class_name DungeonSpawnSet extends Resource

@export var layout_id: String = ""
@export var spawn_ruleset_id: String = "standard"
@export var spawns: Array[Dictionary] = []

func validate(entrance_cell: Vector2i, exit_cell: Vector2i, walkable_cells: Array[Vector2i]) -> Dictionary:
	for spawn in spawns:
		var raw_position: Variant = spawn.get("position", {})
		var spawn_position: Vector2i = _parse_point(raw_position)

		if spawn_position == entrance_cell or spawn_position == exit_cell:
			return _fail("POSITION_NOT_PLACEABLE", "Monster spawn cannot overlap entrance or exit")

		if not walkable_cells.has(spawn_position):
			return _fail("POSITION_NOT_PLACEABLE", "Monster spawn must be on a walkable cell")

		var scene_path: String = str(spawn.get("monsterScenePath", spawn.get("monster_scene_path", "")))
		if scene_path.strip_edges().is_empty():
			return _fail("INVALID_REQUEST", "Monster spawn is missing scene path")

	return {
		"ok": true,
		"error_code": "",
		"message": ""
	}

func _parse_point(raw_value: Variant) -> Vector2i:
	if raw_value is Vector2i:
		return raw_value
	if raw_value is Vector2:
		return Vector2i(raw_value)
	if raw_value is Dictionary:
		return Vector2i(int(raw_value.get("x", 0)), int(raw_value.get("y", 0)))
	return Vector2i.ZERO

func _fail(error_code: String, message: String) -> Dictionary:
	return {
		"ok": false,
		"error_code": error_code,
		"message": message
	}
