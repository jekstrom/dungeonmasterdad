class_name TilePlacementBuilder extends RefCounted

const DungeonGrid = preload("res://scripts/procedural_dungeon/dungeon_grid.gd")
const WallAutotile = preload("res://scripts/procedural_dungeon/wall_autotile.gd")
const TileCatalog = preload("res://scripts/procedural_dungeon/tile_catalog.gd")
const DungeonLayoutData = preload("res://scripts/procedural_dungeon/resources/dungeon_layout_data.gd")

var _tile_catalog: TileCatalog = TileCatalog.new()

func build(layout_data: DungeonLayoutData, walkable_set: Dictionary) -> Array[Dictionary]:
	var placements: Array[Dictionary] = []
	var room_set: Dictionary = {}
	for region in layout_data.room_regions:
		for point in region.get("cells", []):
			room_set[DungeonGrid.cell_from(point)] = true

	for cell in layout_data.walkable_cells:
		placements.append(_floor_placement(cell, room_set, layout_data))

	var wall_set: Dictionary = _enclosed_wall_set(walkable_set)
	var door: Vector2i = _pick_exit_door(layout_data, wall_set)
	if door != DungeonGrid.SENTINEL:
		wall_set.erase(door)
		if not walkable_set.has(door):
			placements.append(_floor_placement(door, room_set, layout_data))

	for cell in wall_set:
		placements.append({
			"position": {"x": cell.x, "y": cell.y},
			"tileRole": "wall",
			"tileSourcePath": _tile_catalog.get_wall_scene_path(),
			"variantId": WallAutotile.wall_type(cell, walkable_set),
			"wallFrame": WallAutotile.wall_frame(cell, walkable_set, wall_set)
		})
	return placements


func _floor_placement(
	cell: Vector2i,
	room_set: Dictionary,
	layout_data: DungeonLayoutData
) -> Dictionary:
	var role := "floor"
	var variant_id := 1
	if room_set.has(cell):
		variant_id = 0
	if cell == layout_data.entrance_cell:
		role = "entrance"
		variant_id = 0
	elif cell == layout_data.exit_cell:
		role = "exit"
		variant_id = 0
	return {
		"position": {"x": cell.x, "y": cell.y},
		"tileRole": role,
		"tileSourcePath": _tile_catalog.get_floor_scene_path(),
		"variantId": variant_id
	}


func _enclosed_wall_set(walkable_set: Dictionary) -> Dictionary:
	# One-cell shell around every walkable cell, including outside generation
	# bounds so rooms that sit on the grid edge still get walls.
	var wall_set: Dictionary = {}
	for cell in walkable_set:
		for neighbor in DungeonGrid.neighbors(cell):
			if not walkable_set.has(neighbor):
				wall_set[neighbor] = true
	var corner_candidates: Dictionary = {}
	var diagonals: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(1, 1)
	]
	for cell in walkable_set:
		for offset in diagonals:
			var candidate: Vector2i = cell + offset
			if walkable_set.has(candidate) or wall_set.has(candidate):
				continue
			corner_candidates[candidate] = true
	for cell in corner_candidates:
		if _is_shell_corner_cell(cell, walkable_set, wall_set):
			wall_set[cell] = true
	return wall_set


func _pick_exit_door(layout_data: DungeonLayoutData, wall_set: Dictionary) -> Vector2i:
	var exit_cells: Dictionary = {}
	for region in layout_data.room_regions:
		if str(region.get("role", "")) != "exit":
			continue
		for point in region.get("cells", []):
			exit_cells[DungeonGrid.cell_from(point)] = true
	if exit_cells.is_empty():
		return DungeonGrid.SENTINEL

	var dirs: Array[Vector2i] = []
	var dx: int = layout_data.exit_cell.x - layout_data.entrance_cell.x
	var dy: int = layout_data.exit_cell.y - layout_data.entrance_cell.y
	if dx != 0:
		dirs.append(Vector2i.RIGHT if dx > 0 else Vector2i.LEFT)
	if dy != 0:
		dirs.append(Vector2i.DOWN if dy > 0 else Vector2i.UP)
	for cardinal in DungeonGrid.cardinals():
		if not dirs.has(cardinal):
			dirs.append(cardinal)
	for dir in dirs:
		var door: Vector2i = _middle_face_wall(exit_cells, dir, wall_set)
		if door != DungeonGrid.SENTINEL:
			return door
	return DungeonGrid.SENTINEL


func _middle_face_wall(exit_cells: Dictionary, dir: Vector2i, wall_set: Dictionary) -> Vector2i:
	var face: Array[Vector2i] = []
	var seen: Dictionary = {}
	for cell in exit_cells:
		var neighbor: Vector2i = cell + dir
		if not wall_set.has(neighbor) or exit_cells.has(neighbor) or seen.has(neighbor):
			continue
		seen[neighbor] = true
		face.append(neighbor)
	if face.is_empty():
		return DungeonGrid.SENTINEL
	if dir.x != 0:
		face.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y)
	else:
		face.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x)
	return face[face.size() / 2]


func _is_shell_corner_cell(cell: Vector2i, walkable_set: Dictionary, wall_set: Dictionary) -> bool:
	if walkable_set.has(cell) or wall_set.has(cell):
		return false
	var wall_n: bool = wall_set.has(cell + Vector2i.UP)
	var wall_s: bool = wall_set.has(cell + Vector2i.DOWN)
	var wall_e: bool = wall_set.has(cell + Vector2i.RIGHT)
	var wall_w: bool = wall_set.has(cell + Vector2i.LEFT)
	if not ((wall_e or wall_w) and (wall_n or wall_s)):
		return false
	# Visible H↔V bends only: the inside of the L must be player-accessible.
	if wall_e and wall_s and walkable_set.has(cell + Vector2i.RIGHT + Vector2i.DOWN):
		return true
	if wall_w and wall_s and walkable_set.has(cell + Vector2i.LEFT + Vector2i.DOWN):
		return true
	if wall_e and wall_n and walkable_set.has(cell + Vector2i.RIGHT + Vector2i.UP):
		return true
	if wall_w and wall_n and walkable_set.has(cell + Vector2i.LEFT + Vector2i.UP):
		return true
	return false
