class_name PickupSpawnPlanner extends RefCounted

const GREEN_DEW_PATH: String = "res://pickups/mtdew.tres"
const D6_PATH: String = "res://pickups/d6.tres"
const D20_PATH: String = "res://pickups/d20.tres"

const START_ROOM_DEW_COUNT: int = DungeonConstants.DEFAULT_START_ROOM_DEW_COUNT
const EXTRA_DEW_COUNT: int = DungeonConstants.DEFAULT_EXTRA_DEW_COUNT
const D6_COUNT: int = DungeonConstants.DEFAULT_D6_COUNT
const D20_COUNT: int = DungeonConstants.DEFAULT_D20_COUNT

func plan_dungeon_pickups(
	room_regions: Array[Dictionary],
	_hallway_regions: Array[Dictionary],
	walkable_cells: Array[Vector2i],
	entrance_cell: Vector2i,
	exit_cell: Vector2i,
	generation_seed: int,
	monster_spawns: Array = [],
	pickup_counts: Dictionary = {}
) -> Array[Dictionary]:
	var start_dew_count: int = _count_from(pickup_counts, "start_room_dew", START_ROOM_DEW_COUNT)
	var extra_dew: int = _count_from(pickup_counts, "extra_dew", EXTRA_DEW_COUNT)
	var d6_count: int = _count_from(pickup_counts, "d6", D6_COUNT)
	var d20_count: int = _count_from(pickup_counts, "d20", D20_COUNT)
	var pickups: Array[Dictionary] = []
	pickups.append_array(plan_start_room_dew(room_regions, entrance_cell, exit_cell, start_dew_count))

	var occupied: Dictionary = {
		entrance_cell: true,
		exit_cell: true
	}
	for pickup in pickups:
		occupied[DungeonGrid.cell_from(pickup.get("position", {}))] = true
	for spawn in monster_spawns:
		if spawn is Dictionary:
			occupied[DungeonGrid.cell_from(spawn.get("position", {}))] = true

	var walkable: Dictionary = {}
	var walkable_list: Array[Vector2i] = []
	for raw_cell in walkable_cells:
		var cell: Vector2i = DungeonGrid.cell_from(raw_cell)
		if walkable.has(cell):
			continue
		walkable[cell] = true
		walkable_list.append(cell)

	var start_set: Dictionary = _start_room_set(room_regions)
	var preferred: Array[Vector2i] = []
	var fallback: Array[Vector2i] = []
	for cell in walkable_list:
		if occupied.has(cell):
			continue
		if start_set.has(cell):
			fallback.append(cell)
		else:
			preferred.append(cell)

	var rng := RandomNumberGenerator.new()
	rng.seed = generation_seed
	_shuffle_cells(preferred, rng)
	_shuffle_cells(fallback, rng)
	var pool: Array[Vector2i] = []
	pool.append_array(preferred)
	pool.append_array(fallback)

	while extra_dew > 0:
		var dew_cell: Vector2i = _take_free_cell(pool, occupied)
		if dew_cell == DungeonGrid.SENTINEL:
			break
		pickups.append(_pickup(GREEN_DEW_PATH, dew_cell))
		occupied[dew_cell] = true
		extra_dew -= 1

	var dice_paths: Array[String] = []
	for _i in d6_count:
		dice_paths.append(D6_PATH)
	for _i in d20_count:
		dice_paths.append(D20_PATH)

	var placed_dice: int = 0
	for path in dice_paths:
		var die_cell: Vector2i = _take_free_cell(pool, occupied)
		if die_cell == DungeonGrid.SENTINEL:
			break
		pickups.append(_pickup(path, die_cell))
		occupied[die_cell] = true
		placed_dice += 1

	if placed_dice == 0 and (d6_count + d20_count) > 0:
		for cell in walkable_list:
			if cell == entrance_cell or cell == exit_cell:
				continue
			pickups.append(_pickup(D6_PATH, cell))
			break

	return pickups

func plan_start_room_dew(
	room_regions: Array[Dictionary],
	entrance_cell: Vector2i,
	exit_cell: Vector2i,
	start_dew_count: int = START_ROOM_DEW_COUNT
) -> Array[Dictionary]:
	var pickups: Array[Dictionary] = []
	for cell in _start_room_dew_cells(room_regions, entrance_cell, exit_cell, start_dew_count):
		pickups.append(_pickup(GREEN_DEW_PATH, cell))
	return pickups

func _start_room_dew_cells(
	room_regions: Array[Dictionary],
	entrance_cell: Vector2i,
	exit_cell: Vector2i,
	start_dew_count: int = START_ROOM_DEW_COUNT
) -> Array[Vector2i]:
	var wanted: int = maxi(0, start_dew_count)
	if wanted == 0:
		return []
	var start_set: Dictionary = _start_room_set(room_regions)
	var chosen: Array[Vector2i] = []
	var occupied: Dictionary = {
		entrance_cell: true,
		exit_cell: true
	}
	for step in DungeonGrid.cardinals():
		var neighbor: Vector2i = entrance_cell + step
		if start_set.has(neighbor) and not occupied.has(neighbor):
			chosen.append(neighbor)
			occupied[neighbor] = true
			if chosen.size() >= wanted:
				return chosen
	for cell in start_set.keys():
		if occupied.has(cell):
			continue
		chosen.append(cell)
		occupied[cell] = true
		if chosen.size() >= wanted:
			return chosen
	return chosen

func _start_room_set(room_regions: Array[Dictionary]) -> Dictionary:
	var start_set: Dictionary = {}
	for region in room_regions:
		if str(region.get("role", "")) != "start":
			continue
		for point in region.get("cells", []):
			start_set[DungeonGrid.cell_from(point)] = true
	return start_set

func _count_from(counts: Dictionary, key: String, default_value: int) -> int:
	if counts.is_empty() or not counts.has(key):
		return maxi(0, default_value)
	return clampi(int(counts[key]), 0, DungeonConstants.MAX_PICKUP_COUNT)

func _pickup(item_type: String, cell: Vector2i) -> Dictionary:
	return {
		"item_type": item_type,
		"position": {"x": cell.x, "y": cell.y}
	}

func _take_free_cell(pool: Array[Vector2i], occupied: Dictionary) -> Vector2i:
	while not pool.is_empty():
		var cell: Vector2i = pool.pop_front()
		if occupied.has(cell):
			continue
		return cell
	return DungeonGrid.SENTINEL

func _shuffle_cells(cells: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(cells.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Vector2i = cells[i]
		cells[i] = cells[j]
		cells[j] = tmp
