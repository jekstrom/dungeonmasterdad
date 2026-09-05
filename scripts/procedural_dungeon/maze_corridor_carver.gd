class_name MazeCorridorCarver extends RefCounted


func carve_between(
	from_cell: Vector2i,
	to_cell: Vector2i,
	bounds: Rect2i,
	blocked: Dictionary,
	rng: RandomNumberGenerator
) -> Array[Vector2i]:
	var points: Array[Vector2i] = [from_cell]
	var wp_count: int = 2 if rng.randf() < 0.55 else 1
	for i in range(wp_count):
		var waypoint: Vector2i = _offset_waypoint(from_cell, to_cell, bounds, rng, i)
		if waypoint == from_cell or waypoint == to_cell:
			continue
		if blocked.has(waypoint):
			continue
		if not bounds.has_point(waypoint):
			continue
		points.append(waypoint)
	points.append(to_cell)
	var path: Array[Vector2i] = []
	var seen: Dictionary = {}
	var cursor: Vector2i = from_cell
	for i in range(1, points.size()):
		var part: Array[Vector2i] = _bfs_path(cursor, points[i], bounds, blocked)
		if part.is_empty():
			continue
		for cell in part:
			_append(path, seen, cell)
		cursor = points[i]
	if not seen.has(to_cell):
		var fallback: Array[Vector2i] = _bfs_path(
			from_cell if path.is_empty() else path[path.size() - 1],
			to_cell,
			bounds,
			blocked
		)
		for cell in fallback:
			_append(path, seen, cell)
	return path


func braid(
	walkable: Dictionary,
	room_set: Dictionary,
	bounds: Rect2i,
	rng: RandomNumberGenerator,
	braid_rate: float
) -> Array[Vector2i]:
	var added: Array[Vector2i] = []
	if braid_rate <= 0.0:
		return added
	var dead_ends: Array[Vector2i] = []
	for cell in walkable.keys():
		if room_set.has(cell):
			continue
		if _walkable_degree(cell, walkable) != 1:
			continue
		dead_ends.append(cell)
	if dead_ends.is_empty():
		return added
	var want: int = maxi(1, int(round(float(dead_ends.size()) * clampf(braid_rate, 0.0, 1.0))))
	_shuffle(dead_ends, rng)
	for cell in dead_ends:
		if added.size() >= want:
			break
		var options: Array[Vector2i] = []
		for neighbor in DungeonGrid.neighbors(cell):
			if not bounds.has_point(neighbor):
				continue
			if walkable.has(neighbor) or room_set.has(neighbor):
				continue
			if _touches_room(neighbor, room_set):
				continue
			if _touches_walkable(neighbor, walkable, cell):
				options.append(neighbor)
		if options.is_empty():
			continue
		var pick: Vector2i = options[rng.randi_range(0, options.size() - 1)]
		walkable[pick] = true
		added.append(pick)
	return added


func grow_maze(
	walkable: Dictionary,
	room_set: Dictionary,
	target: Rect2i,
	rng: RandomNumberGenerator,
	max_new: int
) -> Array[Vector2i]:
	var added: Array[Vector2i] = []
	if max_new <= 0 or target.size.x <= 0 or target.size.y <= 0:
		return added
	var frontier: Array[Vector2i] = []
	for cell in walkable.keys():
		if room_set.has(cell):
			continue
		if _has_empty_neighbor(cell, walkable, room_set, target):
			frontier.append(cell)
	_shuffle(frontier, rng)
	var guard: int = 0
	var guard_limit: int = maxi(4096, max_new * 4)
	while not frontier.is_empty() and added.size() < max_new and guard < guard_limit:
		guard += 1
		var pick_i: int = frontier.size() - 1
		if rng.randf() < 0.12:
			pick_i = rng.randi_range(0, frontier.size() - 1)
		var cell: Vector2i = frontier[pick_i]
		var options: Array[Vector2i] = _maze_options(cell, walkable, room_set, target)
		if options.is_empty():
			frontier.remove_at(pick_i)
			continue
		var nxt: Vector2i = options[rng.randi_range(0, options.size() - 1)]
		walkable[nxt] = true
		added.append(nxt)
		frontier.append(nxt)
	return added


func _offset_waypoint(
	from_cell: Vector2i,
	to_cell: Vector2i,
	bounds: Rect2i,
	rng: RandomNumberGenerator,
	index: int
) -> Vector2i:
	var t: float = 0.3 + 0.35 * float(index)
	var along: Vector2i = Vector2i(
		from_cell.x + int(round(float(to_cell.x - from_cell.x) * t)),
		from_cell.y + int(round(float(to_cell.y - from_cell.y) * t))
	)
	var horiz: bool = absi(to_cell.x - from_cell.x) >= absi(to_cell.y - from_cell.y)
	var sign: int = -1 if rng.randf() < 0.5 else 1
	if index == 1:
		sign *= -1
	var span: int = mini(bounds.size.x, bounds.size.y)
	var dist: int = rng.randi_range(3, maxi(3, mini(7, span / 3)))
	var waypoint: Vector2i = along
	if horiz:
		waypoint.y += sign * dist
	else:
		waypoint.x += sign * dist
	waypoint.x = clampi(waypoint.x, bounds.position.x, bounds.end.x - 1)
	waypoint.y = clampi(waypoint.y, bounds.position.y, bounds.end.y - 1)
	return waypoint


func _bfs_path(
	from_cell: Vector2i,
	to_cell: Vector2i,
	bounds: Rect2i,
	blocked: Dictionary
) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	if from_cell == to_cell:
		return [from_cell]
	if not bounds.has_point(from_cell) or not bounds.has_point(to_cell):
		return empty
	var queue: Array[Vector2i] = [from_cell]
	var visited: Dictionary = {from_cell: true}
	var parent: Dictionary = {}
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current == to_cell:
			return _reconstruct(parent, from_cell, to_cell)
		for neighbor in DungeonGrid.neighbors(current):
			if not bounds.has_point(neighbor):
				continue
			if blocked.has(neighbor) and neighbor != to_cell:
				continue
			if visited.has(neighbor):
				continue
			visited[neighbor] = true
			parent[neighbor] = current
			queue.append(neighbor)
	return empty


func _reconstruct(parent: Dictionary, from_cell: Vector2i, to_cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var current: Vector2i = to_cell
	result.append(current)
	while current != from_cell:
		if not parent.has(current):
			var empty: Array[Vector2i] = []
			return empty
		current = parent[current]
		result.append(current)
	result.reverse()
	return result


func _touches_room(cell: Vector2i, room_set: Dictionary) -> bool:
	for neighbor in DungeonGrid.neighbors(cell):
		if room_set.has(neighbor):
			return true
	return false


func _walkable_degree(cell: Vector2i, walkable: Dictionary) -> int:
	var degree: int = 0
	for neighbor in DungeonGrid.neighbors(cell):
		if walkable.has(neighbor):
			degree += 1
	return degree


func _touches_walkable(cell: Vector2i, walkable: Dictionary, skip: Vector2i) -> bool:
	for neighbor in DungeonGrid.neighbors(cell):
		if neighbor == skip:
			continue
		if walkable.has(neighbor):
			return true
	return false


func _has_empty_neighbor(cell: Vector2i, walkable: Dictionary, room_set: Dictionary, target: Rect2i) -> bool:
	for neighbor in DungeonGrid.neighbors(cell):
		if not target.has_point(neighbor):
			continue
		if walkable.has(neighbor) or room_set.has(neighbor):
			continue
		return true
	return false


func _maze_options(cell: Vector2i, walkable: Dictionary, room_set: Dictionary, target: Rect2i) -> Array[Vector2i]:
	var options: Array[Vector2i] = []
	for neighbor in DungeonGrid.neighbors(cell):
		if not target.has_point(neighbor):
			continue
		if walkable.has(neighbor) or room_set.has(neighbor):
			continue
		if _touches_room(neighbor, room_set):
			continue
		var carved_n: int = 0
		for n2 in DungeonGrid.neighbors(neighbor):
			if walkable.has(n2) or room_set.has(n2):
				carved_n += 1
		if carved_n <= 1:
			options.append(neighbor)
	return options


func _append(path: Array[Vector2i], seen: Dictionary, cell: Vector2i) -> void:
	if seen.has(cell):
		return
	seen[cell] = true
	path.append(cell)


func _shuffle(cells: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(cells.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Vector2i = cells[i]
		cells[i] = cells[j]
		cells[j] = tmp
