class_name MonsterSpawnPlanner extends RefCounted

const BAJA_BOSS_TYPE_ID := "baja_boss"

var _monster_catalog: MonsterCatalog = MonsterCatalog.new()

func plan_spawns(
	layout_id: String,
	room_regions: Array[Dictionary],
	hallway_regions: Array[Dictionary],
	entrance_cell: Vector2i,
	exit_cell: Vector2i,
	generation_seed: int,
	skip_boss: bool = false
) -> Array[Dictionary]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = generation_seed

	var room_cells_by_id: Dictionary = {}
	var all_room_set: Dictionary = {}
	var hallway_set: Dictionary = {}
	for region in hallway_regions:
		for point in region.get("cells", []):
			hallway_set[DungeonGrid.cell_from(point)] = true
	for region in room_regions:
		var cells: Array[Vector2i] = []
		for point in region.get("cells", []):
			var cell: Vector2i = DungeonGrid.cell_from(point)
			cells.append(cell)
			all_room_set[cell] = true
		room_cells_by_id[str(region.get("roomId", ""))] = cells

	var door_set: Dictionary = {}
	for cell in all_room_set.keys():
		for neighbor in DungeonGrid.neighbors(cell):
			if hallway_set.has(neighbor):
				door_set[cell] = true
				break

	var excluded: Dictionary = {
		entrance_cell: true,
		exit_cell: true
	}
	for neighbor in DungeonGrid.neighbors(entrance_cell):
		excluded[neighbor] = true
	for neighbor in DungeonGrid.neighbors(exit_cell):
		excluded[neighbor] = true
	for door in door_set.keys():
		excluded[door] = true
	for region in room_regions:
		var role: String = str(region.get("role", ""))
		if role != "start" and role != "deadend":
			continue
		for point in region.get("cells", []):
			excluded[DungeonGrid.cell_from(point)] = true

	var walkable: Dictionary = {}
	for cell in all_room_set.keys():
		walkable[cell] = true
	for cell in hallway_set.keys():
		walkable[cell] = true
	var door_distance: Dictionary = _multi_source_distance(door_set, walkable)

	var occupied: Dictionary = {}
	var spawns: Array[Dictionary] = []
	var knight_placed: bool = false
	var spawn_index: int = 0

	for region in room_regions:
		var role: String = str(region.get("role", ""))
		var package_types: Array[String] = _roll_room_package(role, knight_placed, rng, skip_boss)
		if package_types.has("knight"):
			knight_placed = true
		var cells: Array[Vector2i] = []
		for point in region.get("cells", []):
			cells.append(DungeonGrid.cell_from(point))
		for type_id in package_types:
			var chosen: Vector2i = _pick_package_cell(cells, excluded, occupied, door_set)
			if chosen == DungeonGrid.SENTINEL:
				continue
			occupied[chosen] = true
			var spawn: Dictionary = _make_spawn(layout_id, spawn_index, type_id, chosen)
			if spawn.is_empty():
				occupied.erase(chosen)
				continue
			spawns.append(spawn)
			spawn_index += 1

	for region in hallway_regions:
		var cells: Array[Vector2i] = []
		for point in region.get("cells", []):
			cells.append(DungeonGrid.cell_from(point))
		if cells.size() < 8:
			continue
		if rng.randi_range(0, 99) > 39:
			continue
		var far_cells: Array[Vector2i] = []
		for cell in cells:
			if excluded.has(cell) or occupied.has(cell):
				continue
			if int(door_distance.get(cell, 0)) < 3:
				continue
			far_cells.append(cell)
		if far_cells.is_empty():
			continue
		var chosen_hall: Vector2i = _pick_farthest(far_cells, door_set, occupied, 8)
		if chosen_hall == DungeonGrid.SENTINEL:
			continue
		occupied[chosen_hall] = true
		var hall_spawn: Dictionary = _make_spawn(layout_id, spawn_index, "skeleton", chosen_hall)
		if hall_spawn.is_empty():
			occupied.erase(chosen_hall)
			continue
		spawns.append(hall_spawn)
		spawn_index += 1

	_place_dungeon_goblins(
		spawns,
		room_regions,
		hallway_set,
		excluded,
		occupied,
		door_set,
		layout_id,
		spawn_index,
		rng
	)
	spawn_index = spawns.size()

	# US-017 T001: skip-boss tests keep skeletons; live matches force one boss in the exit room.
	if skip_boss:
		return _strip_baja_bosses(spawns)
	if _baja_boss_count(spawns) == 0:
		var forced: Dictionary = _force_exit_boss(
			layout_id,
			spawn_index,
			room_regions,
			entrance_cell,
			exit_cell,
			excluded,
			occupied,
			door_set
		)
		if not forced.is_empty():
			spawns.append(forced)
	return spawns

func _roll_room_package(role: String, _knight_placed: bool, rng: RandomNumberGenerator, skip_boss: bool) -> Array[String]:
	var empty: Array[String] = []
	if role == "start" or role == "deadend":
		return empty
	var roll: int = rng.randi_range(0, 99)
	if role == "mid":
		if roll <= 69:
			return ["skeleton", "skeleton"]
		return ["skeleton"]
	if role == "exit":
		# Exactly one Baja Blast boss in the exit package — not an extra skeleton.
		if skip_boss:
			return ["skeleton"]
		return [BAJA_BOSS_TYPE_ID]
	return empty

func _force_exit_boss(
	layout_id: String,
	spawn_index: int,
	room_regions: Array[Dictionary],
	entrance_cell: Vector2i,
	exit_cell: Vector2i,
	excluded: Dictionary,
	occupied: Dictionary,
	door_set: Dictionary
) -> Dictionary:
	var exit_cells: Array[Vector2i] = _exit_room_cells(room_regions)
	if exit_cells.is_empty():
		return {}
	var chosen: Vector2i = _pick_package_cell(exit_cells, excluded, occupied, door_set)
	if chosen == DungeonGrid.SENTINEL:
		# Default pick keeps exit_cell and its neighbors out so validate() passes.
		# If that leaves nothing, neighbors of the exit cell are allowed.
		var relaxed: Dictionary = excluded.duplicate()
		for neighbor in DungeonGrid.neighbors(exit_cell):
			relaxed.erase(neighbor)
		chosen = _pick_package_cell(exit_cells, relaxed, occupied, door_set)
	if chosen == DungeonGrid.SENTINEL:
		chosen = _first_free_exit_cell(exit_cells, entrance_cell, exit_cell, occupied)
	if chosen == DungeonGrid.SENTINEL:
		return {}
	occupied[chosen] = true
	var spawn: Dictionary = _make_spawn(layout_id, spawn_index, BAJA_BOSS_TYPE_ID, chosen)
	if spawn.is_empty():
		occupied.erase(chosen)
		return {}
	return spawn

func _place_dungeon_goblins(
	spawns: Array[Dictionary],
	room_regions: Array[Dictionary],
	hallway_set: Dictionary,
	excluded: Dictionary,
	occupied: Dictionary,
	door_set: Dictionary,
	layout_id: String,
	spawn_index: int,
	rng: RandomNumberGenerator
) -> void:
	var mid_count: int = 0
	var pool: Array[Vector2i] = []
	for region in room_regions:
		var role: String = str(region.get("role", ""))
		if role == "mid":
			mid_count += 1
		if role != "mid":
			continue
		for point in region.get("cells", []):
			var cell: Vector2i = DungeonGrid.cell_from(point)
			if excluded.has(cell) or occupied.has(cell):
				continue
			pool.append(cell)
	for cell in hallway_set.keys():
		if excluded.has(cell) or occupied.has(cell):
			continue
		pool.append(cell)
	if pool.is_empty():
		return
	_shuffle_cells(pool, rng)
	var want: int = clampi(mid_count + 1, DungeonConstants.MIN_DUNGEON_GOBLINS, DungeonConstants.MAX_DUNGEON_GOBLINS)
	var placed: int = 0
	var index: int = spawn_index
	for cell in pool:
		if placed >= want:
			break
		if occupied.has(cell):
			continue
		var spawn: Dictionary = _make_spawn(layout_id, index, "goblin", cell)
		if spawn.is_empty():
			continue
		occupied[cell] = true
		spawns.append(spawn)
		index += 1
		placed += 1


func _shuffle_cells(cells: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(cells.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Vector2i = cells[i]
		cells[i] = cells[j]
		cells[j] = tmp


func _exit_room_cells(room_regions: Array[Dictionary]) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for region in room_regions:
		if str(region.get("role", "")) != "exit":
			continue
		for point in region.get("cells", []):
			cells.append(DungeonGrid.cell_from(point))
	return cells

func _first_free_exit_cell(
	exit_cells: Array[Vector2i],
	entrance_cell: Vector2i,
	exit_cell: Vector2i,
	occupied: Dictionary
) -> Vector2i:
	for cell in exit_cells:
		if cell == entrance_cell or cell == exit_cell:
			continue
		if occupied.has(cell):
			continue
		return cell
	return DungeonGrid.SENTINEL

func _baja_boss_count(spawns: Array[Dictionary]) -> int:
	var count: int = 0
	for spawn in spawns:
		if str(spawn.get("monsterTypeId", "")) == BAJA_BOSS_TYPE_ID:
			count += 1
	return count

func _strip_baja_bosses(spawns: Array[Dictionary]) -> Array[Dictionary]:
	var kept: Array[Dictionary] = []
	for spawn in spawns:
		if str(spawn.get("monsterTypeId", "")) == BAJA_BOSS_TYPE_ID:
			continue
		kept.append(spawn)
	return kept

func _pick_package_cell(
	cells: Array[Vector2i],
	excluded: Dictionary,
	occupied: Dictionary,
	door_set: Dictionary
) -> Vector2i:
	var candidates: Array[Vector2i] = []
	for cell in cells:
		if excluded.has(cell) or occupied.has(cell):
			continue
		candidates.append(cell)
	return _pick_farthest(candidates, door_set, occupied, 8)

func _pick_farthest(
	candidates: Array[Vector2i],
	door_set: Dictionary,
	occupied: Dictionary,
	retries: int
) -> Vector2i:
	if candidates.is_empty():
		return DungeonGrid.SENTINEL
	var scored: Array[Dictionary] = []
	for cell in candidates:
		scored.append({
			"cell": cell,
			"score": _min_door_distance(cell, door_set)
		})
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("score", 0)) > int(b.get("score", 0))
	)
	var attempts: int = 0
	while attempts < retries and attempts < scored.size():
		var cell: Vector2i = scored[attempts]["cell"]
		if not occupied.has(cell):
			return cell
		attempts += 1
	return DungeonGrid.SENTINEL

func _min_door_distance(cell: Vector2i, door_set: Dictionary) -> int:
	if door_set.is_empty():
		return 0
	var best: int = 1_000_000
	for door in door_set.keys():
		var d: int = DungeonGrid.chebyshev(cell, door)
		if d < best:
			best = d
	return best

func _multi_source_distance(sources: Dictionary, walkable: Dictionary) -> Dictionary:
	var dist: Dictionary = {}
	var queue: Array[Vector2i] = []
	for cell in sources.keys():
		if not walkable.has(cell):
			continue
		dist[cell] = 0
		queue.append(cell)
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		var current_d: int = int(dist[current])
		for neighbor in DungeonGrid.neighbors(current):
			if not walkable.has(neighbor) or dist.has(neighbor):
				continue
			dist[neighbor] = current_d + 1
			queue.append(neighbor)
	return dist

func _make_spawn(layout_id: String, index: int, type_id: String, cell: Vector2i) -> Dictionary:
	var scene_path: String = _monster_catalog.get_scene_path(type_id)
	if scene_path.is_empty():
		return {}
	return {
		"spawnId": "%s_spawn_%d" % [layout_id, index],
		"monsterTypeId": type_id,
		"monsterScenePath": scene_path,
		"position": {
			"x": cell.x,
			"y": cell.y
		}
	}
