extends Node

const DungeonGenerationTypes = preload("res://scripts/procedural_dungeon/dungeon_generation_types.gd")
const DungeonConstants = preload("res://scripts/procedural_dungeon/dungeon_constants.gd")
const DungeonGenerationRequest = preload("res://scripts/procedural_dungeon/resources/dungeon_generation_request.gd")
const DungeonLayoutData = preload("res://scripts/procedural_dungeon/resources/dungeon_layout_data.gd")
const EntranceExitResolver = preload("res://scripts/procedural_dungeon/entrance_exit_resolver.gd")
const RoomGraphGenerator = preload("res://scripts/procedural_dungeon/room_graph_generator.gd")
const HallwayCarver = preload("res://scripts/procedural_dungeon/hallway_carver.gd")
const MazeInfillGenerator = preload("res://scripts/procedural_dungeon/maze_infill_generator.gd")
const LayoutComposer = preload("res://scripts/procedural_dungeon/layout_composer.gd")
const PathValidator = preload("res://scripts/procedural_dungeon/path_validator.gd")
const TileCatalog = preload("res://scripts/procedural_dungeon/tile_catalog.gd")
const MonsterSpawnPlanner = preload("res://scripts/procedural_dungeon/monster_spawn_planner.gd")
const DungeonSceneBuilder = preload("res://scripts/procedural_dungeon/dungeon_scene_builder.gd")

var active_request_id: String = ""
var active_layout_id: String = ""
var generation_state: int = DungeonGenerationTypes.GenerationLifecycleState.RECEIVED
var request_start_time_msec: int = 0

var layouts_by_id: Dictionary = {}
var telemetry: Dictionary = {
	"total_requests": 0,
	"total_successes": 0,
	"total_failures": 0,
	"failure_codes": {}
}

var _entrance_exit_resolver: EntranceExitResolver = EntranceExitResolver.new()
var _room_graph_generator: RoomGraphGenerator = RoomGraphGenerator.new()
var _hallway_carver: HallwayCarver = HallwayCarver.new()
var _maze_infill_generator: MazeInfillGenerator = MazeInfillGenerator.new()
var _layout_composer: LayoutComposer = LayoutComposer.new()
var _path_validator: PathValidator = PathValidator.new()
var _tile_catalog: TileCatalog = TileCatalog.new()
var _monster_spawn_planner: MonsterSpawnPlanner = MonsterSpawnPlanner.new()
var _dungeon_scene_builder: DungeonSceneBuilder = DungeonSceneBuilder.new()

func _ready() -> void:
	generation_state = DungeonGenerationTypes.GenerationLifecycleState.RECEIVED

@rpc("any_peer", "reliable")
func request_generate_dungeon(payload: Dictionary) -> void:
	if not multiplayer.is_server():
		return

	var requester_peer_id: int = multiplayer.get_remote_sender_id()
	if requester_peer_id <= 0:
		requester_peer_id = multiplayer.get_unique_id()

	var contract_response: Dictionary = generate_dungeon_contract(payload, requester_peer_id)
	if not contract_response.get("ok", false):
		_emit_generation_failed(
			str(contract_response.get("requestId", "")),
			str(contract_response.get("code", DungeonGenerationTypes.FAILURE_INVALID_REQUEST)),
			str(contract_response.get("message", "Invalid generation request"))
		)
		return

	notify_generation_succeeded.rpc(contract_response["data"])


func generate_dungeon_contract(payload: Dictionary, requester_peer_id: int) -> Dictionary:
	request_start_time_msec = Time.get_ticks_msec()
	telemetry["total_requests"] = int(telemetry.get("total_requests", 0)) + 1

	var request_result: Dictionary = validate_generation_request_payload(payload, requester_peer_id)
	if not request_result.get("ok", false):
		var validation_error: Dictionary = _error_response(
			str(request_result.get("request_id", "")),
			str(request_result.get("error_code", DungeonGenerationTypes.FAILURE_INVALID_REQUEST)),
			str(request_result.get("message", "Invalid generation request"))
		)
		_log_generation_failure(validation_error)
		return validation_error

	var request: DungeonGenerationRequest = request_result["request"]
	active_request_id = request.request_id
	generation_state = DungeonGenerationTypes.GenerationLifecycleState.VALIDATED
	SignalBus.dungeon_generation_requested.emit(request.request_id, request.requested_by_peer_id)

	var build_result: Dictionary = _build_layout_with_retry(request)
	if not build_result.get("ok", false):
		var build_error: Dictionary = _error_response(
			request.request_id,
			str(build_result.get("error_code", DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE)),
			str(build_result.get("message", "Failed to build traversable layout"))
		)
		_log_generation_failure(build_error)
		return build_error

	var layout_data: DungeonLayoutData = build_result["layout"]
	var commit_result: Dictionary = _commit_layout_to_world(layout_data)
	if not commit_result.get("ok", false):
		var commit_error: Dictionary = _error_response(
			request.request_id,
			str(commit_result.get("error_code", DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE)),
			str(commit_result.get("message", "Failed to commit generated dungeon"))
		)
		_log_generation_failure(commit_error)
		return commit_error

	layouts_by_id[layout_data.layout_id] = layout_data
	active_layout_id = layout_data.layout_id
	generation_state = DungeonGenerationTypes.GenerationLifecycleState.COMMITTED
	_log_generation_success(request.request_id, layout_data.layout_id)

	return {
		"ok": true,
		"requestId": request.request_id,
		"data": layout_data.to_contract_dictionary()
	}

@rpc("any_peer", "reliable")
func request_dungeon_layout(layout_id: String) -> void:
	if not multiplayer.is_server():
		return

	var contract_response: Dictionary = get_dungeon_contract(layout_id)
	if not contract_response.get("ok", false):
		_emit_generation_failed(
			str(contract_response.get("requestId", "")),
			str(contract_response.get("code", DungeonGenerationTypes.FAILURE_INVALID_REQUEST)),
			str(contract_response.get("message", "Requested layout was not found"))
		)
		return

	notify_generation_succeeded.rpc(contract_response["data"])

func get_dungeon_contract(layout_id: String) -> Dictionary:
	if not layouts_by_id.has(layout_id):
		return _error_response("", DungeonGenerationTypes.FAILURE_INVALID_REQUEST, "Requested layout was not found")

	var layout_data: DungeonLayoutData = layouts_by_id[layout_id]
	return {
		"ok": true,
		"requestId": layout_data.request_id,
		"data": layout_data.to_contract_dictionary()
	}

func validate_generation_request_payload(payload: Dictionary, requester_peer_id: int) -> Dictionary:
	if active_request_id != "" and generation_state != DungeonGenerationTypes.GenerationLifecycleState.REJECTED:
		return {
			"ok": false,
			"request_id": str(payload.get("requestId", payload.get("request_id", ""))),
			"error_code": DungeonGenerationTypes.FAILURE_SESSION_CONFLICT,
			"message": "Another generation request is already active"
		}

	var request: DungeonGenerationRequest = DungeonGenerationRequest.new()
	request.from_payload(payload)
	request.requested_by_peer_id = requester_peer_id

	var validation: Dictionary = request.validate()
	if not validation.get("ok", false):
		return {
			"ok": false,
			"request_id": request.request_id,
			"error_code": validation.get("error_code", DungeonGenerationTypes.FAILURE_INVALID_REQUEST),
			"message": validation.get("message", "Request validation failed")
		}

	return {
		"ok": true,
		"request": request,
		"request_id": request.request_id
	}

@rpc("authority", "call_local", "reliable")
func notify_generation_succeeded(layout_payload: Dictionary) -> void:
	var request_id: String = str(layout_payload.get("requestId", ""))
	var layout_id: String = str(layout_payload.get("layoutId", ""))
	active_request_id = ""
	active_layout_id = layout_id
	generation_state = DungeonGenerationTypes.GenerationLifecycleState.COMMITTED
	SignalBus.dungeon_generation_succeeded.emit(request_id, layout_id)

@rpc("authority", "call_local", "reliable")
func notify_generation_failed(request_id: String, error_code: String, message: String) -> void:
	active_request_id = ""
	generation_state = DungeonGenerationTypes.GenerationLifecycleState.REJECTED
	SignalBus.dungeon_generation_failed.emit(request_id, error_code, message)

func _emit_generation_failed(request_id: String, error_code: String, message: String) -> void:
	if not DungeonGenerationTypes.is_valid_failure_code(error_code):
		error_code = DungeonGenerationTypes.FAILURE_INVALID_REQUEST
	notify_generation_failed.rpc(request_id, error_code, message)

func _build_layout_with_retry(request: DungeonGenerationRequest) -> Dictionary:
	var last_error: Dictionary = _error_response(
		request.request_id,
		DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE,
		"Unable to build layout"
	)

	for attempt_index in range(DungeonConstants.MAX_GENERATION_ATTEMPTS):
		var generation_seed: int = _calculate_generation_seed(request, attempt_index)
		var attempt_result: Dictionary = _build_layout_candidate(request, generation_seed)
		if not attempt_result.get("ok", false):
			last_error = attempt_result
			continue

		var layout_data: DungeonLayoutData = attempt_result["layout"]
		if not _has_required_regions(layout_data):
			last_error = _error_response(
				request.request_id,
				DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE,
				"Layout missing room or hallway regions"
			)
			continue

		return {
			"ok": true,
			"layout": layout_data
		}

	return last_error

func _build_layout_candidate(request: DungeonGenerationRequest, generation_seed: int) -> Dictionary:
	var resolved_points: Dictionary = _entrance_exit_resolver.resolve_positions(
		request.start_position,
		request.exit_position,
		request.generation_bounds
	)
	if not resolved_points.get("ok", false):
		return resolved_points

	var entrance_cell: Vector2i = resolved_points["entrance_cell"]
	var exit_cell: Vector2i = resolved_points["exit_cell"]

	var room_result: Dictionary = _room_graph_generator.generate_room_backbone(
		entrance_cell,
		exit_cell,
		request.generation_bounds
	)
	var base_room_cells: Array[Vector2i] = room_result.get("walkable_cells", [])

	var hallway_result: Dictionary = _hallway_carver.carve_backbone_hallway(
		entrance_cell,
		exit_cell,
		request.generation_bounds
	)
	var base_hallway_cells: Array[Vector2i] = hallway_result.get("hallway_cells", [])

	var infill_result: Dictionary = _maze_infill_generator.generate_infill(
		request.generation_bounds,
		base_room_cells + base_hallway_cells,
		generation_seed
	)
	var infill_hallway_cells: Array[Vector2i] = infill_result.get("hallway_cells", [])

	var composed_layout: Dictionary = _layout_composer.compose(
		base_room_cells,
		base_hallway_cells,
		infill_hallway_cells
	)

	var walkable_cells: Array[Vector2i] = composed_layout.get("walkable_cells", [])
	var room_regions: Array[Dictionary] = composed_layout.get("room_regions", [])
	var hallway_regions: Array[Dictionary] = composed_layout.get("hallway_regions", [])

	var walkable_set: Dictionary = {}
	for cell in walkable_cells:
		walkable_set[cell] = true

	if not _path_validator.has_connected_path(entrance_cell, exit_cell, walkable_cells):
		return _error_response(request.request_id, DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE, "Entrance and exit are not connected")

	var main_path: Array[Vector2i] = _path_validator.build_shortest_path(entrance_cell, exit_cell, walkable_cells)
	var blocked_cells: Array[Vector2i] = _build_blocked_cells(request.generation_bounds, walkable_set)

	var layout_data: DungeonLayoutData = DungeonLayoutData.new()
	layout_data.layout_id = "layout_%s_%d" % [request.request_id, Time.get_ticks_msec()]
	layout_data.request_id = request.request_id
	layout_data.grid_size = request.generation_bounds.size
	layout_data.entrance_cell = entrance_cell
	layout_data.exit_cell = exit_cell
	layout_data.walkable_cells = walkable_cells
	layout_data.blocked_cells = blocked_cells
	layout_data.room_regions = room_regions
	layout_data.hallway_regions = hallway_regions
	layout_data.main_path_cells = main_path
	layout_data.generation_seed = generation_seed
	layout_data.tile_placements = _build_tile_placements(layout_data)
	layout_data.monster_spawns = _monster_spawn_planner.plan_spawns(
		layout_data.layout_id,
		layout_data.walkable_cells,
		layout_data.entrance_cell,
		layout_data.exit_cell,
		layout_data.generation_seed
	)

	var layout_validation: Dictionary = layout_data.validate()
	if not layout_validation.get("ok", false):
		return _error_response(
			request.request_id,
			str(layout_validation.get("error_code", DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE)),
			str(layout_validation.get("message", "Layout validation failed"))
		)

	return {
		"ok": true,
		"layout": layout_data
	}

func _has_required_regions(layout_data: DungeonLayoutData) -> bool:
	return not layout_data.room_regions.is_empty() and not layout_data.hallway_regions.is_empty()

func _calculate_generation_seed(request: DungeonGenerationRequest, attempt_index: int) -> int:
	var request_hash: int = request.request_id.hash()
	return request_hash + (attempt_index + 1) * 7919

func _build_blocked_cells(bounds: Rect2i, walkable_set: Dictionary) -> Array[Vector2i]:
	var blocked_cells: Array[Vector2i] = []
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			var candidate: Vector2i = Vector2i(x, y)
			if not walkable_set.has(candidate):
				blocked_cells.append(candidate)
	return blocked_cells

func _error_response(request_id: String, error_code: String, message: String) -> Dictionary:
	return {
		"ok": false,
		"requestId": request_id,
		"error_code": error_code,
		"code": error_code,
		"message": message
	}

func _log_generation_success(request_id: String, layout_id: String) -> void:
	var elapsed_msec: int = Time.get_ticks_msec() - request_start_time_msec
	telemetry["total_successes"] = int(telemetry.get("total_successes", 0)) + 1
	print(
		"DungeonGenerationManager: success request=",
		request_id,
		" layout=",
		layout_id,
		" elapsed_msec=",
		elapsed_msec,
		" totals(requests/success/failure)=",
		telemetry.get("total_requests", 0),
		"/",
		telemetry.get("total_successes", 0),
		"/",
		telemetry.get("total_failures", 0)
	)

func _log_generation_failure(error_payload: Dictionary) -> void:
	var elapsed_msec: int = Time.get_ticks_msec() - request_start_time_msec
	var request_id: String = str(error_payload.get("requestId", ""))
	var error_code: String = str(error_payload.get("code", DungeonGenerationTypes.FAILURE_INVALID_REQUEST))
	var message: String = str(error_payload.get("message", "Unknown generation failure"))

	telemetry["total_failures"] = int(telemetry.get("total_failures", 0)) + 1
	var failure_codes: Dictionary = telemetry.get("failure_codes", {})
	failure_codes[error_code] = int(failure_codes.get(error_code, 0)) + 1
	telemetry["failure_codes"] = failure_codes

	push_warning(
		"DungeonGenerationManager: failure request=%s code=%s elapsed_msec=%d message=%s" % [
			request_id,
			error_code,
			elapsed_msec,
			message
		]
	)

func _build_tile_placements(layout_data: DungeonLayoutData) -> Array[Dictionary]:
	var placements: Array[Dictionary] = []

	for cell in layout_data.walkable_cells:
		var role: String = "floor"
		if cell == layout_data.entrance_cell:
			role = "entrance"
		elif cell == layout_data.exit_cell:
			role = "exit"

		placements.append({
			"position": {"x": cell.x, "y": cell.y},
			"tileRole": role,
			"tileSourcePath": _tile_catalog.get_floor_scene_path(),
			"variantId": -1
		})

	for cell in layout_data.blocked_cells:
		placements.append({
			"position": {"x": cell.x, "y": cell.y},
			"tileRole": "wall",
			"tileSourcePath": _tile_catalog.get_wall_scene_path(),
			"variantId": -1
		})

	return placements

func _commit_layout_to_world(layout_data: DungeonLayoutData) -> Dictionary:
	if not multiplayer.is_server():
		return _error_response(layout_data.request_id, DungeonGenerationTypes.FAILURE_AUTHORITY_VIOLATION, "Only server can commit generated dungeons")

	var built_scene: Dictionary = _dungeon_scene_builder.build_container(layout_data)
	if not built_scene.get("ok", false):
		return built_scene

	var container: Node2D = built_scene.get("container", null)
	if not container:
		return _error_response(layout_data.request_id, DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE, "Generated dungeon container missing")

	if not LevelManager or not LevelManager.has_method("replace_generated_dungeon_container"):
		container.queue_free()
		return _error_response(layout_data.request_id, DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE, "LevelManager cannot replace generated dungeon container")

	LevelManager.replace_generated_dungeon_container(container)
	_clear_generated_monsters()
	var spawn_result: Dictionary = _spawn_generated_monsters(layout_data)
	if not spawn_result.get("ok", false):
		_rollback_committed_generation()
		return spawn_result

	return {
		"ok": true
	}

func _rollback_committed_generation() -> void:
	if LevelManager and LevelManager.has_method("clear_generated_dungeon_container"):
		LevelManager.clear_generated_dungeon_container()
	_clear_generated_monsters()

func _clear_generated_monsters() -> void:
	for node in get_tree().get_nodes_in_group("generated_dungeon_monsters"):
		if node and is_instance_valid(node):
			node.queue_free()

func _spawn_generated_monsters(layout_data: DungeonLayoutData) -> Dictionary:
	var spawners: Array = get_tree().get_nodes_in_group("multiplayer_spawner")
	if spawners.is_empty():
		return {"ok": true}

	var spawner: Node = spawners[0]
	if not spawner.has_method("spawn_monster_from_scene_path"):
		return {"ok": true}

	for spawn in layout_data.monster_spawns:
		var position_dict: Dictionary = spawn.get("position", {})
		var world_position: Vector2 = _grid_to_world(position_dict)
		var ok: bool = spawner.spawn_monster_from_scene_path(
			str(spawn.get("monsterScenePath", "")),
			world_position,
			str(spawn.get("spawnId", ""))
		)
		if not ok:
			return _error_response(layout_data.request_id, DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE, "Failed to spawn one or more monsters")

	return {
		"ok": true
	}

func _grid_to_world(point: Dictionary) -> Vector2:
	var x: float = float(point.get("x", 0))
	var y: float = float(point.get("y", 0))
	return Vector2(x * 128.0, y * 128.0)
