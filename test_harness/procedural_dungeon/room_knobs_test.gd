extends Node

func _ready() -> void:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager == null or not manager.has_method("generate_dungeon_contract"):
		push_error("Room knobs test: DungeonGenerationManager missing")
		return

	var three: Dictionary = manager.generate_dungeon_contract({
		"requestId": "room-knobs-count-3",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 16, "y": 16},
		"generationBounds": {"origin": {"x": 0, "y": 0}, "size": {"x": 24, "y": 24}},
		"roomSize": 5,
		"roomCount": 3
	}, 1)
	if not three.get("ok", false):
		push_error("Room knobs test failed count=3: %s" % three)
		return
	var mid_count: int = _role_count(three.get("data", {}).get("roomRegions", []), "mid")
	if mid_count != 1:
		push_error("Room knobs test failed: roomCount 3 should yield 1 mid room, got %d" % mid_count)
		return

	var small: Dictionary = manager.generate_dungeon_contract({
		"requestId": "room-knobs-size-3",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 16, "y": 16},
		"generationBounds": {"origin": {"x": 0, "y": 0}, "size": {"x": 24, "y": 24}},
		"roomSize": 3,
		"roomCount": 3
	}, 1)
	if not small.get("ok", false):
		push_error("Room knobs test failed size=3: %s" % small)
		return
	var start_small: int = _start_room_cells(small.get("data", {}).get("roomRegions", []))
	if start_small != 9:
		push_error("Room knobs test failed: roomSize 3 start room should have 9 cells, got %d" % start_small)
		return

	print("Room knobs test passed: mid_count=", mid_count, " start_cells_size3=", start_small)
	get_tree().quit(0)

func _role_count(regions: Array, role: String) -> int:
	var count: int = 0
	for region in regions:
		if str(region.get("role", "")) == role:
			count += 1
	return count

func _start_room_cells(regions: Array) -> int:
	for region in regions:
		if str(region.get("role", "")) == "start":
			return (region.get("cells", []) as Array).size()
	return 0
