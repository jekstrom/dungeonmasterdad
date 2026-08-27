extends Node

const DungeonGenerationTypes = preload("res://scripts/procedural_dungeon/dungeon_generation_types.gd")
const DungeonConstants = preload("res://scripts/procedural_dungeon/dungeon_constants.gd")
const DungeonGenerationRequest = preload("res://scripts/procedural_dungeon/resources/dungeon_generation_request.gd")
const DungeonLayoutData = preload("res://scripts/procedural_dungeon/resources/dungeon_layout_data.gd")
const DungeonSpawnSet = preload("res://scripts/procedural_dungeon/resources/dungeon_spawn_set.gd")
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

@rpc("any_peer", "call_local", "reliable")
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
	if request.profile_id != "standard":
		var profile_error: Dictionary = _error_response(
			request.request_id,
			DungeonGenerationTypes.FAILURE_INVALID_REQUEST,
			"Unknown generation profile"
		)
		_log_generation_failure(profile_error)
		return profile_error

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
		_release_contract_session(false)
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
		_release_contract_session(false)
		return commit_error

	layouts_by_id[layout_data.layout_id] = layout_data
	active_layout_id = layout_data.layout_id
	_print_region_dump(layout_data)
	_log_generation_success(request.request_id, layout_data.layout_id)
	_release_contract_session(true)

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

	if request.profile_id != "standard":
		return {
			"ok": false,
			"request_id": request.request_id,
			"error_code": DungeonGenerationTypes.FAILURE_INVALID_REQUEST,
			"message": "Unknown generation profile"
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

func _release_contract_session(success: bool) -> void:
	# FR-009: unlock so the next generate_dungeon_contract in this session can run.
	active_request_id = ""
	if success:
		generation_state = DungeonGenerationTypes.GenerationLifecycleState.COMMITTED
	else:
		generation_state = DungeonGenerationTypes.GenerationLifecycleState.REJECTED

func _get_level_manager() -> Node:
	var current_scene: Node = get_tree().current_scene
	if current_scene and current_scene.has_method("begin_generated_dungeon_stage"):
		return current_scene
	return get_tree().get_first_node_in_group("level_manager")

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
		request.generation_bounds,
		generation_seed
	)
	if not room_result.get("ok", false):
		return _error_response(
			request.request_id,
			str(room_result.get("error_code", DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE)),
			str(room_result.get("message", "Failed to place room backbone"))
		)

	var room_regions: Array[Dictionary] = _to_dict_array(room_result.get("room_regions", []))
	var graph_edges: Array = room_result.get("graph_edges", [])
	var rooms_by_id: Dictionary = _rooms_by_id(room_regions)

	var hallway_result: Dictionary = _hallway_carver.carve_graph_hallways(
		rooms_by_id,
		graph_edges,
		request.generation_bounds
	)
	var graph_hallway_cells: Array[Vector2i] = _to_cell_array(hallway_result.get("hallway_cells", []))

	var infill_result: Dictionary = _maze_infill_generator.generate_infill(
		request.generation_bounds,
		room_regions,
		graph_hallway_cells,
		entrance_cell,
		exit_cell,
		generation_seed
	)
	if not infill_result.get("ok", false):
		return _error_response(
			request.request_id,
			str(infill_result.get("error_code", DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE)),
			str(infill_result.get("message", "Failed to place dead-end pockets"))
		)

	var infill_hallway_cells: Array[Vector2i] = _to_cell_array(infill_result.get("hallway_cells", []))
	var deadend_regions: Array[Dictionary] = _to_dict_array(infill_result.get("deadend_regions", []))
	var all_hallway_cells: Array[Vector2i] = []
	all_hallway_cells.append_array(graph_hallway_cells)
	all_hallway_cells.append_array(infill_hallway_cells)

	var composed_layout: Dictionary = _layout_composer.compose(
		room_regions,
		all_hallway_cells,
		deadend_regions
	)

	var walkable_cells: Array[Vector2i] = _to_cell_array(composed_layout.get("walkable_cells", []))
	room_regions = _to_dict_array(composed_layout.get("room_regions", []))
	var hallway_regions: Array[Dictionary] = _to_dict_array(composed_layout.get("hallway_regions", []))

	if hallway_regions.is_empty():
		return _error_response(request.request_id, DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE, "Layout missing hallway regions")
	if not _roles_present(room_regions, ["start", "mid", "exit"]):
		return _error_response(request.request_id, DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE, "Layout missing required room roles")
	if not _rooms_meet_size_and_separation(room_regions):
		return _error_response(request.request_id, DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE, "Room size or separation failed")

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
	layout_data.tile_placements = _build_tile_placements(layout_data, walkable_set)
	layout_data.monster_spawns = _monster_spawn_planner.plan_spawns(
		layout_data.layout_id,
		layout_data.room_regions,
		layout_data.hallway_regions,
		layout_data.entrance_cell,
		layout_data.exit_cell,
		layout_data.generation_seed
	)

	var spawn_set: DungeonSpawnSet = DungeonSpawnSet.new()
	spawn_set.layout_id = layout_data.layout_id
	spawn_set.spawns = layout_data.monster_spawns
	var spawn_validation: Dictionary = spawn_set.validate(
		layout_data.entrance_cell,
		layout_data.exit_cell,
		layout_data.walkable_cells
	)
	if not spawn_validation.get("ok", false):
		return _error_response(
			request.request_id,
			str(spawn_validation.get("error_code", DungeonGenerationTypes.FAILURE_INVALID_REQUEST)),
			str(spawn_validation.get("message", "Spawn set validation failed"))
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
	if layout_data.hallway_regions.is_empty():
		return false
	return _roles_present(layout_data.room_regions, ["start", "mid", "exit"])

func _roles_present(room_regions: Array[Dictionary], required: Array) -> bool:
	var found: Dictionary = {}
	for region in room_regions:
		found[str(region.get("role", ""))] = true
	for role in required:
		if not found.has(str(role)):
			return false
	return true

func _rooms_meet_size_and_separation(room_regions: Array[Dictionary]) -> bool:
	var centers: Array[Vector2i] = []
	for region in room_regions:
		var role: String = str(region.get("role", ""))
		var cells: Array = region.get("cells", [])
		if role == "deadend":
			if cells.size() < 5:
				return false
			continue
		if cells.size() < 9:
			return false
		centers.append(_region_center(region))
	for i in range(centers.size()):
		for j in range(i + 1, centers.size()):
			var dx: int = absi(centers[i].x - centers[j].x)
			var dy: int = absi(centers[i].y - centers[j].y)
			if maxi(dx, dy) < 6:
				return false
	return true

func _region_center(region: Dictionary) -> Vector2i:
	var raw_center: Variant = region.get("center", {})
	if raw_center is Vector2i:
		return raw_center
	if raw_center is Dictionary:
		return Vector2i(int(raw_center.get("x", 0)), int(raw_center.get("y", 0)))
	return Vector2i.ZERO

func _rooms_by_id(room_regions: Array[Dictionary]) -> Dictionary:
	var rooms: Dictionary = {}
	for region in room_regions:
		var room_id: String = str(region.get("roomId", ""))
		rooms[room_id] = {"center": _region_center(region)}
	return rooms

func _to_dict_array(raw_value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if raw_value is Array:
		for item in raw_value:
			if item is Dictionary:
				result.append(item)
	return result

func _to_cell_array(raw_value: Variant) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if raw_value is Array:
		for item in raw_value:
			if item is Vector2i:
				result.append(item)
	return result

func _print_region_dump(layout_data: DungeonLayoutData) -> void:
	var room_set: Dictionary = {}
	for region in layout_data.room_regions:
		for point in region.get("cells", []):
			room_set[_point_to_cell(point)] = true
	var hall_set: Dictionary = {}
	for cell in layout_data.walkable_cells:
		if not room_set.has(cell):
			hall_set[cell] = true
	var spawn_counts: Dictionary = {}
	for spawn in layout_data.monster_spawns:
		var spawn_cell: Vector2i = _point_to_cell(spawn.get("position", {}))
		spawn_counts[spawn_cell] = int(spawn_counts.get(spawn_cell, 0)) + 1
	for region in layout_data.room_regions:
		var doors: int = 0
		var spawns: int = 0
		var cells: Array = region.get("cells", [])
		for point in cells:
			var cell: Vector2i = _point_to_cell(point)
			var is_door: bool = false
			for neighbor in [cell + Vector2i.RIGHT, cell + Vector2i.LEFT, cell + Vector2i.DOWN, cell + Vector2i.UP]:
				if hall_set.has(neighbor):
					is_door = true
					break
			if is_door:
				doors += 1
			spawns += int(spawn_counts.get(cell, 0))
		print(
			"[dungeon] role=%s id=%s cells=%d doors=%d spawns=%d" % [
				str(region.get("role", "")),
				str(region.get("roomId", "")),
				cells.size(),
				doors,
				spawns
			]
		)

func _point_to_cell(raw_value: Variant) -> Vector2i:
	if raw_value is Vector2i:
		return raw_value
	if raw_value is Dictionary:
		return Vector2i(int(raw_value.get("x", 0)), int(raw_value.get("y", 0)))
	return Vector2i.ZERO

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

func _build_tile_placements(layout_data: DungeonLayoutData, walkable_set: Dictionary) -> Array[Dictionary]:
	var placements: Array[Dictionary] = []
	var room_set: Dictionary = {}
	for region in layout_data.room_regions:
		for point in region.get("cells", []):
			room_set[_point_to_cell(point)] = true

	for cell in layout_data.walkable_cells:
		var role: String = "floor"
		var variant_id: int = 1
		if room_set.has(cell):
			variant_id = 0
		if cell == layout_data.entrance_cell:
			role = "entrance"
			variant_id = 0
		elif cell == layout_data.exit_cell:
			role = "exit"
			variant_id = 0

		placements.append({
			"position": {"x": cell.x, "y": cell.y},
			"tileRole": role,
			"tileSourcePath": _tile_catalog.get_floor_scene_path(),
			"variantId": variant_id
		})

	var wall_set: Dictionary = {}
	for cell in layout_data.blocked_cells:
		if _is_occupancy_adjacent(cell, walkable_set):
			wall_set[cell] = true
	# Outer corners are diagonal to walkable, so occupancy-adjacent misses them
	# and leaves a gap between a straight run and the 2/8 return. Snap those
	# cells onto the shell when two occupancy walls already form an L.
	for cell in layout_data.blocked_cells:
		if _is_shell_corner_cell(cell, walkable_set, wall_set):
			wall_set[cell] = true
	for cell in wall_set:
		placements.append({
			"position": {"x": cell.x, "y": cell.y},
			"tileRole": "wall",
			"tileSourcePath": _tile_catalog.get_wall_scene_path(),
			"variantId": _wall_type_for_cell(cell, walkable_set),
			"wallFrame": _wall_frame_for_cell(cell, walkable_set, wall_set)
		})

	return placements

func _is_occupancy_adjacent(cell: Vector2i, walkable_set: Dictionary) -> bool:
	return (
		walkable_set.has(cell + Vector2i.RIGHT)
		or walkable_set.has(cell + Vector2i.LEFT)
		or walkable_set.has(cell + Vector2i.UP)
		or walkable_set.has(cell + Vector2i.DOWN)
	)

func _is_shell_corner_cell(cell: Vector2i, walkable_set: Dictionary, wall_set: Dictionary) -> bool:
	if walkable_set.has(cell) or wall_set.has(cell):
		return false
	var wall_n: bool = wall_set.has(cell + Vector2i.UP)
	var wall_s: bool = wall_set.has(cell + Vector2i.DOWN)
	var wall_e: bool = wall_set.has(cell + Vector2i.RIGHT)
	var wall_w: bool = wall_set.has(cell + Vector2i.LEFT)
	if not ((wall_e or wall_w) and (wall_n or wall_s)):
		return false
	# Inside of the L must be walkable so we do not fill hollow blocked space.
	if wall_e and wall_s and walkable_set.has(cell + Vector2i.RIGHT + Vector2i.DOWN):
		return true
	if wall_w and wall_s and walkable_set.has(cell + Vector2i.LEFT + Vector2i.DOWN):
		return true
	if wall_e and wall_n and walkable_set.has(cell + Vector2i.RIGHT + Vector2i.UP):
		return true
	if wall_w and wall_n and walkable_set.has(cell + Vector2i.LEFT + Vector2i.UP):
		return true
	return false

func _wall_type_for_cell(cell: Vector2i, walkable_set: Dictionary) -> int:
	# Type 2 is the vertical collider so east/west occupancy edges actually block.
	var has_east: bool = walkable_set.has(cell + Vector2i.RIGHT)
	var has_west: bool = walkable_set.has(cell + Vector2i.LEFT)
	if has_east or has_west:
		return 2
	return 1

func _is_east_v_wall(cell: Vector2i, walkable_set: Dictionary) -> bool:
	# East wall of a room: walkable is west, column sits on the left half (frame 12).
	# West wall keeps frame 1. Both sides (thin hallway) stays west; do not invent a double.
	var walk_w: bool = walkable_set.has(cell + Vector2i.LEFT)
	var walk_e: bool = walkable_set.has(cell + Vector2i.RIGHT)
	return walk_w and not walk_e

func _wall_frame_for_cell(cell: Vector2i, walkable_set: Dictionary, wall_set: Dictionary) -> int:
	# 17-frame cubicle_stone_wall.png. Skip 4 (shadow). Collider stays in wall_type.
	# East V (left-half) is 12/13/14. East LD/LU corners are 15/16 (same topology as 2/3).
	# West corners stay 2/3/5/6.
	var n: bool = wall_set.has(cell + Vector2i.UP)
	var e: bool = wall_set.has(cell + Vector2i.RIGHT)
	var s: bool = wall_set.has(cell + Vector2i.DOWN)
	var w: bool = wall_set.has(cell + Vector2i.LEFT)
	var h_count: int = int(e) + int(w)
	var v_count: int = int(n) + int(s)
	var count: int = h_count + v_count
	var east_v: bool = _is_east_v_wall(cell, walkable_set)
	if count >= 3:
		# T or + : keep the through-run. No T frame on the strip.
		if v_count == 2 and h_count < 2:
			return 12 if east_v else 1
		if h_count == 2:
			return 0
		if _wall_type_for_cell(cell, walkable_set) == 2:
			return 12 if east_v else 1
		return 0
	if h_count == 2 and v_count == 0:
		return 0
	if v_count == 2 and h_count == 0:
		return 12 if east_v else 1
	if h_count == 1 and v_count == 1:
		# Corner cell is wall-west, so it cannot also be walkable-west.
		# Face 15/16 from the V neighbor, which is the east 12-run.
		if w and s:
			return 15 if _is_east_v_wall(cell + Vector2i.DOWN, walkable_set) else 2
		if w and n:
			return 16 if _is_east_v_wall(cell + Vector2i.UP, walkable_set) else 3
		if e and n:
			return 5
		if e and s:
			return 6
		return 0
	if count == 1:
		if e:
			return 7
		if w:
			return 8
		if s:
			return 13 if east_v else 9
		if n:
			return 14 if east_v else 10
	if _wall_type_for_cell(cell, walkable_set) == 2:
		return 12 if east_v else 1
	return 0

func _commit_layout_to_world(layout_data: DungeonLayoutData) -> Dictionary:
	if not multiplayer.is_server():
		return _error_response(layout_data.request_id, DungeonGenerationTypes.FAILURE_AUTHORITY_VIOLATION, "Only server can commit generated dungeons")

	var level_manager: Node = _get_level_manager()
	if not level_manager:
		# Contract tests can run without a playground LevelManager in the tree.
		_print_region_dump(layout_data)
		return {"ok": true}

	level_manager.begin_generated_dungeon_stage()

	var tile_result: Dictionary = _spawn_generated_tiles(layout_data, level_manager)
	if not tile_result.get("ok", false):
		level_manager.rollback_generated_dungeon_stage()
		return tile_result

	var spawn_result: Dictionary = _spawn_generated_monsters(layout_data, level_manager)
	if not spawn_result.get("ok", false):
		level_manager.rollback_generated_dungeon_stage()
		return spawn_result

	level_manager.commit_generated_dungeon_stage()
	_print_region_dump(layout_data)
	_smoke_check_generated_tiles(layout_data)
	return {
		"ok": true
	}

func _spawn_generated_tiles(layout_data: DungeonLayoutData, level_manager: Node) -> Dictionary:
	var spawners: Array = get_tree().get_nodes_in_group("multiplayer_spawner")
	if spawners.is_empty() or not spawners[0].has_method("spawn_tile_from_scene_path"):
		var built_scene: Dictionary = _dungeon_scene_builder.build_container(layout_data)
		if not built_scene.get("ok", false):
			return built_scene
		var container: Node2D = built_scene.get("container", null)
		if not container:
			return _error_response(layout_data.request_id, DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE, "Generated dungeon container missing")
		if container.get_parent():
			container.get_parent().remove_child(container)
		get_tree().current_scene.add_child(container)
		level_manager.register_staged_generated_node(container)
		return {"ok": true}

	var spawner: Node = spawners[0]
	for placement in layout_data.tile_placements:
		var scene_path: String = str(placement.get("tileSourcePath", ""))
		var point: Dictionary = placement.get("position", {})
		var world_position: Vector2 = _grid_to_world(point)
		var variant_id: int = int(placement.get("variantId", -1))
		var wall_frame: int = int(placement.get("wallFrame", -1))
		var tile: Node2D = spawner.spawn_tile_from_scene_path(scene_path, world_position, variant_id, wall_frame)
		if not tile:
			return _error_response(layout_data.request_id, DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE, "Failed to spawn one or more tiles")
		level_manager.register_staged_generated_node(tile)

	return {"ok": true}

func _spawn_generated_monsters(layout_data: DungeonLayoutData, level_manager: Node) -> Dictionary:
	var spawners: Array = get_tree().get_nodes_in_group("multiplayer_spawner")
	if spawners.is_empty():
		return {"ok": true}

	var spawner: Node = spawners[0]
	if not spawner.has_method("spawn_monster_from_scene_path"):
		return {"ok": true}

	for spawn in layout_data.monster_spawns:
		var position_dict: Dictionary = spawn.get("position", {})
		var world_position: Vector2 = _grid_to_world(position_dict)
		var monster: Node2D = spawner.spawn_monster_from_scene_path(
			str(spawn.get("monsterScenePath", "")),
			world_position,
			str(spawn.get("spawnId", ""))
		)
		if not monster:
			return _error_response(layout_data.request_id, DungeonGenerationTypes.FAILURE_LAYOUT_INFEASIBLE, "Failed to spawn one or more monsters")
		level_manager.register_staged_generated_node(monster)

	return {
		"ok": true
	}

func _grid_to_world(point: Dictionary) -> Vector2:
	var x: float = float(point.get("x", 0))
	var y: float = float(point.get("y", 0))
	return Vector2(x * 128.0, y * 128.0)

func _smoke_check_generated_tiles(layout_data: DungeonLayoutData) -> void:
	var walkable_set: Dictionary = {}
	for cell in layout_data.walkable_cells:
		walkable_set[cell] = true
	var tiles: Array = get_tree().get_nodes_in_group("generated_dungeon_tiles")
	var off_grid: int = 0
	var ew_ok: int = 0
	var ew_bad: int = 0
	for tile in tiles:
		if not (tile is Node2D):
			continue
		var node: Node2D = tile
		var px: int = int(round(node.position.x))
		var py: int = int(round(node.position.y))
		if px % 128 != 0 or py % 128 != 0:
			off_grid += 1
		if "wall_type" in node:
			var cell: Vector2i = Vector2i(int(round(node.position.x / 128.0)), int(round(node.position.y / 128.0)))
			var is_ew: bool = walkable_set.has(cell + Vector2i.RIGHT) or walkable_set.has(cell + Vector2i.LEFT)
			if is_ew:
				if int(node.wall_type) == 2:
					ew_ok += 1
				else:
					ew_bad += 1
	print(
		"[dungeon] tile smoke tiles=%d off_grid=%d ew_type2=%d ew_bad=%d" % [
			tiles.size(),
			off_grid,
			ew_ok,
			ew_bad
		]
	)
	if off_grid > 0 or ew_bad > 0:
		push_warning("DungeonGenerationManager: tile smoke failed off_grid=%d ew_bad=%d" % [off_grid, ew_bad])
