class_name RoomRegionClassifier extends RefCounted

func classify_room_regions(room_seed_cells: Array[Vector2i]) -> Array[Dictionary]:
	var seed_set: Dictionary = {}
	for cell in room_seed_cells:
		seed_set[cell] = true

	var regions: Array[Dictionary] = []
	var visited: Dictionary = {}
	var region_index: int = 0

	for seed in seed_set.keys():
		if visited.has(seed):
			continue

		var component: Array[Vector2i] = _flood_fill_component(seed, seed_set, visited)
		if component.is_empty():
			continue

		regions.append({
			"roomId": "room_%d" % region_index,
			"cells": _points_to_dict_array(component)
		})
		region_index += 1

	return regions

func _flood_fill_component(start: Vector2i, seed_set: Dictionary, visited: Dictionary) -> Array[Vector2i]:
	var queue: Array[Vector2i] = [start]
	visited[start] = true
	var component: Array[Vector2i] = []

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		component.append(current)

		for neighbor in _neighbors(current):
			if not seed_set.has(neighbor):
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
