class_name MazeInfillGenerator extends RefCounted

var _path_validator: PathValidator = PathValidator.new()

func generate_infill(
	bounds: Rect2i,
	room_regions: Array[Dictionary],
	hallway_cells: Array[Vector2i],
	entrance_cell: Vector2i,
	exit_cell: Vector2i,
	d_seed: int
) -> Dictionary:
	var empty_hall: Array[Vector2i] = []
	var empty_dead: Array[Dictionary] = []

	var mid_count: int = 0
	var room_set: Dictionary = {}
	var room_centers: Array[Vector2i] = []
	for region in room_regions:
		if str(region.get("role", "")) == "mid":
			mid_count += 1
		var center_raw: Variant = region.get("center", {})
		if center_raw is Dictionary or center_raw is Vector2i:
			room_centers.append(DungeonGrid.cell_from(center_raw))
		for point in region.get("cells", []):
			room_set[DungeonGrid.cell_from(point)] = true

	var deadend_count: int = clampi(mid_count, 1, 3)
	var hallway_set: Dictionary = {}
	for cell in hallway_cells:
		if room_set.has(cell):
			continue
		hallway_set[cell] = true

	var walkable: Dictionary = {}
	for cell in room_set.keys():
		walkable[cell] = true
	for cell in hallway_set.keys():
		walkable[cell] = true

	var walkable_cells: Array[Vector2i] = []
	for cell in walkable.keys():
		walkable_cells.append(cell)
	var main_path: Dictionary = _path_validator.build_shortest_path_set(entrance_cell, exit_cell, walkable_cells)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = d_seed

	var branch_cells: Dictionary = {}
	var deadend_regions: Array[Dictionary] = []
	var used_roots: Dictionary = {}

	for slot in range(deadend_count):
		var placed: bool = false
		for _try in range(8):
			var door_neighbor_set: Dictionary = _door_neighbor_hallway_cells(room_set, hallway_set)
			var root: Vector2i = _pick_root(
				hallway_set,
				door_neighbor_set,
				main_path,
				used_roots,
				rng
			)
			if root == DungeonGrid.SENTINEL:
				break
			used_roots[root] = true
			var grown: Dictionary = _grow_deadend(
				root,
				bounds,
				room_set,
				hallway_set,
				room_centers,
				rng
			)
			if not grown.get("ok", false):
				continue

			var pocket_cells: Array[Vector2i] = grown["pocket_cells"]
			var walk_cells: Array[Vector2i] = grown["walk_cells"]
			var pocket_center: Vector2i = grown["center"]
			for cell in pocket_cells:
				room_set[cell] = true
				hallway_set.erase(cell)
				branch_cells.erase(cell)
			for cell in walk_cells:
				if room_set.has(cell):
					continue
				hallway_set[cell] = true
				branch_cells[cell] = true
			room_centers.append(pocket_center)
			deadend_regions.append(_build_deadend_region(deadend_regions.size() + 1, pocket_center, pocket_cells))
			placed = true
			break
		if not placed:
			continue

	if deadend_regions.is_empty():
		return {
			"ok": false,
			"hallway_cells": empty_hall,
			"deadend_regions": empty_dead,
			"error_code": "LAYOUT_INFEASIBLE",
			"message": "Failed to place any dead-end pockets"
		}

	var out_hall: Array[Vector2i] = []
	for cell in branch_cells.keys():
		out_hall.append(cell)

	return {
		"ok": true,
		"hallway_cells": out_hall,
		"deadend_regions": deadend_regions
	}

func _grow_deadend(
	root: Vector2i,
	bounds: Rect2i,
	room_set: Dictionary,
	hallway_set: Dictionary,
	room_centers: Array[Vector2i],
	rng: RandomNumberGenerator
) -> Dictionary:
	var blocked: Dictionary = {}
	for cell in room_set.keys():
		blocked[cell] = true

	var walk_length: int = rng.randi_range(4, 8)
	var current: Vector2i = root
	var walk_cells: Array[Vector2i] = []
	var walk_set: Dictionary = {}

	for _step in range(walk_length):
		var options: Array[Vector2i] = []
		var better: Array[Vector2i] = []
		var current_d: int = _nearest_center_distance(current, room_centers)
		for neighbor in DungeonGrid.neighbors(current):
			if not bounds.has_point(neighbor):
				continue
			if blocked.has(neighbor):
				continue
			if hallway_set.has(neighbor) or walk_set.has(neighbor):
				continue
			if neighbor == root:
				continue
			options.append(neighbor)
			if _nearest_center_distance(neighbor, room_centers) > current_d:
				better.append(neighbor)
		var pool: Array[Vector2i] = better if not better.is_empty() else options
		if pool.is_empty():
			break
		current = pool[rng.randi_range(0, pool.size() - 1)]
		walk_set[current] = true
		walk_cells.append(current)

	if walk_cells.size() < 4:
		return {"ok": false}

	var terminal: Vector2i = walk_cells[walk_cells.size() - 1]
	var pocket_cells: Array[Vector2i] = []
	for y in range(terminal.y - 1, terminal.y + 2):
		for x in range(terminal.x - 1, terminal.x + 2):
			var candidate: Vector2i = Vector2i(x, y)
			if not bounds.has_point(candidate):
				continue
			if room_set.has(candidate):
				return {"ok": false}
			pocket_cells.append(candidate)

	if pocket_cells.size() < 5:
		return {"ok": false}

	var remaining_walk: Array[Vector2i] = []
	var pocket_set: Dictionary = {}
	for cell in pocket_cells:
		pocket_set[cell] = true
	for cell in walk_cells:
		if pocket_set.has(cell):
			continue
		remaining_walk.append(cell)

	return {
		"ok": true,
		"center": terminal,
		"pocket_cells": pocket_cells,
		"walk_cells": remaining_walk
	}

func _pick_root(
	hallway_set: Dictionary,
	door_neighbor_set: Dictionary,
	main_path: Dictionary,
	used_roots: Dictionary,
	rng: RandomNumberGenerator
) -> Vector2i:
	var preferred: Array[Vector2i] = []
	var fallback: Array[Vector2i] = []
	var any_hall: Array[Vector2i] = []
	for cell in hallway_set.keys():
		if used_roots.has(cell):
			continue
		any_hall.append(cell)
		var is_door_neighbor: bool = door_neighbor_set.has(cell)
		var on_main: bool = main_path.has(cell)
		if not is_door_neighbor and not on_main:
			preferred.append(cell)
		elif not is_door_neighbor:
			fallback.append(cell)

	var pool: Array[Vector2i] = preferred
	if pool.is_empty():
		pool = fallback
	if pool.is_empty():
		pool = any_hall
	if pool.is_empty():
		return DungeonGrid.SENTINEL
	return pool[rng.randi_range(0, pool.size() - 1)]

func _door_neighbor_hallway_cells(room_set: Dictionary, hallway_set: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for room_cell in room_set.keys():
		for neighbor in DungeonGrid.neighbors(room_cell):
			if hallway_set.has(neighbor):
				result[neighbor] = true
	return result

func _nearest_center_distance(cell: Vector2i, centers: Array[Vector2i]) -> int:
	var best: int = 1_000_000
	for center in centers:
		var d: int = DungeonGrid.chebyshev(cell, center)
		if d < best:
			best = d
	return best

func _build_deadend_region(index: int, center: Vector2i, cells: Array[Vector2i]) -> Dictionary:
	return {
		"roomId": "room_deadend_%d" % index,
		"role": "deadend",
		"center": {"x": center.x, "y": center.y},
		"cells": DungeonGrid.points_to_dicts(cells)
	}
