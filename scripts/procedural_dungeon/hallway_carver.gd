class_name HallwayCarver extends RefCounted

func carve_backbone_hallway(start_cell: Vector2i, exit_cell: Vector2i, generation_bounds: Rect2i) -> Dictionary:
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

func _points_to_dict_array(points: Array[Vector2i]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for point in points:
		result.append({"x": point.x, "y": point.y})
	return result
