class_name PathValidator extends RefCounted

const DungeonGrid = preload("res://scripts/procedural_dungeon/dungeon_grid.gd")

func has_connected_path(start_cell: Vector2i, exit_cell: Vector2i, walkable_cells: Array[Vector2i]) -> bool:
	return not build_shortest_path(start_cell, exit_cell, walkable_cells).is_empty()


func build_shortest_path(start_cell: Vector2i, exit_cell: Vector2i, walkable_cells: Array[Vector2i]) -> Array[Vector2i]:
	var walkable_set: Dictionary = DungeonGrid.set_from(walkable_cells)
	if not walkable_set.has(start_cell) or not walkable_set.has(exit_cell):
		return []

	var queue: Array[Vector2i] = [start_cell]
	var visited: Dictionary = {start_cell: true}
	var parent: Dictionary = {}
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current == exit_cell:
			return _reconstruct_path(parent, start_cell, exit_cell)
		for neighbor in DungeonGrid.neighbors(current):
			if not walkable_set.has(neighbor) or visited.has(neighbor):
				continue
			visited[neighbor] = true
			parent[neighbor] = current
			queue.append(neighbor)
	return []


func build_shortest_path_set(start_cell: Vector2i, exit_cell: Vector2i, walkable_cells: Array[Vector2i]) -> Dictionary:
	return DungeonGrid.set_from(build_shortest_path(start_cell, exit_cell, walkable_cells))


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
