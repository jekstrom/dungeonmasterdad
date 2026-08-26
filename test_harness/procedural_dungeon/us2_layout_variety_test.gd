extends Node

func _ready() -> void:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if not manager:
		push_error("US2 layout variety test: DungeonGenerationManager autoload not found")
		return

	if not manager.has_method("generate_dungeon_contract"):
		push_error("US2 layout variety test: generate_dungeon_contract() not available")
		return

	var signatures: Dictionary = {}
	var saw_loop: bool = false
	for i in range(6):
		var payload: Dictionary = {
			"requestId": "us2-variety-%d" % i,
			"startPosition": {"x": 2, "y": 2},
			"exitPosition": {"x": 16, "y": 16},
			"generationBounds": {
				"origin": {"x": 0, "y": 0},
				"size": {"x": 24, "y": 24}
			}
		}

		var response: Dictionary = manager.generate_dungeon_contract(payload, 1)
		if not response.get("ok", false):
			push_error("US2 layout variety test failed generation: %s" % response)
			return

		var data: Dictionary = response.get("data", {})
		if not _has_role(data.get("roomRegions", []), "start") \
				or not _has_role(data.get("roomRegions", []), "mid") \
				or not _has_role(data.get("roomRegions", []), "exit"):
			push_error("US2 layout variety test failed: missing start/mid/exit")
			return
		if data.get("hallwayRegions", []).is_empty():
			push_error("US2 layout variety test failed: missing hallway region")
			return

		var signature: String = _walkable_signature(data)
		signatures[signature] = true
		if _has_loop(data):
			saw_loop = true

	if signatures.size() <= 1:
		push_error("US2 layout variety test failed: generated layouts did not vary")
		return
	if not saw_loop:
		push_error("US2 layout variety test failed: no run had a loop")
		return

	print("US2 layout variety test passed: unique signatures=", signatures.size())

func _has_role(regions: Array, role: String) -> bool:
	for region in regions:
		if str(region.get("role", "")) == role:
			return true
	return false

func _walkable_signature(data: Dictionary) -> String:
	var keys: Array[String] = []
	for region in data.get("roomRegions", []):
		for point in region.get("cells", []):
			keys.append("%d,%d" % [int(point.get("x", 0)), int(point.get("y", 0))])
	for region in data.get("hallwayRegions", []):
		for point in region.get("cells", []):
			keys.append("%d,%d" % [int(point.get("x", 0)), int(point.get("y", 0))])
	keys.sort()
	return ",".join(keys)

func _has_loop(data: Dictionary) -> bool:
	var walkable: Dictionary = {}
	var hallway: Dictionary = {}
	for region in data.get("roomRegions", []):
		for point in region.get("cells", []):
			walkable[_as_cell(point)] = true
	for region in data.get("hallwayRegions", []):
		for point in region.get("cells", []):
			var cell: Vector2i = _as_cell(point)
			walkable[cell] = true
			hallway[cell] = true
	var main_set: Dictionary = {}
	for point in data.get("mainPath", []):
		main_set[_as_cell(point)] = true
	for cell in hallway.keys():
		if not main_set.has(cell):
			return true
	var dirs: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
	for cell in walkable.keys():
		var degree: int = 0
		for d in dirs:
			if walkable.has(cell + d):
				degree += 1
		if degree >= 3:
			return true
	return false

func _as_cell(raw_value: Variant) -> Vector2i:
	if raw_value is Vector2i:
		return raw_value
	if raw_value is Dictionary:
		return Vector2i(int(raw_value.get("x", 0)), int(raw_value.get("y", 0)))
	return Vector2i.ZERO
