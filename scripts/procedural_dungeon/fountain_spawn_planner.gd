class_name FountainSpawnPlanner extends RefCounted

const FOUNTAIN_SCENE_PATH: String = "res://doodads/water_fountain.tscn"
const BAJA_BOSS_TYPE_ID := "baja_boss"

func plan_fountain_cell(
	room_regions: Array[Dictionary],
	walkable_cells: Array[Vector2i],
	entrance_cell: Vector2i,
	exit_cell: Vector2i,
	generation_seed: int,
	monster_spawns: Array = [],
	item_pickups: Array = [],
	skip_fountain: bool = false
) -> Vector2i:
	if skip_fountain:
		return DungeonGrid.SENTINEL

	var occupied: Dictionary = {
		entrance_cell: true,
		exit_cell: true
	}
	var boss_cell: Vector2i = DungeonGrid.SENTINEL
	for spawn in monster_spawns:
		if not (spawn is Dictionary):
			continue
		var cell: Vector2i = DungeonGrid.cell_from(spawn.get("position", {}))
		occupied[cell] = true
		if str(spawn.get("monsterTypeId", "")) == BAJA_BOSS_TYPE_ID:
			boss_cell = cell
	for pickup in item_pickups:
		if pickup is Dictionary:
			occupied[DungeonGrid.cell_from(pickup.get("position", {}))] = true

	var walkable: Dictionary = {}
	for raw_cell in walkable_cells:
		walkable[DungeonGrid.cell_from(raw_cell)] = true

	var rng := RandomNumberGenerator.new()
	rng.seed = generation_seed

	var arena: Array[Vector2i] = _boss_room_cells(room_regions, boss_cell, walkable, occupied)
	_shuffle_cells(arena, rng)
	var chosen: Vector2i = _first_free(arena, occupied, boss_cell)
	if chosen != DungeonGrid.SENTINEL:
		return chosen

	var occupied_relaxed: Dictionary = occupied.duplicate()
	if boss_cell != DungeonGrid.SENTINEL:
		occupied_relaxed.erase(boss_cell)
	var arena_with_boss: Array[Vector2i] = _boss_room_cells(room_regions, boss_cell, walkable, occupied_relaxed)
	_shuffle_cells(arena_with_boss, rng)
	chosen = _first_free(arena_with_boss, occupied_relaxed, DungeonGrid.SENTINEL)
	if chosen != DungeonGrid.SENTINEL:
		return chosen
	return DungeonGrid.SENTINEL


func _boss_room_cells(
	room_regions: Array[Dictionary],
	boss_cell: Vector2i,
	walkable: Dictionary,
	occupied: Dictionary
) -> Array[Vector2i]:
	var target_role := "exit"
	if boss_cell != DungeonGrid.SENTINEL:
		for region in room_regions:
			for point in region.get("cells", []):
				if DungeonGrid.cell_from(point) == boss_cell:
					target_role = str(region.get("role", "exit"))
					break
	var cells: Array[Vector2i] = []
	var seen: Dictionary = {}
	for region in room_regions:
		if str(region.get("role", "")) != target_role:
			continue
		for point in region.get("cells", []):
			var cell: Vector2i = DungeonGrid.cell_from(point)
			if seen.has(cell) or not walkable.has(cell) or occupied.has(cell):
				continue
			seen[cell] = true
			cells.append(cell)
	return cells


func _first_free(pool: Array[Vector2i], occupied: Dictionary, boss_cell: Vector2i) -> Vector2i:
	for cell in pool:
		if occupied.has(cell):
			continue
		if cell == boss_cell:
			continue
		return cell
	return DungeonGrid.SENTINEL


func room_cells_containing(room_regions: Array[Dictionary], cell: Vector2i) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for region in room_regions:
		var cells: Array[Vector2i] = []
		var has_cell := false
		for point in region.get("cells", []):
			var member: Vector2i = DungeonGrid.cell_from(point)
			cells.append(member)
			if member == cell:
				has_cell = true
		if has_cell:
			return cells
	found.append(cell)
	return found


func _shuffle_cells(cells: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(cells.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Vector2i = cells[i]
		cells[i] = cells[j]
		cells[j] = tmp
