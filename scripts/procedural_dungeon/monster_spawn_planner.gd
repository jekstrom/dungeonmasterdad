class_name MonsterSpawnPlanner extends RefCounted

const MonsterCatalog = preload("res://scripts/procedural_dungeon/monster_catalog.gd")

var _monster_catalog: MonsterCatalog = MonsterCatalog.new()

func plan_spawns(
	layout_id: String,
	walkable_cells: Array[Vector2i],
	entrance_cell: Vector2i,
	exit_cell: Vector2i,
	generation_seed: int
) -> Array[Dictionary]:
	var candidate_cells: Array[Vector2i] = []
	for cell in walkable_cells:
		if cell == entrance_cell or cell == exit_cell:
			continue
		candidate_cells.append(cell)

	if candidate_cells.is_empty():
		return []

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = generation_seed + 421

	var type_ids: PackedStringArray = _monster_catalog.get_monster_type_ids()
	var spawn_count: int = mini(8, maxi(2, candidate_cells.size() / 20))

	var used_cells: Dictionary = {}
	var spawns: Array[Dictionary] = []
	for index in range(spawn_count):
		var attempts: int = 0
		var chosen_cell: Vector2i = candidate_cells[rng.randi_range(0, candidate_cells.size() - 1)]
		while used_cells.has(chosen_cell) and attempts < 8:
			chosen_cell = candidate_cells[rng.randi_range(0, candidate_cells.size() - 1)]
			attempts += 1

		if used_cells.has(chosen_cell):
			continue

		used_cells[chosen_cell] = true
		var type_id: String = str(type_ids[rng.randi_range(0, type_ids.size() - 1)])
		var scene_path: String = _monster_catalog.get_scene_path(type_id)
		if scene_path.is_empty():
			continue

		spawns.append({
			"spawnId": "%s_spawn_%d" % [layout_id, index],
			"monsterTypeId": type_id,
			"monsterScenePath": scene_path,
			"position": {
				"x": chosen_cell.x,
				"y": chosen_cell.y
			}
		})

	return spawns
