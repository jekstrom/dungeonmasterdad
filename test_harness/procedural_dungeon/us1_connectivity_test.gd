extends Node

func _ready() -> void:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if not manager:
		push_error("US1 connectivity test: DungeonGenerationManager autoload not found")
		return

	if not manager.has_method("generate_dungeon_contract"):
		push_error("US1 connectivity test: generate_dungeon_contract() not available")
		return

	var payload: Dictionary = {
		"requestId": "us1-connectivity-smoke",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 16, "y": 16},
		"generationBounds": {
			"origin": {"x": 0, "y": 0},
			"size": {"x": 24, "y": 24}
		}
	}

	var response: Dictionary = manager.generate_dungeon_contract(payload, 1)
	if not response.get("ok", false):
		push_error("US1 connectivity test failed: %s" % response)
		return

	var data: Dictionary = response.get("data", {})
	var entrance: Dictionary = data.get("entrance", {})
	var exit_point: Dictionary = data.get("exit", {})
	var main_path: Array = data.get("mainPath", [])

	if int(entrance.get("x", -1)) != 2 or int(entrance.get("y", -1)) != 2:
		push_error("US1 connectivity test failed: entrance mismatch")
		return

	if int(exit_point.get("x", -1)) != 16 or int(exit_point.get("y", -1)) != 16:
		push_error("US1 connectivity test failed: exit mismatch")
		return

	if main_path.is_empty():
		push_error("US1 connectivity test failed: main path is empty")
		return

	var walkable: Dictionary = _walkable_set(data)
	for i in range(main_path.size()):
		var cell: Vector2i = _as_cell(main_path[i])
		if not walkable.has(cell):
			push_error("US1 connectivity test failed: mainPath cell is not walkable")
			return
		if i == 0:
			continue
		var prev: Vector2i = _as_cell(main_path[i - 1])
		if absi(cell.x - prev.x) + absi(cell.y - prev.y) != 1:
			push_error("US1 connectivity test failed: mainPath step is not 4-adjacent")
			return

	var has_mid: bool = false
	for region in data.get("roomRegions", []):
		if str(region.get("role", "")) == "mid":
			has_mid = true
			break
	if not has_mid:
		push_error("US1 connectivity test failed: missing mid room")
		return

	var start_cells: Dictionary = {}
	for region in data.get("roomRegions", []):
		if str(region.get("role", "")) != "start":
			continue
		for point in region.get("cells", []):
			start_cells[_as_cell(point)] = true
	for spawn in data.get("monsterSpawns", []):
		if start_cells.has(_as_cell(spawn.get("position", {}))):
			push_error("US1 connectivity test failed: spawn in start room")
			return

	print("US1 connectivity test passed: generated path with ", main_path.size(), " cells")

func _walkable_set(data: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for region in data.get("roomRegions", []):
		for point in region.get("cells", []):
			result[_as_cell(point)] = true
	for region in data.get("hallwayRegions", []):
		for point in region.get("cells", []):
			result[_as_cell(point)] = true
	return result

func _as_cell(raw_value: Variant) -> Vector2i:
	if raw_value is Vector2i:
		return raw_value
	if raw_value is Dictionary:
		return Vector2i(int(raw_value.get("x", 0)), int(raw_value.get("y", 0)))
	return Vector2i.ZERO
