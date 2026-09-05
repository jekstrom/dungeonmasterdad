class_name RoomGraphGenerator extends RefCounted

const ROOM_RADIUS: int = 2
const MIN_ROOM_CELLS: int = 9

func generate_room_backbone(
	start_cell: Vector2i,
	exit_cell: Vector2i,
	generation_bounds: Rect2i,
	generation_seed: int,
	room_radius: int = ROOM_RADIUS,
	requested_mid_count: int = -1
) -> Dictionary:
	var radius: int = ROOM_RADIUS if room_radius < 1 else room_radius
	var separation: int = (radius * 2) + 2
	if DungeonGrid.chebyshev(start_cell, exit_cell) < separation:
		return _fail("LAYOUT_INFEASIBLE", "Start and exit rooms violate center separation")

	var start_cells: Array[Vector2i] = _build_room_cells(start_cell, generation_bounds, radius)
	var exit_cells: Array[Vector2i] = _build_room_cells(exit_cell, generation_bounds, radius)
	if start_cells.size() < MIN_ROOM_CELLS or exit_cells.size() < MIN_ROOM_CELLS:
		return _fail("LAYOUT_INFEASIBLE", "Start or exit room too small after clip")

	var mid_count: int = requested_mid_count
	if mid_count < 1:
		var area: int = generation_bounds.size.x * generation_bounds.size.y
		mid_count = clampi(area / 180, 1, 3)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = generation_seed

	var anchors: Array[Vector2i] = [start_cell, exit_cell]
	var chosen: Array[Vector2i] = _scatter_mids(
		generation_bounds,
		anchors,
		mid_count,
		radius,
		separation,
		rng
	)
	if chosen.size() < mid_count:
		return _fail("LAYOUT_INFEASIBLE", "Unable to place required mid rooms")

	var ordered_ids: Array[String] = ["room_start"]
	var ordered_centers: Array[Vector2i] = [start_cell]
	var room_regions: Array[Dictionary] = [
		_build_room_region("room_start", "start", start_cell, start_cells)
	]
	for i in range(chosen.size()):
		var mid_id: String = "room_mid_%d" % (i + 1)
		var mid_center: Vector2i = chosen[i]
		var mid_cells: Array[Vector2i] = _build_room_cells(mid_center, generation_bounds, radius)
		ordered_ids.append(mid_id)
		ordered_centers.append(mid_center)
		room_regions.append(_build_room_region(mid_id, "mid", mid_center, mid_cells))
	ordered_ids.append("room_exit")
	ordered_centers.append(exit_cell)
	room_regions.append(_build_room_region("room_exit", "exit", exit_cell, exit_cells))

	var graph_edges: Array = _spanning_tree_edges(ordered_ids, ordered_centers)
	if ordered_ids.size() >= 3 and rng.randf() < 0.55:
		var extra: Array = _pick_extra_tree_edge(ordered_ids, graph_edges, rng)
		if extra.size() == 2:
			graph_edges.append(extra)

	var walkable_set: Dictionary = {}
	var walkable_cells: Array[Vector2i] = []
	for region in room_regions:
		for point in region.get("cells", []):
			var cell: Vector2i = DungeonGrid.cell_from(point)
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


func _scatter_mids(
	bounds: Rect2i,
	anchors: Array[Vector2i],
	mid_count: int,
	radius: int,
	separation: int,
	rng: RandomNumberGenerator
) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			var candidate: Vector2i = Vector2i(x, y)
			if not _separated_from_all(candidate, anchors, separation):
				continue
			if _build_room_cells(candidate, bounds, radius).size() < MIN_ROOM_CELLS:
				continue
			candidates.append(candidate)
	_shuffle_cells(candidates, rng)
	var placed: Array[Vector2i] = []
	for candidate in candidates:
		if placed.size() >= mid_count:
			break
		if not _separated_from_all(candidate, placed, separation):
			continue
		placed.append(candidate)
	return placed


func _spanning_tree_edges(ordered_ids: Array[String], ordered_centers: Array[Vector2i]) -> Array:
	var edges: Array = []
	if ordered_ids.size() < 2:
		return edges
	var in_tree: Dictionary = {0: true}
	while in_tree.size() < ordered_ids.size():
		var best_d: int = 1_000_000
		var best_u: int = -1
		var best_v: int = -1
		for u in in_tree.keys():
			for v in range(ordered_ids.size()):
				if in_tree.has(v):
					continue
				var d: int = DungeonGrid.chebyshev(ordered_centers[int(u)], ordered_centers[v])
				if d < best_d:
					best_d = d
					best_u = int(u)
					best_v = v
		if best_v < 0:
			break
		in_tree[best_v] = true
		edges.append([ordered_ids[best_u], ordered_ids[best_v]])
	return edges


func _pick_extra_tree_edge(
	ordered_ids: Array[String],
	graph_edges: Array,
	rng: RandomNumberGenerator
) -> Array:
	var connected: Dictionary = {}
	for edge in graph_edges:
		if not (edge is Array) or edge.size() < 2:
			continue
		connected["%s|%s" % [str(edge[0]), str(edge[1])]] = true
		connected["%s|%s" % [str(edge[1]), str(edge[0])]] = true
	var options: Array = []
	for i in range(ordered_ids.size()):
		for j in range(i + 1, ordered_ids.size()):
			if ordered_ids[i] == "room_start" and ordered_ids[j] == "room_exit":
				continue
			if ordered_ids[i] == "room_exit" and ordered_ids[j] == "room_start":
				continue
			var key: String = "%s|%s" % [ordered_ids[i], ordered_ids[j]]
			if connected.has(key):
				continue
			options.append([ordered_ids[i], ordered_ids[j]])
	if options.is_empty():
		return []
	return options[rng.randi_range(0, options.size() - 1)]


func _separated_from_all(cell: Vector2i, others: Array[Vector2i], separation: int) -> bool:
	for other in others:
		if DungeonGrid.chebyshev(cell, other) < separation:
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
		"cells": DungeonGrid.points_to_dicts(cells)
	}

func _shuffle_cells(cells: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(cells.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Vector2i = cells[i]
		cells[i] = cells[j]
		cells[j] = tmp

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
