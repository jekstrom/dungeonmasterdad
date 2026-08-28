class_name DungeonGrid extends RefCounted

const CELL_PX := 128.0
const SENTINEL := Vector2i(2147483647, 2147483647)

static func cardinals() -> Array[Vector2i]:
	return [
		Vector2i.RIGHT,
		Vector2i.LEFT,
		Vector2i.DOWN,
		Vector2i.UP,
	]


static func neighbors(cell: Vector2i) -> Array[Vector2i]:
	return [
		cell + Vector2i.RIGHT,
		cell + Vector2i.LEFT,
		cell + Vector2i.DOWN,
		cell + Vector2i.UP,
	]


static func cell_from(raw_value: Variant) -> Vector2i:
	if raw_value is Vector2i:
		return raw_value
	if raw_value is Vector2:
		return Vector2i(raw_value)
	if raw_value is Dictionary:
		return Vector2i(int(raw_value.get("x", 0)), int(raw_value.get("y", 0)))
	return Vector2i.ZERO


static func cells_from(raw_value: Variant) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if raw_value is Array:
		for item in raw_value:
			if item is Vector2i:
				result.append(item)
	return result


static func dicts_from(raw_value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if raw_value is Array:
		for item in raw_value:
			if item is Dictionary:
				result.append(item)
	return result


static func points_to_dicts(points: Array[Vector2i]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for point in points:
		result.append({"x": point.x, "y": point.y})
	return result


static func chebyshev(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


static func to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL_PX


static func from_world(world: Vector2) -> Vector2i:
	return Vector2i(int(floor(world.x / CELL_PX)), int(floor(world.y / CELL_PX)))


static func to_world_from_dict(point: Dictionary) -> Vector2:
	return to_world(cell_from(point))


static func set_from(cells: Array[Vector2i]) -> Dictionary:
	var result: Dictionary = {}
	for cell in cells:
		result[cell] = true
	return result


static func blocked_cells(bounds: Rect2i, walkable_set: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			var candidate := Vector2i(x, y)
			if not walkable_set.has(candidate):
				result.append(candidate)
	return result


static func carve_l(start_cell: Vector2i, exit_cell: Vector2i, bounds: Rect2i) -> Array[Vector2i]:
	var seen: Dictionary = {}
	var cells: Array[Vector2i] = []
	var current := start_cell
	while current.x != exit_cell.x:
		_append_unique(cells, seen, current, bounds)
		current.x += int(sign(exit_cell.x - current.x))
	while current.y != exit_cell.y:
		_append_unique(cells, seen, current, bounds)
		current.y += int(sign(exit_cell.y - current.y))
	_append_unique(cells, seen, exit_cell, bounds)
	return cells


static func flood_fill(start: Vector2i, cell_set: Dictionary, visited: Dictionary) -> Array[Vector2i]:
	var queue: Array[Vector2i] = [start]
	visited[start] = true
	var component: Array[Vector2i] = []
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		component.append(current)
		for neighbor in neighbors(current):
			if not cell_set.has(neighbor) or visited.has(neighbor):
				continue
			visited[neighbor] = true
			queue.append(neighbor)
	return component


static func fail(error_code: String, message: String) -> Dictionary:
	return {
		"ok": false,
		"error_code": error_code,
		"message": message
	}


static func _append_unique(
	cells: Array[Vector2i],
	seen: Dictionary,
	cell: Vector2i,
	bounds: Rect2i
) -> void:
	if not bounds.has_point(cell) or seen.has(cell):
		return
	seen[cell] = true
	cells.append(cell)
