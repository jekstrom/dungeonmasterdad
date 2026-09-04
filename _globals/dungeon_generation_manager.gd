extends Node

const PipelineScript = preload("res://scripts/procedural_dungeon/generation/dungeon_generation_state_machine.gd")
const WorldCommitterScript = preload("res://scripts/procedural_dungeon/generation/dungeon_world_committer.gd")

var active_request_id: String = ""
var active_layout_id: String = ""
var generation_state: int = DungeonGenerationTypes.GenerationLifecycleState.RECEIVED
var request_start_time_msec: int = 0

var layouts_by_id: Dictionary = {}
var _dungeon_cell_bounds: Rect2i = Rect2i()
var telemetry: Dictionary = {
	"total_requests": 0,
	"total_successes": 0,
	"total_failures": 0,
	"failure_codes": {}
}

var _pipeline


func _ready() -> void:
	generation_state = DungeonGenerationTypes.GenerationLifecycleState.RECEIVED
	_pipeline = PipelineScript.new()
	_pipeline.name = "GenerationPipeline"
	add_child(_pipeline)
	_pipeline.initialize(self)


func pipeline():
	return _pipeline


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

	var contract_response: Dictionary = _pipeline.run(payload, requester_peer_id)
	if contract_response.get("ok", false):
		var data: Dictionary = contract_response.get("data", {})
		_log_generation_success(
			str(contract_response.get("requestId", "")),
			str(data.get("layoutId", ""))
		)
	else:
		_log_generation_failure(contract_response)
	return contract_response


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
		return DungeonGenerationTypes.error_payload("", DungeonGenerationTypes.FAILURE_INVALID_REQUEST, "Requested layout was not found")

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

	if request.profile_id != DungeonConstants.DEFAULT_PROFILE_ID:
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
	if not multiplayer.is_server():
		_pipeline.world_committer.spawn_fountain_from_contract(layout_payload)
	SignalBus.dungeon_generation_succeeded.emit(request_id, layout_id)


func broadcast_fountain_charge() -> void:
	if not multiplayer.is_server():
		return
	fountain_play_charge.rpc()


func broadcast_fountain_splash() -> void:
	if not multiplayer.is_server():
		return
	_pipeline.world_committer.play_fountain_splash()
	fountain_play_splash.rpc(pack_fountain_state())


func pack_fountain_state() -> Dictionary:
	return _pipeline.world_committer.pack_fountain_state()


func apply_fountain_state(payload: Dictionary) -> void:
	_pipeline.world_committer.apply_fountain_state(payload)


func sync_fountain_to_peer(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	replicate_fountain_state.rpc_id(peer_id, pack_fountain_state())


@rpc("authority", "call_local", "reliable")
func replicate_fountain_state(payload: Dictionary) -> void:
	if multiplayer.is_server():
		return
	apply_fountain_state(payload)


@rpc("authority", "call_local", "reliable")
func fountain_play_charge() -> void:
	_pipeline.world_committer.play_fountain_charge()


@rpc("authority", "reliable")
func fountain_play_splash(payload: Dictionary = {}) -> void:
	if multiplayer.is_server():
		return
	apply_fountain_state(payload)


@rpc("authority", "call_local", "reliable")
func notify_generation_failed(request_id: String, error_code: String, message: String) -> void:
	active_request_id = ""
	generation_state = DungeonGenerationTypes.GenerationLifecycleState.REJECTED
	SignalBus.dungeon_generation_failed.emit(request_id, error_code, message)


func _emit_generation_failed(request_id: String, error_code: String, message: String) -> void:
	if not DungeonGenerationTypes.is_valid_failure_code(error_code):
		error_code = DungeonGenerationTypes.FAILURE_INVALID_REQUEST
	notify_generation_failed.rpc(request_id, error_code, message)


func apply_committed_layout(layout_data: DungeonLayoutData) -> void:
	layouts_by_id[layout_data.layout_id] = layout_data
	active_layout_id = layout_data.layout_id
	_dungeon_cell_bounds = WorldCommitterScript.bounds_from_walkable(layout_data.walkable_cells)
	_apply_map_interior_from_dungeon()
	release_contract_session(true)


func release_contract_session(success: bool) -> void:
	active_request_id = ""
	if success:
		generation_state = DungeonGenerationTypes.GenerationLifecycleState.COMMITTED
	else:
		generation_state = DungeonGenerationTypes.GenerationLifecycleState.REJECTED


func get_dungeon_cell_bounds() -> Rect2i:
	return _dungeon_cell_bounds


func get_dungeon_occupied_cells() -> Dictionary:
	var occupied: Dictionary = {}
	if active_layout_id.is_empty() or not layouts_by_id.has(active_layout_id):
		return occupied
	var layout: DungeonLayoutData = layouts_by_id[active_layout_id]
	if layout == null:
		return occupied
	for placement in layout.tile_placements:
		occupied[DungeonGrid.cell_from(placement.get("position", {}))] = true
	return occupied


func _apply_map_interior_from_dungeon() -> void:
	var interior: Rect2i = MapBounds.interior_from_dungeon_aabb(_dungeon_cell_bounds)
	var level: Node = _pipeline.world_committer.level_manager_or_null()
	if level and level.has_method("commit_map_interior"):
		level.commit_map_interior(interior)
	if level and level.has_method("strip_outside_tiles_from_dungeon_cells"):
		level.strip_outside_tiles_from_dungeon_cells()


func is_world_position_in_dungeon(world_position: Vector2) -> bool:
	if _dungeon_cell_bounds.size.x <= 0 or _dungeon_cell_bounds.size.y <= 0:
		return true
	return _dungeon_cell_bounds.has_point(DungeonGrid.from_world(world_position))


func get_entrance_world_position() -> Vector2:
	if active_layout_id.is_empty() or not layouts_by_id.has(active_layout_id):
		return Vector2.INF
	var layout: DungeonLayoutData = layouts_by_id[active_layout_id]
	if layout == null:
		return Vector2.INF
	return DungeonGrid.to_world_center(layout.entrance_cell)


func get_exit_cell() -> Vector2i:
	if active_layout_id.is_empty() or not layouts_by_id.has(active_layout_id):
		return DungeonGrid.SENTINEL
	var layout: DungeonLayoutData = layouts_by_id[active_layout_id]
	if layout == null:
		return DungeonGrid.SENTINEL
	return layout.exit_cell


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
	var request_id: String = str(error_payload.get("requestId", error_payload.get("request_id", "")))
	var error_code: String = str(error_payload.get("code", error_payload.get("error_code", DungeonGenerationTypes.FAILURE_INVALID_REQUEST)))
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
