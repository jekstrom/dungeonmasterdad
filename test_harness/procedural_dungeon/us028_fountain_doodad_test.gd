extends Node

const FOUNTAIN_SCENE := "res://doodads/water_fountain.tscn"
const ENTRANCE := Vector2i(2, 2)
const EXIT_CELL := Vector2i(16, 16)


func _ready() -> void:
	if not await _run():
		return
	print("US-028 T001 fountain doodad test passed")
	get_tree().quit(0)


func _run() -> bool:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager == null or not manager.has_method("generate_dungeon_contract"):
		_fail("US-028 T001: DungeonGenerationManager missing")
		return false
	var payload := {
		"requestId": "us028-fountain",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 16, "y": 16},
		"generationBounds": {"origin": {"x": 0, "y": 0}, "size": {"x": 24, "y": 24}},
		"roomCount": 4
	}
	var response: Dictionary = manager.generate_dungeon_contract(payload, 1)
	if not response.get("ok", false):
		_fail("US-028 T001: generation failed %s" % response)
		return false
	var data: Dictionary = response.get("data", {})
	if not _assert_one_fountain(data):
		return false
	var response_b: Dictionary = manager.generate_dungeon_contract(payload, 1)
	if not response_b.get("ok", false):
		_fail("US-028 T001: second generation failed")
		return false
	if str(response_b.get("data", {}).get("fountain", {})) != str(data.get("fountain", {})):
		_fail("US-028 T001: same seed must produce the same fountain cell")
		return false
	var skip_response: Dictionary = manager.generate_dungeon_contract({
		"requestId": "us028-fountain-skip",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 16, "y": 16},
		"generationBounds": {"origin": {"x": 0, "y": 0}, "size": {"x": 24, "y": 24}},
		"roomCount": 4,
		"skipFountain": true
	}, 1)
	if not skip_response.get("ok", false):
		_fail("US-028 T001: skipFountain generation failed %s" % skip_response)
		return false
	var skip_fountain: Dictionary = skip_response.get("data", {}).get("fountain", {})
	if not skip_fountain.is_empty():
		_fail("US-028 T001: skipFountain must yield no fountain, got %s" % skip_fountain)
		return false
	if not await _assert_fountain_scene():
		return false
	if not _assert_no_boss_wave():
		return false
	return true


func _assert_one_fountain(data: Dictionary) -> bool:
	var raw: Variant = data.get("fountain", {})
	if not (raw is Dictionary) or (raw as Dictionary).is_empty():
		_fail("US-028 T001: expected exactly one fountain cell")
		return false
	var cell: Vector2i = DungeonGrid.cell_from(raw)
	var entrance: Vector2i = DungeonGrid.cell_from(data.get("entrance", ENTRANCE))
	var exit_cell: Vector2i = DungeonGrid.cell_from(data.get("exit", EXIT_CELL))
	if cell == entrance:
		_fail("US-028 T001: fountain must not spawn on entrance %s" % cell)
		return false
	if cell == exit_cell:
		_fail("US-028 T001: fountain must not spawn on exit %s" % cell)
		return false
	var walkable: Dictionary = {}
	for point in data.get("mainPath", []):
		walkable[DungeonGrid.cell_from(point)] = true
	for region in data.get("roomRegions", []):
		for point in region.get("cells", []):
			walkable[DungeonGrid.cell_from(point)] = true
	for region in data.get("hallwayRegions", []):
		for point in region.get("cells", []):
			walkable[DungeonGrid.cell_from(point)] = true
	if not walkable.has(cell):
		_fail("US-028 T001: fountain cell %s is not walkable" % cell)
		return false
	var boss_cell: Vector2i = DungeonGrid.SENTINEL
	for spawn in data.get("monsterSpawns", []):
		if str(spawn.get("monsterTypeId", "")) == "baja_boss":
			boss_cell = DungeonGrid.cell_from(spawn.get("position", {}))
			break
	var exit_cells: Dictionary = {}
	for region in data.get("roomRegions", []):
		if str(region.get("role", "")) != "exit":
			continue
		for point in region.get("cells", []):
			exit_cells[DungeonGrid.cell_from(point)] = true
	if boss_cell != DungeonGrid.SENTINEL:
		var boss_room: Dictionary = {}
		for region in data.get("roomRegions", []):
			var in_region := false
			var region_cells: Dictionary = {}
			for point in region.get("cells", []):
				var member: Vector2i = DungeonGrid.cell_from(point)
				region_cells[member] = true
				if member == boss_cell:
					in_region = true
			if in_region:
				boss_room = region_cells
				break
		if not boss_room.is_empty() and not boss_room.has(cell):
			_fail("US-028 T001: fountain %s must be in the Baja boss room" % cell)
			return false
		if cell == boss_cell:
			_fail("US-028 T001: fountain must not occupy the boss cell %s" % cell)
			return false
	elif not exit_cells.has(cell):
		_fail("US-028 T001: fountain %s must be in the exit room" % cell)
		return false
	print("US-028 T001: fountain cell=", cell, " entrance=", entrance, " exit=", exit_cell, " boss=", boss_cell)
	return true


func _assert_fountain_scene() -> bool:
	var packed: PackedScene = load(FOUNTAIN_SCENE) as PackedScene
	if packed == null:
		_fail("US-028 T001: failed to load water_fountain.tscn")
		return false
	var fountain: Node = packed.instantiate()
	if fountain == null:
		_fail("US-028 T001: failed to instantiate water_fountain.tscn")
		return false
	add_child(fountain)
	await get_tree().process_frame
	var body: StaticBody2D = fountain.get_node_or_null("StaticBody2D") as StaticBody2D
	if body == null:
		_fail("US-028 T001: fountain needs a StaticBody2D")
		return false
	if int(body.collision_layer) != 16:
		_fail("US-028 T001: fountain collision_layer must be 16, got %s" % body.collision_layer)
		return false
	var src := FileAccess.get_file_as_string("res://doodads/water_fountain.tscn")
	if src.find("bajablast") != -1:
		_fail("US-028 T001: do not use pickups/bajablast as the fountain body")
		return false
	fountain.queue_free()
	await get_tree().process_frame
	return true


func _assert_no_boss_wave() -> bool:
	var boss_src := FileAccess.get_file_as_string("res://monsters/baja_boss.gd")
	if boss_src.find("FreezeWave") != -1 or boss_src.find("freeze_wave") != -1:
		_fail("US-028 T001: do not add a Freeze Wave state to baja_boss")
		return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
