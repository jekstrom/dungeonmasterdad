class_name MonsterSpawnPlanner extends RefCounted

const MonsterCatalog = preload("res://scripts/procedural_dungeon/monster_catalog.gd")

var _monster_catalog: MonsterCatalog = MonsterCatalog.new()

func plan_spawns(
	layout_id: String,
	room_regions: Array[Dictionary],
	hallway_regions: Array[Dictionary],
	entrance_cell: Vector2i,
	exit_cell: Vector2i,
	generation_seed: int
) -> Array[Dictionary]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = generation_seed

	var room_cells_by_id: Dictionary = {}
	var all_room_set: Dictionary = {}
	var hallway_set: Dictionary = {}
	for region in hallway_regions:
		for point in region.get("cells", []):
			hallway_set[_cell_from(point)] = true
	for region in room_regions:
		var cells: Array[Vector2i] = []
		for point in region.get("cells", []):
			var cell: Vector2i = _cell_from(point)
			cells.append(cell)
			all_room_set[cell] = true
		room_cells_by_id[str(region.get("roomId", ""))] = cells

	var door_set: Dictionary = {}
	for cell in all_room_set.keys():
		for neighbor in _neighbors(cell):
			if hallway_set.has(neighbor):
				door_set[cell] = true
				break

	var excluded: Dictionary = {
		entrance_cell: true,
		exit_cell: true
	}
	for neighbor in _neighbors(entrance_cell):
		excluded[neighbor] = true
	for neighbor in _neighbors(exit_cell):
		excluded[neighbor] = true
	for door in door_set.keys():
		excluded[door] = true
	for region in room_regions:
		var role: String = str(region.get("role", ""))
		if role != "start" and role != "deadend":
			continue
		for point in region.get("cells", []):
			excluded[_cell_from(point)] = true

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
		var package_types: Array[String] = _roll_room_package(role, knight_placed, rng)
		if package_types.has("knight"):
			knight_placed = true
		var cells: Array[Vector2i] = []
		for point in region.get("cells", []):
			cells.append(_cell_from(point))
		for type_id in package_types:
			var chosen: Vector2i = _pick_package_cell(cells, excluded, occupied, door_set, rng)
			if chosen == Vector2i(2147483647, 2147483647):
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
			cells.append(_cell_from(point))
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
		var chosen_hall: Vector2i = _pick_farthest(far_cells, door_set, occupied, rng, 8)
		if chosen_hall == Vector2i(2147483647, 2147483647):
			continue
		occupied[chosen_hall] = true
		var hall_spawn: Dictionary = _make_spawn(layout_id, spawn_index, "goblin", chosen_hall)
		if hall_spawn.is_empty():
			occupied.erase(chosen_hall)
			continue
		spawns.append(hall_spawn)
		spawn_index += 1

	return spawns

func _roll_room_package(role: String, knight_placed: bool, rng: RandomNumberGenerator) -> Array[String]:
	var empty: Array[String] = []
	if role == "start" or role == "deadend":
		return empty
	var roll: int = rng.randi_range(0, 99)
	if role == "mid":
		if roll <= 59:
			return ["goblin", "goblin"]
		if roll <= 89:
			return ["skeleton", "goblin"]
		if knight_placed:
			return ["goblin", "goblin"]
		return ["knight"]
	if role == "exit":
		if roll <= 69:
			return ["skeleton"]
		return empty
	return empty

func _pick_package_cell(
	cells: Array[Vector2i],
	excluded: Dictionary,
	occupied: Dictionary,
	door_set: Dictionary,
	rng: RandomNumberGenerator
) -> Vector2i:
	var candidates: Array[Vector2i] = []
	for cell in cells:
		if excluded.has(cell) or occupied.has(cell):
			continue
		candidates.append(cell)
	return _pick_farthest(candidates, door_set, occupied, rng, 8)

func _pick_farthest(
	candidates: Array[Vector2i],
	door_set: Dictionary,
	occupied: Dictionary,
	rng: RandomNumberGenerator,
	retries: int
) -> Vector2i:
	if candidates.is_empty():
		return Vector2i(2147483647, 2147483647)
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
	return Vector2i(2147483647, 2147483647)

func _min_door_distance(cell: Vector2i, door_set: Dictionary) -> int:
	if door_set.is_empty():
		return 0
	var best: int = 1_000_000
	for door in door_set.keys():
		var d: int = maxi(absi(cell.x - door.x), absi(cell.y - door.y))
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
		for neighbor in _neighbors(current):
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

func _cell_from(raw_value: Variant) -> Vector2i:
	if raw_value is Vector2i:
		return raw_value
	if raw_value is Dictionary:
		return Vector2i(int(raw_value.get("x", 0)), int(raw_value.get("y", 0)))
	return Vector2i.ZERO

func _neighbors(cell: Vector2i) -> Array[Vector2i]:
	return [
		cell + Vector2i(1, 0),
		cell + Vector2i(-1, 0),
		cell + Vector2i(0, 1),
		cell + Vector2i(0, -1)
	]
