extends Node

## US-017 T001/T002: one Baja Blast boss at the exit room, skip-boss, south placeholder, host die.

const BOSS_SCENE := "res://monsters/baja_boss.tscn"
const ENTRANCE := Vector2i(2, 2)
const EXIT_CELL := Vector2i(16, 16)

func _ready() -> void:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager == null or not manager.has_method("generate_dungeon_contract"):
		_fail("US-017 T001: DungeonGenerationManager missing")
		return

	var response: Dictionary = manager.generate_dungeon_contract({
		"requestId": "us017-boss-spawn",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 16, "y": 16},
		"generationBounds": {"origin": {"x": 0, "y": 0}, "size": {"x": 24, "y": 24}},
		"roomCount": 4
	}, 1)
	if not response.get("ok", false):
		_fail("US-017 T001: generation failed %s" % response)
		return

	var data: Dictionary = response.get("data", {})
	if not _assert_one_exit_boss(data):
		return

	var skip_response: Dictionary = manager.generate_dungeon_contract({
		"requestId": "us017-boss-spawn-skip",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 16, "y": 16},
		"generationBounds": {"origin": {"x": 0, "y": 0}, "size": {"x": 24, "y": 24}},
		"roomCount": 4,
		"skipBoss": true
	}, 1)
	if not skip_response.get("ok", false):
		_fail("US-017 T001: skipBoss generation failed %s" % skip_response)
		return
	if _baja_bosses(skip_response.get("data", {}).get("monsterSpawns", [])).size() != 0:
		_fail("US-017 T001: skipBoss must yield zero baja_boss")
		return

	if not await _assert_boss_scene():
		return

	print("US-017 T001/T002 boss spawn test passed")
	get_tree().quit(0)


func _assert_one_exit_boss(data: Dictionary) -> bool:
	var bosses: Array = _baja_bosses(data.get("monsterSpawns", []))
	if bosses.size() != 1:
		_fail("US-017 T001: expected exactly one baja_boss, got %d" % bosses.size())
		return false
	var spawn: Dictionary = bosses[0]
	if str(spawn.get("monsterScenePath", "")) != BOSS_SCENE:
		_fail("US-017 T001: boss scene %s" % spawn.get("monsterScenePath", ""))
		return false
	var cell: Vector2i = _as_cell(spawn.get("position", {}))
	var entrance: Vector2i = _as_cell(data.get("entrance", ENTRANCE))
	var exit_cell: Vector2i = _as_cell(data.get("exit", EXIT_CELL))
	if cell == entrance:
		_fail("US-017 T001: boss must not spawn on entrance %s" % cell)
		return false
	if cell == exit_cell:
		_fail("US-017 T001: boss must not overlap exit cell %s" % cell)
		return false
	var start_cells: Dictionary = _role_cells(data, "start")
	if start_cells.has(cell):
		_fail("US-017 T001: boss must not spawn in the start room %s" % cell)
		return false
	var exit_cells: Dictionary = _role_cells(data, "exit")
	var near_exit: bool = DungeonGrid.chebyshev(cell, exit_cell) <= 4
	if not exit_cells.has(cell) and not near_exit:
		_fail("US-017 T001: boss %s is not in the exit room or near exit %s" % [cell, exit_cell])
		return false
	print("US-017 T001: boss cell=", cell, " entrance=", entrance, " exit=", exit_cell)
	return true


func _assert_boss_scene() -> bool:
	var packed: PackedScene = load(BOSS_SCENE) as PackedScene
	if packed == null:
		_fail("US-017 T002: failed to load baja_boss.tscn")
		return false
	var boss: Node = packed.instantiate()
	if boss == null:
		_fail("US-017 T002: failed to instantiate baja_boss.tscn")
		return false
	add_child(boss)
	await get_tree().process_frame
	var sprite: Sprite2D = boss.get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null or sprite.texture == null:
		_fail("US-017 T002: Sprite2D / texture missing")
		return false
	var tex_path: String = str(sprite.texture.resource_path)
	if tex_path.find("baja_boss.png") == -1:
		_fail("US-017 T002: expected baja_boss.png, got %s" % tex_path)
		return false
	if tex_path.find("mtdew") != -1 or tex_path.find("goblin") != -1 or tex_path.find("bajablast") != -1:
		_fail("US-017 T002: must not use can or goblin art")
		return false
	if sprite.hframes != 3:
		_fail("US-017 T002: hframes must be 3, got %d" % sprite.hframes)
		return false
	if sprite.scale != Vector2.ONE:
		_fail("US-017 T002: scale must be Vector2.ONE, got %s" % sprite.scale)
		return false
	if int(boss.get("max_hp")) < 1 or int(boss.get("hp")) < 1:
		_fail("US-017 T001: boss hp must be hosted and >= 1")
		return false
	if int(boss.get("max_hp")) != 12 or int(boss.get("hp")) != 12:
		_fail("US-017 T001: expected hp/max_hp 12, got %s/%s" % [boss.get("hp"), boss.get("max_hp")])
		return false
	if not multiplayer.is_server():
		_fail("US-017 T001: offline peer must be server for die()")
		return false
	boss.call("die")
	await get_tree().process_frame
	if not bool(boss.get("_dying")):
		_fail("US-017 T001: die() must set _dying on the host")
		return false
	return true


func _baja_bosses(spawns: Array) -> Array:
	var bosses: Array = []
	for spawn in spawns:
		if str(spawn.get("monsterTypeId", "")) == "baja_boss":
			bosses.append(spawn)
	return bosses


func _role_cells(data: Dictionary, role: String) -> Dictionary:
	var cells: Dictionary = {}
	for region in data.get("roomRegions", []):
		if str(region.get("role", "")) != role:
			continue
		for point in region.get("cells", []):
			cells[_as_cell(point)] = true
	return cells


func _as_cell(raw: Variant) -> Vector2i:
	return DungeonGrid.cell_from(raw)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
