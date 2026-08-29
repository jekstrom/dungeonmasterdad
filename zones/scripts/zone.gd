class_name Zone extends Area2D

const SPRITE_GRID_Y := -63.0
const HOME_OVERLAY_PATH := "res://sprites/reality_home_overlay.png"
const FANTASY_HOME_OVERLAY_PATH := "res://sprites/fantasy_home_overlay.png"

@export var base_radius: float = 100.0
@export var zone_color: Color = Color(0, 1, 0, 0.3)
@export var is_reality: bool = false
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var radius
var home_rect: Rect2i = Rect2i()
var _home_overlay_root: Node2D = null
var _home_overlay_texture: Texture2D = null

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
	clip_home_to_interior()

func _draw() -> void:
	# Home look is cell overlays (Reality and Fantasy). Skip debug circle/rect.
	return

func contains_world_position(world: Vector2) -> bool:
	if home_rect.size.x <= 0 or home_rect.size.y <= 0:
		return false
	return home_rect.has_point(DungeonGrid.from_world(world))

func contains_world_rect(rect: Rect2) -> bool:
	if home_rect.size.x <= 0 or home_rect.size.y <= 0:
		return false
	var home_world := Rect2(
		DungeonGrid.to_world(home_rect.position),
		Vector2(home_rect.size) * DungeonGrid.CELL_PX
	)
	return home_world.encloses(rect)

func on_level_changed(_new_level: int) -> void:
	clip_home_to_interior()

func _on_map_bounds_committed(_interior: Rect2i) -> void:
	clip_home_to_interior()

func _on_map_bounds_cleared() -> void:
	home_rect = Rect2i()
	_clear_home_overlay()
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
		_clear_home_overlay()
		if _resolve_collision_shape():
			collision_shape_2d.disabled = true
		return
	var world_origin: Vector2 = DungeonGrid.to_world(home_rect.position)
	var world_size: Vector2 = Vector2(home_rect.size) * DungeonGrid.CELL_PX
	global_position = world_origin + world_size * 0.5
	_apply_rect_collision(world_size)
	_rebuild_home_overlay()
	queue_redraw()

func _apply_rect_collision(world_size: Vector2) -> void:
	if not _resolve_collision_shape():
		return
	collision_shape_2d.scale = Vector2.ONE
	collision_shape_2d.position = Vector2.ZERO
	collision_shape_2d.disabled = false
	var rect_shape: RectangleShape2D
	if collision_shape_2d.shape is RectangleShape2D:
		rect_shape = collision_shape_2d.shape as RectangleShape2D
		if not rect_shape.resource_local_to_scene:
			rect_shape = rect_shape.duplicate() as RectangleShape2D
			rect_shape.resource_local_to_scene = true
			collision_shape_2d.shape = rect_shape
	else:
		rect_shape = RectangleShape2D.new()
		rect_shape.resource_local_to_scene = true
		collision_shape_2d.shape = rect_shape
	rect_shape.size = world_size

func _rebuild_home_overlay() -> void:
	_ensure_home_overlay_root()
	_clear_overlay_children(_home_overlay_root)
	if _home_overlay_texture == null:
		var path: String = HOME_OVERLAY_PATH if is_reality else FANTASY_HOME_OVERLAY_PATH
		_home_overlay_texture = load(path) as Texture2D
	if _home_overlay_texture == null:
		return
	for y in range(home_rect.position.y, home_rect.end.y):
		for x in range(home_rect.position.x, home_rect.end.x):
			_place_overlay_sprite(_home_overlay_root, _home_overlay_texture, Vector2i(x, y), 0)

func _place_overlay_sprite(parent: Node2D, texture: Texture2D, cell: Vector2i, z: int) -> void:
	if parent == null or texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.z_as_relative = false
	sprite.z_index = z
	sprite.position = DungeonGrid.to_world(cell) - global_position + Vector2(0.0, SPRITE_GRID_Y)
	parent.add_child(sprite)

func _clear_overlay_children(parent: Node2D) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func _ensure_home_overlay_root() -> void:
	if _home_overlay_root != null and is_instance_valid(_home_overlay_root):
		return
	_home_overlay_root = get_node_or_null("HomeOverlay") as Node2D
	if _home_overlay_root == null:
		_home_overlay_root = Node2D.new()
		_home_overlay_root.name = "HomeOverlay"
		add_child(_home_overlay_root)

func _clear_home_overlay() -> void:
	_clear_overlay_children(_home_overlay_root)

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
