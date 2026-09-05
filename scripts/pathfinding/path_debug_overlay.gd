extends Node2D

const TILE_COLOR := Color(1.0, 0.92, 0.2, 0.35)
const PATH_CELL_COLOR := Color(0.35, 0.75, 1.0, 0.22)
const BLOCKED_COLOR := Color(1.0, 0.15, 0.15, 0.18)
const PATH_COLOR := Color(0.15, 1.0, 0.45, 0.95)
const GOAL_COLOR := Color(1.0, 0.45, 0.1, 0.95)

var enabled: bool = false


func _ready() -> void:
	z_index = 4096
	z_as_relative = false
	y_sort_enabled = false
	visible = false


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("toggle_minimap_debug_reveal"):
		return
	enabled = not enabled
	visible = enabled
	queue_redraw()


func _process(_delta: float) -> void:
	if enabled:
		queue_redraw()


func _draw() -> void:
	if not enabled:
		return
	var finder: Node = get_parent()
	if finder == null:
		return
	var view: Rect2 = _visible_world()
	_draw_tile_grid(view)
	_draw_occupancy(finder, view)
	_draw_mob_paths(finder)


func _visible_world() -> Rect2:
	var vp: Viewport = get_viewport()
	if vp == null:
		return Rect2()
	var size: Vector2 = vp.get_visible_rect().size
	var cam: Camera2D = vp.get_camera_2d()
	if cam == null:
		return Rect2(Vector2.ZERO, size)
	var zoom: Vector2 = cam.zoom
	var world_size := Vector2(size.x / maxf(zoom.x, 0.001), size.y / maxf(zoom.y, 0.001))
	return Rect2(cam.get_screen_center_position() - world_size * 0.5, world_size).grow(128.0)


func _draw_tile_grid(view: Rect2) -> void:
	var px: float = DungeonGrid.CELL_PX
	var ox: float = -DungeonGrid.SPRITE_HALF_X
	var oy: float = -DungeonGrid.SPRITE_TOP
	var x0: int = int(floor((view.position.x - ox) / px))
	var y0: int = int(floor((view.position.y - oy) / px))
	var x1: int = int(ceil((view.end.x - ox) / px))
	var y1: int = int(ceil((view.end.y - oy) / px))
	for x in range(x0, x1 + 1):
		var wx: float = float(x) * px + ox
		draw_line(Vector2(wx, view.position.y), Vector2(wx, view.end.y), TILE_COLOR, 1.0)
	for y in range(y0, y1 + 1):
		var wy: float = float(y) * px + oy
		draw_line(Vector2(view.position.x, wy), Vector2(view.end.x, wy), TILE_COLOR, 1.0)


func _draw_occupancy(finder: Node, view: Rect2) -> void:
	var occ = finder.occupancy
	if occ == null or occ.region.size.x <= 0:
		return
	var px: float = float(occ.CELL_PX)
	var x0: int = int(floor(view.position.x / px))
	var y0: int = int(floor(view.position.y / px))
	var x1: int = int(ceil(view.end.x / px))
	var y1: int = int(ceil(view.end.y / px))
	for x in range(x0, x1 + 1):
		var wx: float = float(x) * px
		draw_line(Vector2(wx, view.position.y), Vector2(wx, view.end.y), PATH_CELL_COLOR, 1.0)
	for y in range(y0, y1 + 1):
		var wy: float = float(y) * px
		draw_line(Vector2(view.position.x, wy), Vector2(view.end.x, wy), PATH_CELL_COLOR, 1.0)
	for y in range(y0, y1):
		for x in range(x0, x1):
			var cell := Vector2i(x, y)
			if occ.region.has_point(cell) and not occ.is_walkable(cell):
				draw_rect(Rect2(Vector2(cell) * px, Vector2(px, px)), BLOCKED_COLOR, true)


func _draw_mob_paths(finder: Node) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("monsters"):
		if not (node is Node2D) or not is_instance_valid(node):
			continue
		var mob: Node2D = node as Node2D
		var points: PackedVector2Array = PackedVector2Array()
		points.append(mob.global_position)
		if node.has_method("debug_follow_path"):
			var cells: Array = node.call("debug_follow_path")
			for cell in cells:
				points.append(finder.cell_center(cell))
			var goal: Vector2 = node.call("debug_follow_goal")
			if is_finite(goal.x) and is_finite(goal.y):
				var last: Vector2 = points[points.size() - 1]
				if bool(finder.world_segment_walkable(last, goal, false)):
					points.append(goal)
					draw_circle(goal, 6.0, GOAL_COLOR)
		if points.size() < 2:
			continue
		draw_polyline(points, PATH_COLOR, 2.0)
		for i in range(1, points.size()):
			draw_circle(points[i], 3.5, PATH_COLOR)
