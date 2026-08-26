class_name HallwayCarver extends RefCounted

func carve_backbone_hallway(start_cell: Vector2i, exit_cell: Vector2i, generation_bounds: Rect2i) -> Dictionary:
	var compact_cells: Array[Vector2i] = carve_l_cells(start_cell, exit_cell, generation_bounds)
	return {
		"ok": true,
		"hallway_cells": compact_cells,
		"hallway_regions": [
			{
				"hallwayId": "hallway_main",
				"cells": _points_to_dict_array(compact_cells)
			}
		]
	}

func carve_graph_hallways(rooms_by_id: Dictionary, graph_edges: Array, bounds: Rect2i) -> Dictionary:
	var unique_cells: Dictionary = {}
	for edge in graph_edges:
		if not (edge is Array) or edge.size() < 2:
			continue
		var from_id: String = str(edge[0])
		var to_id: String = str(edge[1])
		var from_center: Vector2i = _center_of(rooms_by_id, from_id)
		var to_center: Vector2i = _center_of(rooms_by_id, to_id)
		for cell in carve_l_cells(from_center, to_center, bounds):
			unique_cells[cell] = true

	var hallway_cells: Array[Vector2i] = []
	for cell in unique_cells.keys():
		hallway_cells.append(cell)

	return {
		"ok": true,
		"hallway_cells": hallway_cells
	}

func carve_l_cells(start_cell: Vector2i, exit_cell: Vector2i, generation_bounds: Rect2i) -> Array[Vector2i]:
	var hallway_cells: Array[Vector2i] = []
	var current: Vector2i = start_cell
	while current.x != exit_cell.x:
		if generation_bounds.has_point(current):
			hallway_cells.append(current)
		current.x += int(sign(exit_cell.x - current.x))

	while current.y != exit_cell.y:
		if generation_bounds.has_point(current):
			hallway_cells.append(current)
		current.y += int(sign(exit_cell.y - current.y))

	if generation_bounds.has_point(exit_cell):
		hallway_cells.append(exit_cell)

	var unique_cells: Dictionary = {}
	for cell in hallway_cells:
		unique_cells[cell] = true

	var compact_cells: Array[Vector2i] = []
	for cell in unique_cells.keys():
		compact_cells.append(cell)
	return compact_cells

func _center_of(rooms_by_id: Dictionary, room_id: String) -> Vector2i:
	if not rooms_by_id.has(room_id):
		return Vector2i.ZERO
	var entry: Variant = rooms_by_id[room_id]
	if entry is Vector2i:
		return entry
	if entry is Dictionary:
		var raw_center: Variant = entry.get("center", entry)
		if raw_center is Vector2i:
			return raw_center
		if raw_center is Dictionary:
			return Vector2i(int(raw_center.get("x", 0)), int(raw_center.get("y", 0)))
	return Vector2i.ZERO

func _points_to_dict_array(points: Array[Vector2i]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for point in points:
		result.append({"x": point.x, "y": point.y})
	return result
