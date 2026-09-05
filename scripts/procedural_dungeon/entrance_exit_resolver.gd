class_name EntranceExitResolver extends RefCounted

func resolve_positions(
	start_position: Vector2i,
	exit_position: Vector2i,
	generation_bounds: Rect2i,
	generation_seed: int = 1,
	room_radius: int = 2,
	auto_place: bool = false
) -> Dictionary:
	if auto_place or start_position == DungeonGrid.SENTINEL or exit_position == DungeonGrid.SENTINEL:
		return _auto_place(generation_bounds, generation_seed, room_radius)
	if start_position == exit_position:
		return DungeonGrid.fail("START_EQUALS_EXIT", "Start and exit positions must be different")
	if not generation_bounds.has_point(start_position) or not generation_bounds.has_point(exit_position):
		return DungeonGrid.fail("POSITION_OUT_OF_BOUNDS", "Start and exit positions must be inside generation bounds")
	return {
		"ok": true,
		"entrance_cell": start_position,
		"exit_cell": exit_position
	}


func _auto_place(bounds: Rect2i, generation_seed: int, room_radius: int) -> Dictionary:
	var radius: int = maxi(1, room_radius)
	var room_sep: int = (radius * 2) + 2
	var min_sep: int = maxi(room_sep * 2, int(float(mini(bounds.size.x, bounds.size.y)) * DungeonConstants.AUTO_PORTAL_MIN_SPAN))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = generation_seed
	var legal: Array[Vector2i] = []
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			var cell: Vector2i = Vector2i(x, y)
			if _room_cell_count(cell, bounds, radius) < DungeonConstants.MIN_ROOM_CELLS:
				continue
			legal.append(cell)
	if legal.size() < 2:
		return DungeonGrid.fail("LAYOUT_INFEASIBLE", "Not enough cells to auto-place entrance and exit")
	var exits: Array[Vector2i] = _west_edge_centers(legal, bounds, radius)
	if exits.is_empty():
		exits = _perimeter_centers(legal, bounds, radius)
	_shuffle(exits, rng)
	var starts: Array[Vector2i] = legal.duplicate()
	_shuffle(starts, rng)
	for exit_cell in exits:
		var far: Array[Vector2i] = []
		var any_ok: Array[Vector2i] = []
		for start_cell in starts:
			if start_cell == exit_cell:
				continue
			var dist: int = DungeonGrid.chebyshev(start_cell, exit_cell)
			if dist < room_sep:
				continue
			any_ok.append(start_cell)
			if dist >= min_sep and start_cell.x > exit_cell.x:
				far.append(start_cell)
		var pool: Array[Vector2i] = far
		if pool.is_empty():
			pool = any_ok
		if pool.is_empty():
			continue
		return {
			"ok": true,
			"entrance_cell": pool[rng.randi_range(0, pool.size() - 1)],
			"exit_cell": exit_cell
		}
	return DungeonGrid.fail("LAYOUT_INFEASIBLE", "Unable to auto-place distinct entrance and exit")


func _west_edge_centers(legal: Array[Vector2i], bounds: Rect2i, radius: int) -> Array[Vector2i]:
	var west_x: int = bounds.position.x + radius
	var result: Array[Vector2i] = []
	for cell in legal:
		if cell.x == west_x:
			result.append(cell)
	if not result.is_empty():
		return result
	for cell in legal:
		if cell.x <= bounds.position.x + radius:
			result.append(cell)
	return result


func _perimeter_centers(legal: Array[Vector2i], bounds: Rect2i, radius: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell in legal:
		if _on_overworld_edge(cell, bounds, radius):
			result.append(cell)
	return result


func _on_overworld_edge(cell: Vector2i, bounds: Rect2i, radius: int) -> bool:
	if cell.x <= bounds.position.x + radius:
		return true
	if cell.y <= bounds.position.y + radius:
		return true
	if cell.y >= bounds.end.y - radius - 1:
		return true
	return false


func _room_cell_count(center: Vector2i, bounds: Rect2i, radius: int) -> int:
	var count: int = 0
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if bounds.has_point(Vector2i(x, y)):
				count += 1
	return count


func _shuffle(cells: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(cells.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Vector2i = cells[i]
		cells[i] = cells[j]
		cells[j] = tmp
