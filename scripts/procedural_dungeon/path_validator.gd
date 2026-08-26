class_name PathValidator extends RefCounted

func has_connected_path(start_cell: Vector2i, exit_cell: Vector2i, walkable_cells: Array[Vector2i]) -> bool:
	return not build_shortest_path(start_cell, exit_cell, walkable_cells).is_empty()

func build_shortest_path(start_cell: Vector2i, exit_cell: Vector2i, walkable_cells: Array[Vector2i]) -> Array[Vector2i]:
	var walkable_set: Dictionary = {}
	for cell in walkable_cells:
		walkable_set[cell] = true

	if not walkable_set.has(start_cell) or not walkable_set.has(exit_cell):
		return []

	var queue: Array[Vector2i] = [start_cell]
	var visited: Dictionary = {start_cell: true}
	var parent: Dictionary = {}

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current == exit_cell:
			return _reconstruct_path(parent, start_cell, exit_cell)

		for neighbor in _neighbors(current):
			if not walkable_set.has(neighbor):
				continue
			if visited.has(neighbor):
				continue

			visited[neighbor] = true
			parent[neighbor] = current
			queue.append(neighbor)

	return []

func _neighbors(cell: Vector2i) -> Array[Vector2i]:
	return [
		cell + Vector2i(1, 0),
		cell + Vector2i(-1, 0),
		cell + Vector2i(0, 1),
		cell + Vector2i(0, -1)
	]

func _reconstruct_path(parent: Dictionary, start_cell: Vector2i, exit_cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var current: Vector2i = exit_cell
	result.append(current)

	while current != start_cell:
		if not parent.has(current):
			return []
		current = parent[current]
		result.append(current)

	result.reverse()
	return result
