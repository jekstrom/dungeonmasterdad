class_name DungeonGenerationRequest extends Resource

@export var request_id: String = ""
@export var start_position: Vector2i = Vector2i.ZERO
@export var exit_position: Vector2i = Vector2i.ZERO
@export var generation_bounds: Rect2i = Rect2i(Vector2i.ZERO, Vector2i(16, 16))
@export var profile_id: String = "standard"
@export var room_size: int = 5
@export var room_count: int = 0
@export var request_time_unix: int = 0
@export var requested_by_peer_id: int = 1

func validate() -> Dictionary:
	if request_id.strip_edges().is_empty():
		return DungeonGrid.fail("INVALID_REQUEST", "Request ID is required")

	if requested_by_peer_id <= 0:
		return DungeonGrid.fail("AUTHORITY_VIOLATION", "Requested peer id must be positive")

	if generation_bounds.size.x <= 0 or generation_bounds.size.y <= 0:
		return DungeonGrid.fail("INVALID_REQUEST", "Generation bounds must have positive size")

	if generation_bounds.size.x < DungeonConstants.STANDARD_MIN_BOUNDS.x \
			or generation_bounds.size.y < DungeonConstants.STANDARD_MIN_BOUNDS.y:
		return DungeonGrid.fail("BOUNDS_TOO_SMALL", "Generation bounds must be at least 16x16")

	var resolved_profile: String = profile_id.strip_edges()
	if resolved_profile.is_empty():
		resolved_profile = DungeonConstants.DEFAULT_PROFILE_ID
		profile_id = DungeonConstants.DEFAULT_PROFILE_ID
	if resolved_profile != DungeonConstants.DEFAULT_PROFILE_ID:
		return DungeonGrid.fail("INVALID_REQUEST", "Unknown generation profile")

	if start_position == exit_position:
		return DungeonGrid.fail("START_EQUALS_EXIT", "Start and exit positions must be different")

	if not generation_bounds.has_point(start_position) or not generation_bounds.has_point(exit_position):
		return DungeonGrid.fail("POSITION_OUT_OF_BOUNDS", "Start and exit must be inside generation bounds")

	room_size = DungeonConstants.normalize_room_size(room_size)
	if room_count != 0 and (room_count < DungeonConstants.MIN_ROOM_COUNT or room_count > DungeonConstants.MAX_ROOM_COUNT):
		return DungeonGrid.fail(
			"INVALID_REQUEST",
			"Room count must be 0 (auto) or %d-%d" % [DungeonConstants.MIN_ROOM_COUNT, DungeonConstants.MAX_ROOM_COUNT]
		)

	return {
		"ok": true,
		"error_code": "",
		"message": ""
	}

func from_payload(payload: Dictionary) -> void:
	request_id = str(payload.get("requestId", payload.get("request_id", "")))
	start_position = DungeonGrid.cell_from(payload.get("startPosition", payload.get("start_position", {})))
	exit_position = DungeonGrid.cell_from(payload.get("exitPosition", payload.get("exit_position", {})))
	generation_bounds = _parse_bounds(payload.get("generationBounds", payload.get("generation_bounds", {})))
	var raw_profile: String = str(payload.get("profileId", payload.get("profile_id", DungeonConstants.DEFAULT_PROFILE_ID)))
	if raw_profile.strip_edges().is_empty():
		raw_profile = DungeonConstants.DEFAULT_PROFILE_ID
	profile_id = raw_profile
	var raw_room_size: int = int(payload.get("roomSize", payload.get("room_size", DungeonConstants.DEFAULT_ROOM_SIZE)))
	if raw_room_size <= 0:
		raw_room_size = DungeonConstants.DEFAULT_ROOM_SIZE
	room_size = DungeonConstants.normalize_room_size(raw_room_size)
	room_count = int(payload.get("roomCount", payload.get("room_count", 0)))
	request_time_unix = int(Time.get_unix_time_from_system())

func mid_room_count() -> int:
	if room_count >= DungeonConstants.MIN_ROOM_COUNT:
		return room_count - 2
	return DungeonConstants.auto_mid_room_count(generation_bounds)

func room_radius() -> int:
	return DungeonConstants.room_radius(room_size)

func center_separation() -> int:
	return DungeonConstants.room_center_separation(room_size)

func _parse_bounds(raw_value: Variant) -> Rect2i:
	if raw_value is Rect2i:
		return raw_value
	if raw_value is Dictionary:
		var origin: Vector2i = DungeonGrid.cell_from(raw_value.get("origin", {}))
		var size: Vector2i = DungeonGrid.cell_from(raw_value.get("size", {}))
		return Rect2i(origin, size)
	return Rect2i(Vector2i.ZERO, DungeonConstants.STANDARD_MIN_BOUNDS)
