class_name RoomGraphGenerator extends RefCounted

const ROOM_RADIUS: int = 2
const MIN_SEPARATION: int = 6
const MIN_ROOM_CELLS: int = 9

func generate_room_backbone(
	start_cell: Vector2i,
	exit_cell: Vector2i,
	generation_bounds: Rect2i,
	generation_seed: int
) -> Dictionary:
	if _chebyshev(start_cell, exit_cell) < MIN_SEPARATION:
		return _fail("LAYOUT_INFEASIBLE", "Start and exit rooms violate center separation")

	var start_cells: Array[Vector2i] = _build_room_cells(start_cell, generation_bounds, ROOM_RADIUS)
	var exit_cells: Array[Vector2i] = _build_room_cells(exit_cell, generation_bounds, ROOM_RADIUS)
	if start_cells.size() < MIN_ROOM_CELLS or exit_cells.size() < MIN_ROOM_CELLS:
		return _fail("LAYOUT_INFEASIBLE", "Start or exit room too small after clip")

	var area: int = generation_bounds.size.x * generation_bounds.size.y
	var mid_count: int = clampi(area / 180, 1, 3)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = generation_seed

	var l_cells: Array[Vector2i] = _carve_l(start_cell, exit_cell, generation_bounds)
	var candidates: Array[Vector2i] = []
	for cell in l_cells:
		if _chebyshev(cell, start_cell) < MIN_SEPARATION:
			continue
		if _chebyshev(cell, exit_cell) < MIN_SEPARATION:
			continue
		if not generation_bounds.has_point(cell):
			continue
		candidates.append(cell)

	_shuffle_cells(candidates, rng)

	var chosen: Array[Vector2i] = []
	for cand in candidates:
		if chosen.size() >= mid_count:
			break
		if not _separated_from_all(cand, chosen):
			continue
		var clipped: Array[Vector2i] = _build_room_cells(cand, generation_bounds, ROOM_RADIUS)
		if clipped.size() < MIN_ROOM_CELLS:
			continue
		chosen.append(cand)

	if chosen.size() < mid_count:
		return _fail("LAYOUT_INFEASIBLE", "Unable to place required mid rooms")

	if mid_count >= 2:
		var jittered: Array[Vector2i] = _jitter_one_mid(
			chosen,
			start_cell,
			exit_cell,
			generation_bounds,
			rng
		)
		if jittered.is_empty():
			return _fail("LAYOUT_INFEASIBLE", "Unable to jitter a mid room off the backbone L")
		chosen = jittered

	var axis: Vector2 = Vector2(exit_cell - start_cell)
	chosen.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return Vector2(a).dot(axis) < Vector2(b).dot(axis)
	)

	var ordered_ids: Array[String] = ["room_start"]
	var ordered_centers: Array[Vector2i] = [start_cell]
	var room_regions: Array[Dictionary] = [
		_build_room_region("room_start", "start", start_cell, start_cells)
	]
	for i in range(chosen.size()):
		var mid_id: String = "room_mid_%d" % (i + 1)
		var mid_center: Vector2i = chosen[i]
		var mid_cells: Array[Vector2i] = _build_room_cells(mid_center, generation_bounds, ROOM_RADIUS)
		ordered_ids.append(mid_id)
		ordered_centers.append(mid_center)
		room_regions.append(_build_room_region(mid_id, "mid", mid_center, mid_cells))
	ordered_ids.append("room_exit")
	ordered_centers.append(exit_cell)
	room_regions.append(_build_room_region("room_exit", "exit", exit_cell, exit_cells))

	var graph_edges: Array = []
	for i in range(ordered_ids.size() - 1):
		graph_edges.append([ordered_ids[i], ordered_ids[i + 1]])

	if mid_count >= 2 and (generation_seed % 2) == 0:
		var extra: Array = _pick_extra_edge(
			ordered_ids,
			ordered_centers,
			generation_bounds,
			room_regions
		)
		if extra.size() == 2:
			graph_edges.append(extra)

	var walkable_set: Dictionary = {}
	var walkable_cells: Array[Vector2i] = []
	for region in room_regions:
		for point in region.get("cells", []):
			var cell: Vector2i = Vector2i(int(point.get("x", 0)), int(point.get("y", 0)))
			if walkable_set.has(cell):
				continue
			walkable_set[cell] = true
			walkable_cells.append(cell)

	return {
		"ok": true,
		"walkable_cells": walkable_cells,
		"room_regions": room_regions,
		"graph_edges": graph_edges
	}

func _jitter_one_mid(
	placed: Array[Vector2i],
	start_cell: Vector2i,
	exit_cell: Vector2i,
	bounds: Rect2i,
	rng: RandomNumberGenerator
) -> Array[Vector2i]:
	var indices: Array[int] = []
	for i in range(placed.size()):
		indices.append(i)
	_shuffle_ints(indices, rng)

	for idx in indices:
		var original: Vector2i = placed[idx]
		var deltas: Array[Vector2i] = _jitter_deltas(original, start_cell, exit_cell)
		_shuffle_cells(deltas, rng)
		for delta in deltas:
			var candidate: Vector2i = original + delta
			if not bounds.has_point(candidate):
				continue
			var others: Array[Vector2i] = [start_cell, exit_cell]
			for j in range(placed.size()):
				if j == idx:
					continue
				others.append(placed[j])
			if not _separated_from_all(candidate, others):
				continue
			if _build_room_cells(candidate, bounds, ROOM_RADIUS).size() < MIN_ROOM_CELLS:
				continue
			var result: Array[Vector2i] = placed.duplicate()
			result[idx] = candidate
			return result

	return []

func _jitter_deltas(original: Vector2i, start_cell: Vector2i, exit_cell: Vector2i) -> Array[Vector2i]:
	# Horizontal L segment (X-then-Y first leg) jitters Y; vertical second leg jitters X.
	var horizontal: bool = original.y == start_cell.y
	var deltas: Array[Vector2i] = []
	for distance in range(4, 9):
		if horizontal:
			deltas.append(Vector2i(0, distance))
			deltas.append(Vector2i(0, -distance))
		else:
			deltas.append(Vector2i(distance, 0))
			deltas.append(Vector2i(-distance, 0))
	# Corner sits on both legs; also try the other axis if the primary fails later in the caller.
	if original.y == start_cell.y and original.x == exit_cell.x:
		for distance in range(4, 9):
			deltas.append(Vector2i(distance, 0))
			deltas.append(Vector2i(-distance, 0))
	return deltas

func _pick_extra_edge(
	ordered_ids: Array[String],
	ordered_centers: Array[Vector2i],
	bounds: Rect2i,
	room_regions: Array[Dictionary]
) -> Array:
	var backbone_set: Dictionary = {}
	for i in range(ordered_centers.size() - 1):
		for cell in _carve_l(ordered_centers[i], ordered_centers[i + 1], bounds):
			backbone_set[cell] = true

	var room_set: Dictionary = {}
	for region in room_regions:
		for point in region.get("cells", []):
			room_set[Vector2i(int(point.get("x", 0)), int(point.get("y", 0)))] = true

	var pairs: Array = []
	var first_mid_i: int = 1
	var last_mid_i: int = ordered_ids.size() - 2
	if last_mid_i - first_mid_i >= 2:
		pairs.append([first_mid_i, last_mid_i])
	for i in range(ordered_ids.size()):
		for j in range(i + 2, ordered_ids.size()):
			if i == first_mid_i and j == last_mid_i:
				continue
			pairs.append([i, j])

	for pair in pairs:
		var u: int = int(pair[0])
		var v: int = int(pair[1])
		var novel: int = 0
		for cell in _carve_l(ordered_centers[u], ordered_centers[v], bounds):
			if backbone_set.has(cell):
				continue
			if room_set.has(cell):
				continue
			novel += 1
		if novel >= 1:
			return [ordered_ids[u], ordered_ids[v]]

	return []

func _separated_from_all(cell: Vector2i, others: Array[Vector2i]) -> bool:
	for other in others:
		if _chebyshev(cell, other) < MIN_SEPARATION:
			return false
	return true

func _build_room_cells(center: Vector2i, bounds: Rect2i, radius: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var candidate: Vector2i = Vector2i(x, y)
			if bounds.has_point(candidate):
				cells.append(candidate)

	if cells.is_empty() and bounds.has_point(center):
		cells.append(center)

	return cells

func _build_room_region(room_id: String, role: String, center: Vector2i, cells: Array[Vector2i]) -> Dictionary:
	return {
		"roomId": room_id,
		"role": role,
		"center": {"x": center.x, "y": center.y},
		"cells": _points_to_dict_array(cells)
	}

func _carve_l(start_cell: Vector2i, exit_cell: Vector2i, bounds: Rect2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var current: Vector2i = start_cell
	while current.x != exit_cell.x:
		if bounds.has_point(current):
			cells.append(current)
		current.x += int(sign(exit_cell.x - current.x))
	while current.y != exit_cell.y:
		if bounds.has_point(current):
			cells.append(current)
		current.y += int(sign(exit_cell.y - current.y))
	if bounds.has_point(exit_cell):
		cells.append(exit_cell)
	return cells

func _shuffle_cells(cells: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(cells.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Vector2i = cells[i]
		cells[i] = cells[j]
		cells[j] = tmp

func _shuffle_ints(values: Array[int], rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = values[i]
		values[i] = values[j]
		values[j] = tmp

func _chebyshev(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))

func _points_to_dict_array(points: Array[Vector2i]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for point in points:
		result.append({"x": point.x, "y": point.y})
	return result

func _fail(error_code: String, message: String) -> Dictionary:
	var empty_cells: Array[Vector2i] = []
	var empty_regions: Array[Dictionary] = []
	return {
		"ok": false,
		"walkable_cells": empty_cells,
		"room_regions": empty_regions,
		"graph_edges": [],
		"error_code": error_code,
		"message": message
	}
