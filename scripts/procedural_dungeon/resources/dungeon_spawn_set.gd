class_name DungeonSpawnSet extends Resource

@export var layout_id: String = ""
@export var spawn_ruleset_id: String = "standard"
@export var spawns: Array[Dictionary] = []

func validate(entrance_cell: Vector2i, exit_cell: Vector2i, walkable_cells: Array[Vector2i]) -> Dictionary:
	var catalog: MonsterCatalog = MonsterCatalog.new()
	for spawn in spawns:
		var raw_position: Variant = spawn.get("position", {})
		var spawn_position: Vector2i = DungeonGrid.cell_from(raw_position)

		if spawn_position == entrance_cell or spawn_position == exit_cell:
			return DungeonGrid.fail("POSITION_NOT_PLACEABLE", "Monster spawn cannot overlap entrance or exit")

		if not walkable_cells.has(spawn_position):
			return DungeonGrid.fail("POSITION_NOT_PLACEABLE", "Monster spawn must be on a walkable cell")

		var scene_path: String = str(spawn.get("monsterScenePath", spawn.get("monster_scene_path", "")))
		if scene_path.strip_edges().is_empty():
			return DungeonGrid.fail("INVALID_REQUEST", "Monster spawn is missing scene path")
		if not catalog.is_approved_scene_path(scene_path):
			return DungeonGrid.fail("INVALID_REQUEST", "Monster spawn path is not in the catalog")

	return {
		"ok": true,
		"error_code": "",
		"message": ""
	}
