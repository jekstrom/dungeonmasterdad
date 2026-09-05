extends Node

const Planner = preload("res://scripts/procedural_dungeon/pickup_spawn_planner.gd")
const LayoutMetricsScript = preload("res://scripts/procedural_dungeon/layout_metrics.gd")

func _ready() -> void:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager == null or not manager.has_method("generate_dungeon_contract"):
		_fail("US-057: DungeonGenerationManager missing")
		return

	if not _assert_square_compact_and_winding(manager):
		return
	if not _assert_interior_portals(manager):
		return
	if not _assert_axis_pair_is_compact(manager):
		return
	if not _assert_auto_place(manager):
		return
	if not _assert_elongated_bounds(manager):
		return
	if not _assert_start_room_content(manager):
		return
	if not _assert_explicit_knobs_honored(manager):
		return
	if not _assert_closed_rooms(manager):
		return
	if not _assert_playground_does_not_generate_on_ready():
		return

	print("US-057 maze layout test passed")
	get_tree().quit(0)


func _assert_square_compact_and_winding(manager: Node) -> bool:
	var saw_non_l: bool = false
	for i in range(5):
		var response: Dictionary = manager.generate_dungeon_contract(_payload(
			"us057-square-%d" % i,
			Vector2i(2, 2),
			Vector2i(16, 16),
			Vector2i(24, 24)
		), 1)
		if not response.get("ok", false):
			return _fail("US-057 square generate failed: %s" % response)
		var data: Dictionary = response.get("data", {})
		if not _connected(data):
			return _fail("US-057 square: entrance and exit not connected")
		var aabb: Rect2i = _walkable_aabb(data)
		var aspect: float = LayoutMetricsScript.aspect_ratio(aabb)
		if aspect > DungeonConstants.MAX_WALKABLE_ASPECT:
			return _fail("US-057 square: walkable aspect %s > %s" % [aspect, DungeonConstants.MAX_WALKABLE_ASPECT])
		if not _winding_ok(data):
			return _fail("US-057 square: path is not winding")
		if _hallway_has_non_l(data, Rect2i(Vector2i.ZERO, Vector2i(24, 24))):
			saw_non_l = true
		if not _has_roles(data, ["start", "mid", "exit"]):
			return _fail("US-057 square: missing start/mid/exit")
	if not saw_non_l:
		return _fail("US-057 square: hallways were a pure L-set")
	return true


func _assert_interior_portals(manager: Node) -> bool:
	var response: Dictionary = manager.generate_dungeon_contract(_payload(
		"us057-interior",
		Vector2i(8, 10),
		Vector2i(14, 13),
		Vector2i(24, 24)
	), 1)
	if not response.get("ok", false):
		return _fail("US-057 interior generate failed: %s" % response)
	var data: Dictionary = response.get("data", {})
	var entrance: Vector2i = _as_cell(data.get("entrance", {}))
	var exit_cell: Vector2i = _as_cell(data.get("exit", {}))
	if entrance != Vector2i(8, 10) or exit_cell != Vector2i(14, 13):
		return _fail("US-057 interior: explicit start/exit not honored")
	if entrance == exit_cell:
		return _fail("US-057 interior: entrance equals exit")
	if not _connected(data):
		return _fail("US-057 interior: not connected")
	if LayoutMetricsScript.aspect_ratio(_walkable_aabb(data)) > DungeonConstants.MAX_WALKABLE_ASPECT:
		return _fail("US-057 interior: walkable aspect too long")
	return true


func _assert_axis_pair_is_compact(manager: Node) -> bool:
	var response: Dictionary = manager.generate_dungeon_contract(_payload(
		"us057-axis",
		Vector2i(3, 12),
		Vector2i(20, 12),
		Vector2i(24, 24)
	), 1)
	if not response.get("ok", false):
		return _fail("US-057 axis generate failed: %s" % response)
	var data: Dictionary = response.get("data", {})
	if not _connected(data):
		return _fail("US-057 axis: not connected")
	if not _winding_ok(data):
		return _fail("US-057 axis: path is not winding")
	if LayoutMetricsScript.aspect_ratio(_walkable_aabb(data)) > DungeonConstants.MAX_WALKABLE_ASPECT:
		return _fail("US-057 axis: sausage AABB")
	return true


func _assert_auto_place(manager: Node) -> bool:
	var payload: Dictionary = _payload(
		"us057-auto",
		Vector2i.ZERO,
		Vector2i.ZERO,
		Vector2i(24, 24)
	)
	payload["autoPlacePortals"] = true
	var response: Dictionary = manager.generate_dungeon_contract(payload, 1)
	if not response.get("ok", false):
		return _fail("US-057 auto-place generate failed: %s" % response)
	var data: Dictionary = response.get("data", {})
	var entrance: Vector2i = _as_cell(data.get("entrance", {}))
	var exit_cell: Vector2i = _as_cell(data.get("exit", {}))
	if entrance == exit_cell:
		return _fail("US-057 auto-place: entrance equals exit")
	var bounds := Rect2i(Vector2i.ZERO, Vector2i(24, 24))
	if not bounds.has_point(entrance):
		return _fail("US-057 auto-place: entrance out of bounds")
	if not bounds.has_point(exit_cell):
		return _fail("US-057 auto-place: exit out of bounds")
	if exit_cell.x > bounds.position.x + 2:
		return _fail("US-057 auto-place: exit must sit on the west overworld edge")
	if DungeonGrid.chebyshev(entrance, exit_cell) < 8:
		return _fail("US-057 auto-place: entrance too close to exit")
	if not _connected(data):
		return _fail("US-057 auto-place: not connected")
	if not _has_roles(data, ["start", "mid", "exit"]):
		return _fail("US-057 auto-place: missing rooms")
	return true


func _assert_elongated_bounds(manager: Node) -> bool:
	var response: Dictionary = manager.generate_dungeon_contract(_payload(
		"us057-wide",
		Vector2i(2, 2),
		Vector2i(28, 12),
		Vector2i(32, 16)
	), 1)
	if not response.get("ok", false):
		return _fail("US-057 elongated generate failed: %s" % response)
	var data: Dictionary = response.get("data", {})
	if not _connected(data):
		return _fail("US-057 elongated: not connected")
	if not _has_roles(data, ["start", "mid", "exit"]):
		return _fail("US-057 elongated: missing rooms")
	if not _hallway_has_non_l(data, Rect2i(Vector2i.ZERO, Vector2i(32, 16))):
		return _fail("US-057 elongated: hallways were a pure L-set")
	return true


func _assert_start_room_content(manager: Node) -> bool:
	var response: Dictionary = manager.generate_dungeon_contract(_payload(
		"us057-content",
		Vector2i(2, 2),
		Vector2i(16, 16),
		Vector2i(24, 24)
	), 1)
	if not response.get("ok", false):
		return _fail("US-057 content generate failed: %s" % response)
	var data: Dictionary = response.get("data", {})
	var start_set: Dictionary = {}
	for region in data.get("roomRegions", []):
		if str(region.get("role", "")) != "start":
			continue
		for point in region.get("cells", []):
			start_set[_as_cell(point)] = true
	if start_set.is_empty():
		return _fail("US-057 content: missing start room")
	var dew: int = 0
	var code_red: int = 0
	for pickup in data.get("itemPickups", []):
		var cell: Vector2i = _as_cell(pickup.get("position", {}))
		if not start_set.has(cell):
			continue
		var item_type: String = str(pickup.get("item_type", ""))
		if item_type == Planner.GREEN_DEW_PATH:
			dew += 1
		if item_type == Planner.CODE_RED_PATH:
			code_red += 1
	if dew < Planner.START_ROOM_DEW_COUNT:
		return _fail("US-057 content: expected start-room Dew")
	if code_red < 1:
		return _fail("US-057 content: expected start-room Code Red")
	return true


func _assert_explicit_knobs_honored(manager: Node) -> bool:
	var response: Dictionary = manager.generate_dungeon_contract(_payload(
		"us057-knobs",
		Vector2i(29, 16),
		Vector2i(0, 16),
		Vector2i(32, 32)
	), 1)
	if not response.get("ok", false):
		return _fail("US-057 knobs generate failed: %s" % response)
	var data: Dictionary = response.get("data", {})
	var entrance: Vector2i = _as_cell(data.get("entrance", {}))
	var exit_cell: Vector2i = _as_cell(data.get("exit", {}))
	if entrance != Vector2i(29, 16) or exit_cell != Vector2i(0, 16):
		return _fail("US-057 knobs: explicit start/exit not honored got %s %s" % [entrance, exit_cell])
	if not _connected(data):
		return _fail("US-057 knobs: not connected")
	return true


func _assert_closed_rooms(manager: Node) -> bool:
	var response: Dictionary = manager.generate_dungeon_contract(_payload(
		"us057-closed",
		Vector2i(29, 16),
		Vector2i(0, 16),
		Vector2i(32, 32)
	), 1)
	if not response.get("ok", false):
		return _fail("US-057 closed generate failed: %s" % response)
	var data: Dictionary = response.get("data", {})
	var hallway: Dictionary = {}
	for region in data.get("hallwayRegions", []):
		for point in region.get("cells", []):
			hallway[_as_cell(point)] = true
	for region in data.get("roomRegions", []):
		var role: String = str(region.get("role", ""))
		if role != "start" and role != "mid" and role != "exit":
			continue
		var doors: int = 0
		for point in region.get("cells", []):
			var cell: Vector2i = _as_cell(point)
			for neighbor in DungeonGrid.neighbors(cell):
				if hallway.has(neighbor):
					doors += 1
					break
		if doors > 4:
			return _fail("US-057 closed: %s room has %d hallway doors" % [role, doors])
	return true


func _assert_playground_does_not_generate_on_ready() -> bool:
	var text: String = FileAccess.get_file_as_string("res://playground.tscn")
	if text.find("generate_on_ready = false") < 0:
		return _fail("US-057: playground must keep generate_on_ready false")
	if text.find("auto_place_portals = true") >= 0:
		return _fail("US-057: playground must not force auto_place_portals")
	return true


func _payload(request_id: String, start_cell: Vector2i, exit_cell: Vector2i, bounds_size: Vector2i) -> Dictionary:
	return {
		"requestId": request_id,
		"startPosition": {"x": start_cell.x, "y": start_cell.y},
		"exitPosition": {"x": exit_cell.x, "y": exit_cell.y},
		"generationBounds": {
			"origin": {"x": 0, "y": 0},
			"size": {"x": bounds_size.x, "y": bounds_size.y}
		},
		"roomSize": 5,
		"roomCount": 4
	}


func _connected(data: Dictionary) -> bool:
	var path: Array = data.get("mainPath", [])
	if path.is_empty():
		return false
	var walkable: Dictionary = _walkable_set(data)
	var entrance: Vector2i = _as_cell(data.get("entrance", {}))
	var exit_cell: Vector2i = _as_cell(data.get("exit", {}))
	if entrance == exit_cell:
		return false
	if not walkable.has(entrance) or not walkable.has(exit_cell):
		return false
	for i in range(path.size()):
		var cell: Vector2i = _as_cell(path[i])
		if not walkable.has(cell):
			return false
		if i == 0:
			continue
		var prev: Vector2i = _as_cell(path[i - 1])
		if absi(cell.x - prev.x) + absi(cell.y - prev.y) != 1:
			return false
	return _as_cell(path[0]) == entrance and _as_cell(path[path.size() - 1]) == exit_cell


func _winding_ok(data: Dictionary) -> bool:
	var path: Array = data.get("mainPath", [])
	var entrance: Vector2i = _as_cell(data.get("entrance", {}))
	var exit_cell: Vector2i = _as_cell(data.get("exit", {}))
	return LayoutMetricsScript.winding_ratio(path.size(), entrance, exit_cell) >= DungeonConstants.MIN_WINDING_RATIO


func _hallway_has_non_l(data: Dictionary, bounds: Rect2i) -> bool:
	var centers: Array[Vector2i] = []
	for region in data.get("roomRegions", []):
		var role: String = str(region.get("role", ""))
		if role != "start" and role != "mid" and role != "exit":
			continue
		centers.append(_as_cell(region.get("center", {})))
	var l_set: Dictionary = LayoutMetricsScript.l_cell_set(centers, bounds)
	for region in data.get("hallwayRegions", []):
		for point in region.get("cells", []):
			var cell: Vector2i = _as_cell(point)
			if not l_set.has(cell):
				return true
	return false


func _has_roles(data: Dictionary, roles: Array) -> bool:
	var found: Dictionary = {}
	for region in data.get("roomRegions", []):
		found[str(region.get("role", ""))] = true
	for role in roles:
		if not found.has(str(role)):
			return false
	return true


func _walkable_set(data: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for region in data.get("roomRegions", []):
		for point in region.get("cells", []):
			result[_as_cell(point)] = true
	for region in data.get("hallwayRegions", []):
		for point in region.get("cells", []):
			result[_as_cell(point)] = true
	return result


func _walkable_aabb(data: Dictionary) -> Rect2i:
	var cells: Array[Vector2i] = []
	for cell in _walkable_set(data).keys():
		cells.append(cell)
	return LayoutMetricsScript.walkable_aabb(cells)


func _as_cell(raw_value: Variant) -> Vector2i:
	if raw_value is Vector2i:
		return raw_value
	if raw_value is Dictionary:
		return Vector2i(int(raw_value.get("x", 0)), int(raw_value.get("y", 0)))
	return Vector2i.ZERO


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
