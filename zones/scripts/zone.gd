class_name Zone extends Area2D

@export var base_radius: float = 100.0
@export var zone_color: Color = Color(0, 1, 0, 0.3)
@export var is_reality: bool = false
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var radius
var home_rect: Rect2i = Rect2i()

func _ready() -> void:
	if is_reality:
		if not PlayerManager.reality_level_changed.is_connected(on_level_changed):
			PlayerManager.reality_level_changed.connect(on_level_changed)
	else:
		if not DmManager.fantasy_level_changed.is_connected(on_level_changed):
			DmManager.fantasy_level_changed.connect(on_level_changed)
	if not SignalBus.map_bounds_committed.is_connected(_on_map_bounds_committed):
		SignalBus.map_bounds_committed.connect(_on_map_bounds_committed)
	if not SignalBus.map_bounds_cleared.is_connected(_on_map_bounds_cleared):
		SignalBus.map_bounds_cleared.connect(_on_map_bounds_cleared)
	radius = base_radius + float(_current_zone_level())
	_apply_circle_radius(radius)
	clip_home_to_interior()

func _draw() -> void:
	if home_rect.size.x > 0 and home_rect.size.y > 0:
		var world_origin: Vector2 = DungeonGrid.to_world(home_rect.position)
		var world_size: Vector2 = Vector2(home_rect.size) * DungeonGrid.CELL_PX
		var local_rect := Rect2(world_origin - global_position, world_size)
		draw_rect(local_rect, zone_color)
		draw_rect(local_rect, zone_color.darkened(0.5), false, 2.0)
		return
	if radius == null:
		return
	draw_circle(Vector2.ZERO, radius, zone_color)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, zone_color.darkened(0.5), 2.0, true)

func on_level_changed(_new_level: int) -> void:
	clip_home_to_interior()
	if home_rect.size.x <= 0:
		radius = base_radius + float(_current_zone_level())
		_apply_circle_radius(radius)
		queue_redraw()

func _on_map_bounds_committed(_interior: Rect2i) -> void:
	clip_home_to_interior()

func _on_map_bounds_cleared() -> void:
	home_rect = Rect2i()
	queue_redraw()

func clip_home_to_interior() -> void:
	var bounds: MapBounds = _level_map_bounds()
	if bounds == null or not bounds.has_committed_bounds():
		return
	var interior: Rect2i = bounds.get_interior()
	if is_reality:
		_place_reality_home(bounds, interior)
	else:
		_place_fantasy_home(bounds, interior)
	_apply_clipped_home_presentation()

func clip_pocket_rect(rect: Rect2i) -> Rect2i:
	var bounds: MapBounds = _level_map_bounds()
	if bounds == null:
		return Rect2i()
	return bounds.intersect_interior(rect)

func _place_reality_home(bounds: MapBounds, interior: Rect2i) -> void:
	var width: int = _home_width_from_radius() + maxi(0, _current_zone_level())
	var proposed := Rect2i(interior.position, Vector2i(width, interior.size.y))
	home_rect = bounds.intersect_interior(proposed)

func _place_fantasy_home(bounds: MapBounds, interior: Rect2i) -> void:
	var seed_rect: Rect2i = _fantasy_seed_rect(interior)
	var growth: int = maxi(0, _current_zone_level())
	var proposed := Rect2i(
		seed_rect.position - Vector2i(growth, growth),
		seed_rect.size + Vector2i(growth * 2, growth * 2)
	)
	home_rect = bounds.intersect_interior(proposed)

func _fantasy_seed_rect(interior: Rect2i) -> Rect2i:
	var level_node: Node = _level_manager()
	if level_node and level_node.has_method("dungeon_cell_bounds"):
		var dungeon: Rect2i = level_node.dungeon_cell_bounds()
		if dungeon.size.x > 0 and dungeon.size.y > 0:
			return dungeon
	var width: int = _home_width_from_radius()
	return Rect2i(
		Vector2i(interior.end.x - width, interior.position.y),
		Vector2i(width, interior.size.y)
	)

func _apply_clipped_home_presentation() -> void:
	if home_rect.size.x <= 0 or home_rect.size.y <= 0:
		return
	var world_origin: Vector2 = DungeonGrid.to_world(home_rect.position)
	var world_size: Vector2 = Vector2(home_rect.size) * DungeonGrid.CELL_PX
	global_position = world_origin + world_size * 0.5
	radius = maxf(0.0, minf(world_size.x, world_size.y) * 0.5 - 0.5)
	_apply_circle_radius(radius)
	queue_redraw()

func _apply_circle_radius(value: float) -> void:
	if not _resolve_collision_shape():
		return
	collision_shape_2d.scale = Vector2.ONE
	collision_shape_2d.position = Vector2.ZERO
	if collision_shape_2d.shape is CircleShape2D:
		if not collision_shape_2d.shape.resource_local_to_scene:
			collision_shape_2d.shape = collision_shape_2d.shape.duplicate()
			collision_shape_2d.shape.resource_local_to_scene = true
		(collision_shape_2d.shape as CircleShape2D).radius = value

func _home_width_from_radius() -> int:
	return maxi(1, int(ceil(base_radius / DungeonGrid.CELL_PX)))

func _current_zone_level() -> int:
	if is_reality:
		return int(PlayerManager.reality_level)
	return int(DmManager.fantasy_level)

func _level_manager() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("level_manager")

func _level_map_bounds() -> MapBounds:
	var level_node: Node = _level_manager()
	if level_node and level_node.has_method("get_map_bounds"):
		return level_node.get_map_bounds()
	return null

func _resolve_collision_shape() -> bool:
	if collision_shape_2d == null:
		collision_shape_2d = get_node_or_null("CollisionShape2D")
	return collision_shape_2d != null
