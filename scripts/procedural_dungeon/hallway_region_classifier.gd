class_name HallwayRegionClassifier extends RefCounted

func classify_hallway_regions(all_walkable_cells: Array[Vector2i], room_cells: Array[Vector2i]) -> Array[Dictionary]:
	var walkable_set: Dictionary = {}
	for cell in all_walkable_cells:
		walkable_set[cell] = true

	var room_set: Dictionary = {}
	for cell in room_cells:
		room_set[cell] = true

	var hallway_set: Dictionary = {}
	for cell in walkable_set.keys():
		if not room_set.has(cell):
			hallway_set[cell] = true

	var regions: Array[Dictionary] = []
	var visited: Dictionary = {}
	var region_index: int = 0

	for start_cell in hallway_set.keys():
		if visited.has(start_cell):
			continue

		var component: Array[Vector2i] = _flood_fill_component(start_cell, hallway_set, visited)
		if component.is_empty():
			continue

		regions.append({
			"hallwayId": "hallway_%d" % region_index,
			"cells": _points_to_dict_array(component)
		})
		region_index += 1

	return regions

func _flood_fill_component(start: Vector2i, cell_set: Dictionary, visited: Dictionary) -> Array[Vector2i]:
	var queue: Array[Vector2i] = [start]
	visited[start] = true
	var component: Array[Vector2i] = []

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		component.append(current)

		for neighbor in _neighbors(current):
			if not cell_set.has(neighbor):
				continue
			if visited.has(neighbor):
				continue
			visited[neighbor] = true
			queue.append(neighbor)

	return component

func _neighbors(cell: Vector2i) -> Array[Vector2i]:
	return [
		cell + Vector2i(1, 0),
		cell + Vector2i(-1, 0),
		cell + Vector2i(0, 1),
		cell + Vector2i(0, -1)
	]

func _points_to_dict_array(points: Array[Vector2i]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for point in points:
		result.append({"x": point.x, "y": point.y})
	return result
