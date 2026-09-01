class_name MapBounds extends RefCounted

var interior: Rect2i = Rect2i()

func has_committed_bounds() -> bool:
	return interior.size.x > 0 and interior.size.y > 0

func commit_interior(rect: Rect2i) -> void:
	if rect.size.x <= 0 or rect.size.y <= 0:
		interior = Rect2i()
		return
	interior = rect

func clear() -> void:
	interior = Rect2i()

func get_interior() -> Rect2i:
	return interior

func outer_rect() -> Rect2i:
	if not has_committed_bounds():
		return Rect2i()
	return Rect2i(interior.position - Vector2i.ONE, interior.size + Vector2i(2, 2))

func is_interior_cell(cell: Vector2i) -> bool:
	if not has_committed_bounds():
		return false
	return interior.has_point(cell)

func is_cliff_cell(cell: Vector2i) -> bool:
	if not has_committed_bounds():
		return false
	return outer_rect().has_point(cell) and not interior.has_point(cell)

func is_world_position_in_interior(world: Vector2) -> bool:
	return is_interior_cell(DungeonGrid.from_world(world))

func is_world_position_on_cliff(world: Vector2) -> bool:
	return is_cliff_cell(DungeonGrid.from_world(world))

func walk_world_rect() -> Rect2:
	if not has_committed_bounds():
		return Rect2()
	var origin: Vector2 = DungeonGrid.to_world(interior.position)
	var end_p: Vector2 = DungeonGrid.to_world(interior.end)
	var margin: float = DungeonGrid.CLIFF_GRASS_MARGIN
	var min_p := Vector2(
		origin.x - DungeonGrid.SPRITE_HALF_X - margin,
		origin.y - DungeonGrid.SPRITE_TOP - margin
	)
	var max_p := Vector2(
		end_p.x - DungeonGrid.SPRITE_HALF_X + margin,
		end_p.y - DungeonGrid.SPRITE_TOP + margin
	)
	return Rect2(min_p, max_p - min_p)

func is_world_position_walkable(world: Vector2) -> bool:
	if not has_committed_bounds():
		return false
	return walk_world_rect().grow(0.001).has_point(world)

func clamp_world_to_interior(world: Vector2) -> Vector2:
	if not has_committed_bounds():
		return world
	var rect: Rect2 = walk_world_rect()
	var max_p: Vector2 = rect.position + rect.size - Vector2(0.001, 0.001)
	return world.clamp(rect.position, max_p)

func cliff_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if not has_committed_bounds():
		return cells
	var outer: Rect2i = outer_rect()
	for y in range(outer.position.y, outer.end.y):
		for x in range(outer.position.x, outer.end.x):
			var cell := Vector2i(x, y)
			if interior.has_point(cell):
				continue
			cells.append(cell)
	return cells

func interior_cell_count() -> int:
	if not has_committed_bounds():
		return 0
	return interior.size.x * interior.size.y

func intersect_interior(rect: Rect2i) -> Rect2i:
	if not has_committed_bounds():
		return Rect2i()
	if rect.size.x <= 0 or rect.size.y <= 0:
		return Rect2i()
	var clipped: Rect2i = interior.intersection(rect)
	if clipped.size.x <= 0 or clipped.size.y <= 0:
		return Rect2i()
	return clipped

func interior_world_rect() -> Rect2:
	if not has_committed_bounds():
		return Rect2()
	return Rect2(DungeonGrid.to_world(interior.position), Vector2(interior.size) * DungeonGrid.CELL_PX)

static func interior_from_dungeon_aabb(dungeon: Rect2i) -> Rect2i:
	var wd: int = dungeon.size.x
	var hd: int = dungeon.size.y
	if wd <= 0 or hd <= 0:
		return Rect2i()
	var wi: int = wd * 2
	var hi: int = hd * 2
	if hi < hd + 2:
		hi = hd + 2
	if wi < wd:
		wi = wd
	var dungeon_area: int = wd * hd
	while wi * hi < 4 * dungeon_area:
		wi += 1
	# Square play area: grow height to match width (letterbox N/S pads).
	# Prefer fill-width geometry; never shrink below the area/pad floors above.
	if hi < wi:
		hi = wi
	var north_pad: int = int((hi - hd) / 2)
	var origin := Vector2i(dungeon.end.x - wi, dungeon.position.y - north_pad)
	return Rect2i(origin, Vector2i(wi, hi))

func tree_scatter_candidate_cells(dungeon: Rect2i = Rect2i()) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if not has_committed_bounds():
		return cells
	var west: Dictionary = {}
	for cell in west_spawn_strip_cells(dungeon):
		west[cell] = true
	for y in range(interior.position.y, interior.end.y):
		for x in range(interior.position.x, interior.end.x):
			var cell := Vector2i(x, y)
			if is_cliff_cell(cell):
				continue
			if dungeon.size.x > 0 and dungeon.size.y > 0 and dungeon.has_point(cell):
				continue
			if west.has(cell):
				continue
			cells.append(cell)
	return cells

func west_spawn_strip_cells(dungeon: Rect2i = Rect2i()) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if not has_committed_bounds():
		return cells
	var x: int = interior.position.x
	for y in range(interior.position.y, interior.end.y):
		var cell := Vector2i(x, y)
		if dungeon.size.x > 0 and dungeon.size.y > 0 and dungeon.has_point(cell):
			continue
		cells.append(cell)
	return cells

func west_spawn_world(index: int, dungeon: Rect2i = Rect2i()) -> Vector2:
	var cells: Array[Vector2i] = west_spawn_strip_cells(dungeon)
	if cells.is_empty():
		return clamp_world_to_interior(Vector2(DungeonGrid.CELL_PX * 0.5, DungeonGrid.CELL_PX * 0.5))
	var cell: Vector2i = cells[posmod(index, cells.size())]
	return DungeonGrid.to_world(cell) + Vector2(DungeonGrid.CELL_PX * 0.5, DungeonGrid.CELL_PX * 0.5)

static func cell_translation_for_east_flush(dungeon: Rect2i) -> Vector2i:
	var planned: Rect2i = interior_from_dungeon_aabb(dungeon)
	if planned.size.x <= 0 or planned.size.y <= 0:
		return Vector2i.ZERO
	return -planned.position
