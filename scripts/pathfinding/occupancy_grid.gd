extends RefCounted

const CELL_PX: float = 32.0

var region: Rect2i = Rect2i()
var walkable: Dictionary = {}
var cliffs: Dictionary = {}
var dungeon_floors: Dictionary = {}
var exit_door: Vector2i = DungeonGrid.SENTINEL
var exit_landing: Vector2i = DungeonGrid.SENTINEL
var _manual: bool = false


static func from_world(world: Vector2) -> Vector2i:
	return Vector2i(int(floor(world.x / CELL_PX)), int(floor(world.y / CELL_PX)))


static func to_world_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * CELL_PX


static func subdiv() -> int:
	return maxi(1, int(round(DungeonGrid.CELL_PX / CELL_PX)))


func clear() -> void:
	region = Rect2i()
	walkable.clear()
	cliffs.clear()
	dungeon_floors.clear()
	exit_door = DungeonGrid.SENTINEL
	exit_landing = DungeonGrid.SENTINEL
	_manual = false


func load_manual(new_region: Rect2i, walkable_cells: Array[Vector2i], cliff_cells: Array[Vector2i] = []) -> void:
	clear()
	_manual = true
	region = new_region
	for cell in walkable_cells:
		walkable[cell] = true
	for cell in cliff_cells:
		cliffs[cell] = true


func rebuild_from_world(tree: SceneTree) -> void:
	if _manual:
		return
	clear()
	var interior: Rect2i = Rect2i()
	var dungeon_aabb: Rect2i = Rect2i()
	var dungeon_walk: Dictionary = {}
	var level: Node = null
	if tree:
		level = tree.get_first_node_in_group("level_manager")
	if level and level.has_method("get_map_bounds"):
		var bounds = level.get_map_bounds()
		if bounds != null and bounds.has_method("get_interior"):
			interior = bounds.get_interior()
	if level and level.has_method("dungeon_cell_bounds"):
		dungeon_aabb = level.dungeon_cell_bounds()
	var manager: Node = null
	if tree:
		manager = tree.root.get_node_or_null("DungeonGenerationManager")
	if manager and manager.has_method("get_dungeon_cell_bounds") and dungeon_aabb.size.x <= 0:
		dungeon_aabb = manager.get_dungeon_cell_bounds()
	if manager != null:
		dungeon_walk = _dungeon_walkable_from_manager(manager)
		exit_door = _dungeon_door_from_manager(manager)
	dungeon_floors = dungeon_walk
	var dungeon_walls: Dictionary = _dungeon_walls_from_manager(manager)
	exit_landing = _landing_from_door(exit_door, dungeon_walk, dungeon_walls, interior)
	_paint_world_tiles(interior, dungeon_aabb, dungeon_walk, dungeon_walls, exit_door)
	_block_live_wall_colliders(tree)
	_block_live_tree_trunks(tree)
	_apply_solid_nodes(tree)


func _paint_world_tiles(
	interior: Rect2i,
	dungeon_aabb: Rect2i,
	dungeon_walk: Dictionary,
	dungeon_walls: Dictionary,
	door: Vector2i = DungeonGrid.SENTINEL
) -> void:
	var world_region: Rect2i = _union_rect(interior, dungeon_aabb)
	if world_region.size.x <= 0 or world_region.size.y <= 0:
		return
	var scale: int = subdiv()
	var origin0: Vector2i = layout_path_origin(world_region.position)
	var last_world: Vector2i = world_region.end - Vector2i.ONE
	var origin1: Vector2i = layout_path_origin(last_world)
	var min_p: Vector2i = Vector2i(mini(origin0.x, origin1.x), mini(origin0.y, origin1.y))
	var max_p: Vector2i = Vector2i(maxi(origin0.x, origin1.x), maxi(origin0.y, origin1.y)) + Vector2i(scale, scale)
	region = Rect2i(min_p, max_p - min_p)
	for y in range(world_region.position.y, world_region.end.y):
		for x in range(world_region.position.x, world_region.end.x):
			var world_cell := Vector2i(x, y)
			if _world_is_cliff(world_cell, interior):
				_stamp_world_cell(world_cell, false, true)
				continue
			if _world_tile_walkable(world_cell, interior, dungeon_walk, dungeon_walls, door):
				_stamp_world_cell(world_cell, true, false)
	_block_layout_wall_segments(dungeon_walls, dungeon_walk)
	_seal_wall_exteriors(dungeon_walls, dungeon_walk)


static func layout_sprite_rect(world_cell: Vector2i) -> Rect2:
	var origin: Vector2 = DungeonGrid.to_world(world_cell) - Vector2(DungeonGrid.SPRITE_HALF_X, DungeonGrid.SPRITE_TOP)
	return Rect2(origin, Vector2(DungeonGrid.CELL_PX, DungeonGrid.CELL_PX))


static func layout_path_origin(world_cell: Vector2i) -> Vector2i:
	return from_world(layout_sprite_rect(world_cell).position)


static func _world_tile_walkable(
	cell: Vector2i,
	interior: Rect2i,
	dungeon_walk: Dictionary,
	dungeon_walls: Dictionary,
	door: Vector2i = DungeonGrid.SENTINEL
) -> bool:
	if dungeon_walls.has(cell):
		return true
	if dungeon_walk.has(cell):
		return true
	if dungeon_walk.size() > 0 and _adjacent_to_set(cell, dungeon_walk):
		if door == DungeonGrid.SENTINEL or not _is_door_adjacent(cell, door):
			return false
	if interior.size.x > 0 and interior.has_point(cell):
		return true
	return false


static func _adjacent_to_set(cell: Vector2i, cells: Dictionary) -> bool:
	for n in DungeonGrid.neighbors(cell):
		if cells.has(n):
			return true
	return false


static func _is_door_adjacent(cell: Vector2i, door: Vector2i) -> bool:
	if cell == door:
		return true
	return absi(cell.x - door.x) + absi(cell.y - door.y) == 1


static func _landing_from_door(
	door: Vector2i,
	dungeon_walk: Dictionary,
	dungeon_walls: Dictionary,
	interior: Rect2i
) -> Vector2i:
	if door == DungeonGrid.SENTINEL:
		return DungeonGrid.SENTINEL
	for n in DungeonGrid.neighbors(door):
		if dungeon_walk.has(n):
			continue
		if dungeon_walls.has(n):
			continue
		if interior.size.x > 0 and interior.has_point(n):
			return n
	return DungeonGrid.SENTINEL


static func world_cell_of_path(path_cell: Vector2i) -> Vector2i:
	var world: Vector2 = to_world_center(path_cell)
	return DungeonGrid.from_world(world + Vector2(DungeonGrid.SPRITE_HALF_X, DungeonGrid.SPRITE_TOP))


func is_portal_pair(a: Vector2i, b: Vector2i) -> bool:
	if exit_door == DungeonGrid.SENTINEL or exit_landing == DungeonGrid.SENTINEL:
		return false
	var wa: Vector2i = layout_cell_of_path(a)
	var wb: Vector2i = layout_cell_of_path(b)
	return (wa == exit_door and wb == exit_landing) or (wa == exit_landing and wb == exit_door)


func layout_cell_of_path(path_cell: Vector2i) -> Vector2i:
	if _manual:
		var scale: int = subdiv()
		return Vector2i(
			int(floor(float(path_cell.x) / float(scale))),
			int(floor(float(path_cell.y) / float(scale)))
		)
	return world_cell_of_path(path_cell)


func _dungeon_walls_from_manager(manager: Node) -> Dictionary:
	var walls: Dictionary = {}
	if manager == null:
		return walls
	var layout = _active_layout(manager)
	if layout == null:
		return walls
	for placement in layout.tile_placements:
		if str(placement.get("tileRole", "")) != "wall":
			continue
		walls[DungeonGrid.cell_from(placement.get("position", {}))] = true
	return walls


func _active_layout(manager: Node):
	var layout_id: String = str(manager.get("active_layout_id"))
	var layouts: Dictionary = manager.get("layouts_by_id")
	if layout_id.is_empty() or not (layouts is Dictionary) or not layouts.has(layout_id):
		return null
	return layouts[layout_id]


func _dungeon_door_from_manager(manager: Node) -> Vector2i:
	var layout = _active_layout(manager)
	if layout == null:
		return DungeonGrid.SENTINEL
	var floors: Dictionary = {}
	for cell in layout.walkable_cells:
		floors[cell] = true
	for placement in layout.tile_placements:
		var role: String = str(placement.get("tileRole", ""))
		if role != "floor" and role != "entrance" and role != "exit":
			continue
		var cell: Vector2i = DungeonGrid.cell_from(placement.get("position", {}))
		if not floors.has(cell):
			return cell
	if layout.exit_cell != DungeonGrid.SENTINEL:
		return layout.exit_cell
	return DungeonGrid.SENTINEL


func is_dungeon_path_cell(path_cell: Vector2i) -> bool:
	if dungeon_floors.is_empty():
		return false
	return dungeon_floors.has(layout_cell_of_path(path_cell))


func _dungeon_walkable_from_manager(manager: Node) -> Dictionary:
	var result: Dictionary = {}
	var layout = _active_layout(manager)
	if layout == null:
		return result
	for cell in layout.walkable_cells:
		result[cell] = true
	for placement in layout.tile_placements:
		var role: String = str(placement.get("tileRole", ""))
		if role != "floor" and role != "entrance" and role != "exit":
			continue
		result[DungeonGrid.cell_from(placement.get("position", {}))] = true
	return result


func _block_live_tree_trunks(tree: SceneTree) -> void:
	if tree == null:
		return
	var seen: Dictionary = {}
	var groups: Array[String] = ["harvest_trees", "scattered_trees", "exit_forest_trees"]
	for group_name in groups:
		for node in tree.get_nodes_in_group(group_name):
			if not (node is Node2D) or not is_instance_valid(node):
				continue
			var id: int = node.get_instance_id()
			if seen.has(id):
				continue
			seen[id] = true
			_block_doodad_static_body(node as Node2D)


func _block_doodad_static_body(node: Node2D) -> void:
	var body: Node = node.get_node_or_null("StaticBody2D")
	if body == null:
		body = node.get_node_or_null("StaticBody")
	if body == null:
		return
	for child in body.get_children():
		if not (child is CollisionShape2D):
			continue
		var col: CollisionShape2D = child as CollisionShape2D
		if col.disabled:
			continue
		var shape: Shape2D = col.shape
		if not (shape is RectangleShape2D):
			continue
		var rect_shape: RectangleShape2D = shape as RectangleShape2D
		var world_size: Vector2 = rect_shape.size * Vector2(absf(col.global_scale.x), absf(col.global_scale.y))
		if world_size.x <= 0.0 or world_size.y <= 0.0:
			continue
		var center: Vector2 = col.global_position
		_block_world_rect(Rect2(center - world_size * 0.5, world_size).grow(8.0))


func _apply_solid_nodes(tree: SceneTree) -> void:
	if tree == null:
		return
	for node in tree.get_nodes_in_group("buildings"):
		if not (node is Node2D) or not is_instance_valid(node):
			continue
		if node.get("is_ghost") == true:
			continue
		if node.get("destroyed") == true:
			continue
		_block_node_cells(node as Node2D)


func _block_layout_wall_segments(dungeon_walls: Dictionary, dungeon_walk: Dictionary = {}) -> void:
	const WALL_THICK := 40.0
	const WALL_FACE := 44.0
	const OX := 44.0
	const OY := 44.0
	var foot_y0: float = OY + WALL_THICK
	var foot_y1: float = 128.0
	for cell in dungeon_walls:
		var n: bool = dungeon_walls.has(cell + Vector2i.UP)
		var e: bool = dungeon_walls.has(cell + Vector2i.RIGHT)
		var s: bool = dungeon_walls.has(cell + Vector2i.DOWN)
		var w: bool = dungeon_walls.has(cell + Vector2i.LEFT)
		var has_h: bool = e or w
		var has_v: bool = n or s
		var node_pos: Vector2 = DungeonGrid.to_world(cell)
		if has_h:
			var hx0: float = 0.0 if w else OX
			var hx1: float = 128.0 if e else OX + WALL_THICK
			_block_tile_local_rect(node_pos, hx0, foot_y0, hx1, foot_y1)
		if has_v:
			var vy0: float = 0.0 if n else foot_y0
			_block_tile_local_rect(node_pos, OX, vy0, OX + WALL_THICK, foot_y1)
		if not has_h and not has_v:
			if dungeon_walk.has(cell + Vector2i.RIGHT) or dungeon_walk.has(cell + Vector2i.LEFT):
				_block_tile_local_rect(node_pos, OX, 0.0, OX + WALL_THICK, 128.0)
			else:
				_block_tile_local_rect(node_pos, 0.0, foot_y0, 128.0, foot_y1)


func _seal_wall_exteriors(dungeon_walls: Dictionary, dungeon_walk: Dictionary) -> void:
	const WALL_THICK := 40.0
	const OX := 44.0
	const OY := 44.0
	var foot_y0: float = OY + WALL_THICK
	var scale: int = subdiv()
	for wall_cell in dungeon_walls:
		var n: bool = dungeon_walls.has(wall_cell + Vector2i.UP)
		var e: bool = dungeon_walls.has(wall_cell + Vector2i.RIGHT)
		var s: bool = dungeon_walls.has(wall_cell + Vector2i.DOWN)
		var w: bool = dungeon_walls.has(wall_cell + Vector2i.LEFT)
		var has_h: bool = e or w
		var has_v: bool = n or s
		var floors: Array[Vector2i] = []
		for nb in DungeonGrid.neighbors(wall_cell):
			if dungeon_walk.has(nb):
				floors.append(nb)
		if floors.is_empty():
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var diag: Vector2i = wall_cell + Vector2i(dx, dy)
					if dungeon_walk.has(diag):
						floors.append(diag)
		var node_pos: Vector2 = DungeonGrid.to_world(wall_cell)
		var col_x: float = node_pos.x + OX + WALL_THICK * 0.5 - 64.0
		var foot_mid_y: float = node_pos.y + (foot_y0 + 128.0) * 0.5 - 127.0
		var origin: Vector2i = layout_path_origin(wall_cell)
		for oy in range(scale):
			for ox in range(scale):
				var cell: Vector2i = origin + Vector2i(ox, oy)
				if not walkable.has(cell):
					continue
				if floors.is_empty():
					walkable.erase(cell)
					continue
				var center: Vector2 = to_world_center(cell)
				if not _path_cell_on_interior_side(center, wall_cell, floors, has_h, has_v, col_x, foot_mid_y, dungeon_walk):
					walkable.erase(cell)


func _path_cell_on_interior_side(
	center: Vector2,
	wall_cell: Vector2i,
	floors: Array[Vector2i],
	has_h: bool,
	has_v: bool,
	col_x: float,
	foot_mid_y: float,
	dungeon_walk: Dictionary
) -> bool:
	var floor_east := false
	var floor_west := false
	var floor_north := false
	var floor_south := false
	for floor_cell in floors:
		if floor_cell.x > wall_cell.x:
			floor_east = true
		if floor_cell.x < wall_cell.x:
			floor_west = true
		if floor_cell.y < wall_cell.y:
			floor_north = true
		if floor_cell.y > wall_cell.y:
			floor_south = true
	var vertical: bool = has_v or (not has_h and not has_v and (dungeon_walk.has(wall_cell + Vector2i.RIGHT) or dungeon_walk.has(wall_cell + Vector2i.LEFT)))
	var horizontal: bool = has_h or (not has_h and not has_v and not vertical)
	if vertical:
		if floor_east and center.x < col_x:
			return false
		if floor_west and center.x > col_x:
			return false
	if horizontal:
		if floor_north and center.y > foot_mid_y:
			return false
		if floor_south and center.y < foot_mid_y:
			return false
	return true


func _block_tile_local_rect(node_pos: Vector2, tx0: float, ty0: float, tx1: float, ty1: float) -> void:
	var size := Vector2(tx1 - tx0, ty1 - ty0)
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var center: Vector2 = node_pos + Vector2((tx0 + tx1) * 0.5 - 64.0, (ty0 + ty1) * 0.5 - 127.0)
	_block_world_rect(Rect2(center - size * 0.5, size))


func _block_live_wall_colliders(tree: SceneTree) -> void:
	if tree == null:
		return
	var nodes: Array = []
	nodes.append_array(tree.get_nodes_in_group("wall"))
	for node in tree.get_nodes_in_group("generated_dungeon_tiles"):
		if node is WallDoodad:
			nodes.append(node)
	for node in nodes:
		if not (node is Node2D) or not is_instance_valid(node):
			continue
		var body: Node = node.get_node_or_null("StaticBody")
		if body == null:
			continue
		for child in body.get_children():
			if not (child is CollisionShape2D):
				continue
			var col: CollisionShape2D = child as CollisionShape2D
			if col.disabled:
				continue
			var shape: Shape2D = col.shape
			if not (shape is RectangleShape2D):
				continue
			var rect_shape: RectangleShape2D = shape as RectangleShape2D
			var half: Vector2 = rect_shape.size * 0.5
			_block_world_rect(Rect2(col.global_position - half, rect_shape.size))


func _block_world_rect(rect: Rect2) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var min_c: Vector2i = from_world(rect.position)
	var max_c: Vector2i = from_world(rect.position + rect.size - Vector2(0.001, 0.001))
	for y in range(min_c.y, max_c.y + 1):
		for x in range(min_c.x, max_c.x + 1):
			var cell := Vector2i(x, y)
			if rect.has_point(to_world_center(cell)):
				walkable.erase(cell)


func _stamp_world_cell(world_cell: Vector2i, walk: bool, cliff: bool) -> void:
	var scale: int = subdiv()
	var origin: Vector2i = layout_path_origin(world_cell)
	for oy in range(scale):
		for ox in range(scale):
			var cell: Vector2i = origin + Vector2i(ox, oy)
			if cliff:
				cliffs[cell] = true
				walkable.erase(cell)
			elif walk:
				walkable[cell] = true
			else:
				walkable.erase(cell)


func _world_is_cliff(world_cell: Vector2i, interior: Rect2i) -> bool:
	if interior.size.x <= 0:
		return false
	var outer: Rect2i = Rect2i(interior.position - Vector2i.ONE, interior.size + Vector2i(2, 2))
	return outer.has_point(world_cell) and not interior.has_point(world_cell)


func _block_node_cells(node: Node2D) -> void:
	walkable.erase(from_world(node.global_position))
	if node is Building:
		var hull: Rect2 = (node as Building).raid_hull_rect(0.0)
		var min_c: Vector2i = from_world(hull.position)
		var max_c: Vector2i = from_world(hull.position + hull.size)
		for y in range(min_c.y, max_c.y + 1):
			for x in range(min_c.x, max_c.x + 1):
				walkable.erase(Vector2i(x, y))


func is_walkable(cell: Vector2i) -> bool:
	return walkable.has(cell)


func is_world_walkable(world: Vector2) -> bool:
	if region.size.x <= 0:
		return true
	return walkable.has(from_world(world))


func inland_penalty(cell: Vector2i) -> bool:
	for neighbor in DungeonGrid.neighbors(cell):
		if cliffs.has(neighbor):
			return true
		if region.size.x > 0 and not region.has_point(neighbor):
			return true
	return false


func nearest_walkable(from_cell: Vector2i, max_radius: int = 24) -> Vector2i:
	if walkable.has(from_cell):
		return from_cell
	if region.size.x <= 0:
		return from_cell
	for r in range(1, max_radius + 1):
		for y in range(from_cell.y - r, from_cell.y + r + 1):
			for x in range(from_cell.x - r, from_cell.x + r + 1):
				if maxi(absi(x - from_cell.x), absi(y - from_cell.y)) != r:
					continue
				var cell := Vector2i(x, y)
				if walkable.has(cell):
					return cell
	return DungeonGrid.SENTINEL


static func _union_rect(a: Rect2i, b: Rect2i) -> Rect2i:
	if a.size.x <= 0 and a.size.y <= 0:
		return b
	if b.size.x <= 0 and b.size.y <= 0:
		return a
	var min_p: Vector2i = Vector2i(mini(a.position.x, b.position.x), mini(a.position.y, b.position.y))
	var max_p: Vector2i = Vector2i(maxi(a.end.x, b.end.x), maxi(a.end.y, b.end.y))
	return Rect2i(min_p, max_p - min_p)
