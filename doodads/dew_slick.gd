class_name DewSlick extends Node2D

const DEFAULT_DURATION_SEC := 6.0
const SLIDE_ACCEL := 1400.0
const SLIDE_DECEL := 320.0
const TEAL := Color(0.05, 0.92, 0.82, 0.55)

@export var duration_sec: float = DEFAULT_DURATION_SEC

var remaining_sec: float = 0.0
var room_cells: Array[Vector2i] = []
var _cell_set: Dictionary = {}


func _ready() -> void:
	add_to_group("dew_slick")
	z_index = DungeonConstants.FLOOR_Z_INDEX + 1
	y_sort_enabled = false
	z_as_relative = true
	var wash: CanvasItem = get_node_or_null("Wash") as CanvasItem
	if wash and wash.material is ShaderMaterial:
		wash.material = wash.material.duplicate()
	_apply_teal()
	_rebuild_polygon()


func refresh(cells: Array[Vector2i], origin: Vector2, duration: float) -> void:
	room_cells = cells.duplicate()
	_cell_set.clear()
	for cell in room_cells:
		_cell_set[cell] = true
	remaining_sec = maxf(0.1, duration)
	duration_sec = remaining_sec
	global_position = origin
	_rebuild_polygon()
	_apply_teal()
	visible = true


func pack_cells() -> Array:
	return DungeonGrid.points_to_dicts(room_cells)


func covers_world(world: Vector2) -> bool:
	if remaining_sec <= 0.0:
		return false
	if _cell_set.is_empty():
		return false
	return _cell_set.has(DungeonGrid.from_world(world))


static func any_covers_world(world: Vector2) -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return false
	for node in tree.get_nodes_in_group("dew_slick"):
		if node.has_method("covers_world") and bool(node.call("covers_world", world)):
			return true
	return false


static func slide_velocity(current: Vector2, desired: Vector2, delta: float) -> Vector2:
	var dt: float = maxf(0.0, delta)
	if desired.length_squared() < 1.0:
		return current.move_toward(Vector2.ZERO, SLIDE_DECEL * dt)
	return current.move_toward(desired, SLIDE_ACCEL * dt)


func _process(delta: float) -> void:
	if remaining_sec <= 0.0:
		return
	remaining_sec = maxf(0.0, remaining_sec - delta)
	if remaining_sec <= 0.0:
		visible = false
		_cell_set.clear()
		queue_free()


func _apply_teal() -> void:
	var wash: CanvasItem = get_node_or_null("Wash") as CanvasItem
	if wash == null:
		return
	wash.z_index = 0
	var mat := wash.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("teal", TEAL)


func _rebuild_polygon() -> void:
	var wash: Sprite2D = get_node_or_null("Wash") as Sprite2D
	var bubbles: CPUParticles2D = get_node_or_null("Bubbles") as CPUParticles2D
	_apply_teal()
	if _cell_set.is_empty():
		if wash:
			wash.visible = false
		if bubbles:
			bubbles.emitting = false
		return
	var min_c: Vector2i = _cell_set.keys()[0]
	var max_c: Vector2i = min_c
	for cell in _cell_set.keys():
		min_c.x = mini(min_c.x, cell.x)
		min_c.y = mini(min_c.y, cell.y)
		max_c.x = maxi(max_c.x, cell.x)
		max_c.y = maxi(max_c.y, cell.y)
	var world_pos: Vector2 = DungeonGrid.to_world(min_c)
	var world_end: Vector2 = DungeonGrid.to_world(max_c + Vector2i.ONE)
	var top_left: Vector2 = world_pos - global_position
	var size: Vector2 = world_end - world_pos
	if wash:
		wash.visible = true
		wash.centered = false
		wash.position = top_left
		wash.region_enabled = true
		wash.region_rect = Rect2(Vector2.ZERO, size)
		var mat := wash.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("puddle_px", size)
			mat.set_shader_parameter("teal", TEAL)
	if bubbles:
		bubbles.position = top_left + size * 0.5
		bubbles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		bubbles.emission_rect_extents = size * 0.46
		bubbles.amount = clampi(int((size.x * size.y) / 14000.0), 10, 40)
		bubbles.emitting = true
		bubbles.z_index = 1
