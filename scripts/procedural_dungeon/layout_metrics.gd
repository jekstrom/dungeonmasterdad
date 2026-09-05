class_name LayoutMetrics extends RefCounted


static func walkable_aabb(cells: Array[Vector2i]) -> Rect2i:
	if cells.is_empty():
		return Rect2i()
	var min_x: int = cells[0].x
	var min_y: int = cells[0].y
	var max_x: int = cells[0].x
	var max_y: int = cells[0].y
	for cell in cells:
		min_x = mini(min_x, cell.x)
		min_y = mini(min_y, cell.y)
		max_x = maxi(max_x, cell.x)
		max_y = maxi(max_y, cell.y)
	return Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1))


static func aspect_ratio(rect: Rect2i) -> float:
	var w: int = maxi(1, rect.size.x)
	var h: int = maxi(1, rect.size.y)
	return float(maxi(w, h)) / float(mini(w, h))


static func bounds_are_compact(bounds: Rect2i) -> bool:
	return aspect_ratio(bounds) <= DungeonConstants.COMPACT_BOUNDS_ASPECT


static func winding_ratio(path_length: int, start_cell: Vector2i, exit_cell: Vector2i) -> float:
	var cheb: int = maxi(1, DungeonGrid.chebyshev(start_cell, exit_cell))
	return float(path_length) / float(cheb)


static func l_cell_set(centers: Array[Vector2i], bounds: Rect2i) -> Dictionary:
	var result: Dictionary = {}
	for i in range(centers.size()):
		for j in range(i + 1, centers.size()):
			for cell in DungeonGrid.carve_l(centers[i], centers[j], bounds):
				result[cell] = true
	return result


static func expand_compact_rect(aabb: Rect2i, bounds: Rect2i, max_aspect: float) -> Rect2i:
	var rect: Rect2i = _clip_to_bounds(aabb.grow(1), bounds)
	var guard: int = 0
	while aspect_ratio(rect) > max_aspect and guard < 256:
		guard += 1
		var grown: Rect2i = rect
		if rect.size.x > rect.size.y:
			grown = _grow_rect_y(rect, bounds)
		else:
			grown = _grow_rect_x(rect, bounds)
		if grown == rect:
			break
		rect = _clip_to_bounds(grown, bounds)
	return rect


static func grow_for_infill(aabb: Rect2i, bounds: Rect2i, extra_steps: int, max_aspect: float) -> Rect2i:
	var rect: Rect2i = expand_compact_rect(aabb, bounds, max_aspect)
	for _step in range(maxi(0, extra_steps)):
		var grown: Rect2i = _clip_to_bounds(rect.grow(1), bounds)
		if grown == rect:
			break
		if aspect_ratio(grown) > max_aspect:
			grown = expand_compact_rect(grown, bounds, max_aspect)
		rect = grown
	return rect


static func passes(
	request: DungeonGenerationRequest,
	walkable_cells: Array[Vector2i],
	entrance_cell: Vector2i,
	exit_cell: Vector2i,
	path_length: int
) -> bool:
	if walkable_cells.is_empty() or path_length < 2:
		return false
	if winding_ratio(path_length, entrance_cell, exit_cell) < DungeonConstants.MIN_WINDING_RATIO:
		return false
	if bounds_are_compact(request.generation_bounds):
		if aspect_ratio(walkable_aabb(walkable_cells)) > DungeonConstants.MAX_WALKABLE_ASPECT:
			return false
	return true


static func _clip_to_bounds(rect: Rect2i, bounds: Rect2i) -> Rect2i:
	var pos: Vector2i = Vector2i(
		clampi(rect.position.x, bounds.position.x, bounds.end.x - 1),
		clampi(rect.position.y, bounds.position.y, bounds.end.y - 1)
	)
	var end_p: Vector2i = Vector2i(
		clampi(rect.end.x, bounds.position.x + 1, bounds.end.x),
		clampi(rect.end.y, bounds.position.y + 1, bounds.end.y)
	)
	return Rect2i(pos, end_p - pos)


static func _grow_rect_y(rect: Rect2i, bounds: Rect2i) -> Rect2i:
	if rect.position.y > bounds.position.y:
		return Rect2i(rect.position + Vector2i(0, -1), rect.size + Vector2i(0, 1))
	if rect.end.y < bounds.end.y:
		return Rect2i(rect.position, rect.size + Vector2i(0, 1))
	return rect


static func _grow_rect_x(rect: Rect2i, bounds: Rect2i) -> Rect2i:
	if rect.position.x > bounds.position.x:
		return Rect2i(rect.position + Vector2i(-1, 0), rect.size + Vector2i(1, 0))
	if rect.end.x < bounds.end.x:
		return Rect2i(rect.position, rect.size + Vector2i(1, 0))
	return rect
