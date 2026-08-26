class_name RoomGraphGenerator extends RefCounted

func generate_room_backbone(start_cell: Vector2i, exit_cell: Vector2i, generation_bounds: Rect2i) -> Dictionary:
	var start_room_cells: Array[Vector2i] = _build_room_cells(start_cell, generation_bounds, 2)
	var exit_room_cells: Array[Vector2i] = _build_room_cells(exit_cell, generation_bounds, 2)

	var unique_cells: Dictionary = {}
	for cell in start_room_cells:
		unique_cells[cell] = true
	for cell in exit_room_cells:
		unique_cells[cell] = true

	var walkable_cells: Array[Vector2i] = []
	for cell in unique_cells.keys():
		walkable_cells.append(cell)

	return {
		"ok": true,
		"walkable_cells": walkable_cells,
		"room_regions": [
			_build_room_region("room_start", start_room_cells),
			_build_room_region("room_exit", exit_room_cells)
		],
		"graph_edges": [["room_start", "room_exit"]]
	}

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

func _build_room_region(room_id: String, cells: Array[Vector2i]) -> Dictionary:
	return {
		"roomId": room_id,
		"cells": _points_to_dict_array(cells)
	}

func _points_to_dict_array(points: Array[Vector2i]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for point in points:
		result.append({"x": point.x, "y": point.y})
	return result
