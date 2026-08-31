@tool
class_name CliffDoodad extends Node2D

const CLIFF_Z_INDEX := 0
const SPRITE_GRID_Y := -63.0

enum CliffFrame {
	N,
	E,
	S,
	W,
	NW,
	NE,
	SW,
	SE,
	VOID,
}

@export var cliff_frame: CliffFrame = CliffFrame.N: set = _set_cliff_frame
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var grass_sprite: Sprite2D = $Grass
@onready var stone_b: Sprite2D = $Sprite2DStoneB
@onready var collision_a: CollisionShape2D = $StaticBody/CollisionShape2D
@onready var collision_b: CollisionShape2D = $StaticBody/CollisionShape2D2
@onready var static_body: StaticBody2D = $StaticBody

var _sort_shift: Vector2 = Vector2.ZERO

func _enter_tree() -> void:
	z_index = CLIFF_Z_INDEX
	y_sort_enabled = false
	if _resolve_nodes() and grass_sprite:
		grass_sprite.z_index = -1
		grass_sprite.z_as_relative = false
	if Engine.is_editor_hint():
		_ensure_unique_texture()

func _ready() -> void:
	z_index = CLIFF_Z_INDEX
	y_sort_enabled = false
	_ensure_unique_texture()
	_update_visual()

func _set_cliff_frame(value: CliffFrame) -> void:
	cliff_frame = value
	if not is_inside_tree() or not _resolve_nodes():
		if Engine.is_editor_hint():
			call_deferred("_update_visual")
		return
	_update_visual()

func _update_visual() -> void:
	if not _resolve_nodes():
		return
	_ensure_unique_texture()
	_apply_frame_crops()
	_apply_sort_shift()
	_update_collision()

func _apply_frame_crops() -> void:
	var grass: float = DungeonGrid.CLIFF_GRASS_MARGIN
	var stone: float = 128.0 - grass
	# New sheet is 8 cells (0-7). VOID has no atlas cell.
	var atlas_x: float = float(clampi(int(cliff_frame), 0, 7)) * 128.0
	match cliff_frame:
		CliffFrame.N:
			_crop_sprite(sprite_2d, atlas_x, Rect2(0, 0, 128, stone), true)
			_crop_sprite(grass_sprite, atlas_x, Rect2(0, stone, 128, grass), true)
			_crop_sprite(stone_b, atlas_x, Rect2(), false)
		CliffFrame.E:
			_crop_sprite(sprite_2d, atlas_x, Rect2(grass, 0, stone, 128), true)
			_crop_sprite(grass_sprite, atlas_x, Rect2(0, 0, grass, 128), true)
			_crop_sprite(stone_b, atlas_x, Rect2(), false)
		CliffFrame.S:
			_crop_sprite(sprite_2d, atlas_x, Rect2(0, grass, 128, stone), true)
			_crop_sprite(grass_sprite, atlas_x, Rect2(0, 0, 128, grass), true)
			_crop_sprite(stone_b, atlas_x, Rect2(), false)
		CliffFrame.W:
			_crop_sprite(sprite_2d, atlas_x, Rect2(0, 0, stone, 128), true)
			_crop_sprite(grass_sprite, atlas_x, Rect2(stone, 0, grass, 128), true)
			_crop_sprite(stone_b, atlas_x, Rect2(), false)
		CliffFrame.NW:
			_crop_sprite(sprite_2d, atlas_x, Rect2(0, 0, 128, stone), true)
			_crop_sprite(stone_b, atlas_x, Rect2(0, 0, stone, 128), true)
			_crop_sprite(grass_sprite, atlas_x, Rect2(stone, stone, grass, grass), true)
		CliffFrame.NE:
			_crop_sprite(sprite_2d, atlas_x, Rect2(0, 0, 128, stone), true)
			_crop_sprite(stone_b, atlas_x, Rect2(grass, 0, stone, 128), true)
			_crop_sprite(grass_sprite, atlas_x, Rect2(0, stone, grass, grass), true)
		CliffFrame.SW:
			_crop_sprite(sprite_2d, atlas_x, Rect2(0, grass, 128, stone), true)
			_crop_sprite(stone_b, atlas_x, Rect2(0, 0, stone, 128), true)
			_crop_sprite(grass_sprite, atlas_x, Rect2(stone, 0, grass, grass), true)
		CliffFrame.SE:
			_crop_sprite(sprite_2d, atlas_x, Rect2(0, grass, 128, stone), true)
			_crop_sprite(stone_b, atlas_x, Rect2(grass, 0, stone, 128), true)
			_crop_sprite(grass_sprite, atlas_x, Rect2(0, 0, grass, grass), true)
		CliffFrame.VOID:
			_crop_sprite(sprite_2d, atlas_x, Rect2(), false)
			_crop_sprite(grass_sprite, atlas_x, Rect2(), false)
			_crop_sprite(stone_b, atlas_x, Rect2(), false)
		_:
			_crop_sprite(sprite_2d, atlas_x, Rect2(0, 0, 128, stone), true)
			_crop_sprite(grass_sprite, atlas_x, Rect2(0, stone, 128, grass), true)
			_crop_sprite(stone_b, atlas_x, Rect2(), false)

func _crop_sprite(sprite: Sprite2D, atlas_x: float, rect: Rect2, show_sprite: bool) -> void:
	if sprite == null:
		return
	sprite.visible = show_sprite and rect.size.x > 0.0 and rect.size.y > 0.0
	if not sprite.visible:
		return
	if sprite.texture is AtlasTexture:
		(sprite.texture as AtlasTexture).region = Rect2(atlas_x + rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	sprite.offset = Vector2(
		rect.position.x + rect.size.x * 0.5 - 64.0,
		rect.position.y + rect.size.y * 0.5 - 127.0
	)

func grid_world_position() -> Vector2:
	return position - _sort_shift

func _face_sort_offset() -> Vector2:
	match cliff_frame:
		CliffFrame.N, CliffFrame.NE, CliffFrame.NW:
			return Vector2(0.0, (128.0 - DungeonGrid.CLIFF_GRASS_MARGIN) - DungeonGrid.SPRITE_TOP)
		_:
			return Vector2.ZERO

func _apply_sort_shift() -> void:
	var want: Vector2 = _face_sort_offset()
	var delta: Vector2 = want - _sort_shift
	if delta != Vector2.ZERO:
		position += delta
		_sort_shift = want
	var counter: Vector2 = -_sort_shift
	if sprite_2d:
		sprite_2d.position = counter
	if grass_sprite:
		grass_sprite.position = counter
	if stone_b:
		stone_b.position = counter
	if _resolve_static_body():
		static_body.position = counter

func _update_collision() -> void:
	if collision_a == null:
		return
	var grass: float = DungeonGrid.CLIFF_GRASS_MARGIN
	match cliff_frame:
		CliffFrame.N:
			_set_rect(collision_a, 0.0, 0.0, 128.0, 128.0 - grass)
			_disable(collision_b)
		CliffFrame.E:
			_set_rect(collision_a, grass, 0.0, 128.0, 128.0)
			_disable(collision_b)
		CliffFrame.S:
			_set_rect(collision_a, 0.0, grass, 128.0, 128.0)
			_disable(collision_b)
		CliffFrame.W:
			_set_rect(collision_a, 0.0, 0.0, 128.0 - grass, 128.0)
			_disable(collision_b)
		CliffFrame.NW:
			_set_rect(collision_a, 0.0, 0.0, 128.0, 128.0 - grass)
			_set_rect(collision_b, 0.0, 0.0, 128.0 - grass, 128.0)
		CliffFrame.NE:
			_set_rect(collision_a, 0.0, 0.0, 128.0, 128.0 - grass)
			_set_rect(collision_b, grass, 0.0, 128.0, 128.0)
		CliffFrame.SW:
			_set_rect(collision_a, 0.0, grass, 128.0, 128.0)
			_set_rect(collision_b, 0.0, 0.0, 128.0 - grass, 128.0)
		CliffFrame.SE:
			_set_rect(collision_a, 0.0, grass, 128.0, 128.0)
			_set_rect(collision_b, grass, 0.0, 128.0, 128.0)
		CliffFrame.VOID:
			_set_rect(collision_a, 0.0, 0.0, 128.0, 128.0)
			_disable(collision_b)
		_:
			_set_rect(collision_a, 0.0, 0.0, 128.0, 128.0 - grass)
			_disable(collision_b)

func _set_rect(node: CollisionShape2D, tx0: float, ty0: float, tx1: float, ty1: float) -> void:
	node.rotation_degrees = 0.0
	node.position = Vector2((tx0 + tx1) * 0.5 - 64.0, (ty0 + ty1) * 0.5 - 127.0)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(tx1 - tx0, ty1 - ty0)
	node.shape = shape
	node.disabled = false

func _disable(node: CollisionShape2D) -> void:
	if node:
		node.disabled = true

func _ensure_unique_texture() -> void:
	if not _resolve_nodes():
		return
	_unique_atlas(sprite_2d, "cliff_owner_id")
	_unique_atlas(grass_sprite, "cliff_grass_owner_id")
	_unique_atlas(stone_b, "cliff_stone_b_owner_id")

func _unique_atlas(sprite: Sprite2D, meta_key: String) -> void:
	if sprite == null or not (sprite.texture is AtlasTexture):
		return
	var owner_id := get_instance_id()
	if sprite.texture.get_meta(meta_key, -1) == owner_id:
		return
	var unique_texture = sprite.texture.duplicate(true) as AtlasTexture
	unique_texture.resource_local_to_scene = true
	unique_texture.set_meta(meta_key, owner_id)
	sprite.texture = unique_texture

func _resolve_static_body() -> bool:
	if static_body == null:
		static_body = get_node_or_null("StaticBody")
	return static_body != null

func _resolve_nodes() -> bool:
	if sprite_2d == null:
		sprite_2d = get_node_or_null("Sprite2D")
	if grass_sprite == null:
		grass_sprite = get_node_or_null("Grass")
	if stone_b == null:
		stone_b = get_node_or_null("Sprite2DStoneB")
	_resolve_static_body()
	if collision_a == null:
		collision_a = get_node_or_null("StaticBody/CollisionShape2D")
	if collision_b == null:
		collision_b = get_node_or_null("StaticBody/CollisionShape2D2")
	return sprite_2d != null
