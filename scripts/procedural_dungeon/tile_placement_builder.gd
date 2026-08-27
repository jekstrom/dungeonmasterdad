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
		placements.append({
			"position": {"x": cell.x, "y": cell.y},
			"tileRole": role,
			"tileSourcePath": _tile_catalog.get_floor_scene_path(),
			"variantId": variant_id
		})

	var wall_set: Dictionary = {}
	for cell in layout_data.blocked_cells:
		if _is_occupancy_adjacent(cell, walkable_set):
			wall_set[cell] = true
	for cell in layout_data.blocked_cells:
		if _is_shell_corner_cell(cell, walkable_set, wall_set):
			wall_set[cell] = true
	for cell in wall_set:
		placements.append({
			"position": {"x": cell.x, "y": cell.y},
			"tileRole": "wall",
			"tileSourcePath": _tile_catalog.get_wall_scene_path(),
			"variantId": WallAutotile.wall_type(cell, walkable_set),
			"wallFrame": WallAutotile.wall_frame(cell, walkable_set, wall_set)
		})
	return placements


func _is_occupancy_adjacent(cell: Vector2i, walkable_set: Dictionary) -> bool:
	for neighbor in DungeonGrid.neighbors(cell):
		if walkable_set.has(neighbor):
			return true
	return false


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
