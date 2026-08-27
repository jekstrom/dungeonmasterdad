@tool
class_name WallDoodad extends Node2D

const WALL_Z_INDEX := 0

# wall_type is the collider: 1 = horizontal, 2 = vertical (generator contract).
# wall_frame is the atlas index from cubicle_stone_wall.png. 4 is shadow-only.
@export var wall_type: int = -1: set = _set_wall_type
@export var wall_frame: int = -1: set = _set_wall_frame
@onready var sprite_2d: Sprite2D = $StaticBody/Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $StaticBody/CollisionShape2D
@onready var shadow: Sprite2D = $StaticBody/Shadow

func _enter_tree() -> void:
	z_index = WALL_Z_INDEX
	y_sort_enabled = true
	if Engine.is_editor_hint():
		_ensure_unique_texture()

func _ready() -> void:
	z_index = WALL_Z_INDEX
	y_sort_enabled = true
	_ensure_unique_texture()
	_update_texture()
	if Engine.is_editor_hint():
		return
	_smoke_generated_tile()

func _update_texture() -> void:
	if not _resolve_sprite():
		return
	if not sprite_2d.texture is AtlasTexture:
		return
	if wall_type < 0:
		wall_type = 1
	var vertical: bool = wall_type == 2
	if vertical:
		collision_shape_2d.position = Vector2(32, -64)
		collision_shape_2d.rotation_degrees = 90.0
		var shape = RectangleShape2D.new()
		shape.size = Vector2(128, 64)
		collision_shape_2d.shape = shape
		if shadow:
			shadow.visible = false
	else:
		collision_shape_2d.position = Vector2(0, -16)
		collision_shape_2d.rotation_degrees = 0.0
		var shape = RectangleShape2D.new()
		shape.size = Vector2(128, 32)
		collision_shape_2d.shape = shape
		if shadow:
			shadow.visible = true
	var frame: int = _resolved_frame()
	(sprite_2d.texture as AtlasTexture).region = Rect2(frame * 128, 0, 128, 128)

func _resolved_frame() -> int:
	var frame: int = wall_frame
	if frame == 4:
		frame = 0
	if frame < 0:
		# Playground instances: type 2 is the vertical collider. Frame 1 is
		# V middle. Generated walls always set wall_frame.
		if wall_type == 2:
			frame = 1
		else:
			frame = 0
	return clampi(frame, 0, 14)

func _set_wall_type(_value: int) -> void:
	wall_type = _value
	if not is_inside_tree() or not _resolve_sprite():
		if Engine.is_editor_hint():
			call_deferred("_apply_wall_type")
		return
	_apply_wall_type()

func _set_wall_frame(_value: int) -> void:
	wall_frame = _value
	if not is_inside_tree() or not _resolve_sprite():
		if Engine.is_editor_hint():
			call_deferred("_apply_wall_type")
		return
	_apply_wall_type()

func _apply_wall_type() -> void:
	_ensure_unique_texture()
	_update_texture()

func _ensure_unique_texture() -> void:
	if not _resolve_sprite():
		return
	if not sprite_2d.texture:
		return
	if sprite_2d.texture is AtlasTexture:
		var owner_id := get_instance_id()
		var texture_owner_id = sprite_2d.texture.get_meta("wall_owner_id", -1)
		if texture_owner_id != owner_id:
			var unique_texture = sprite_2d.texture.duplicate(true) as AtlasTexture
			unique_texture.resource_local_to_scene = true
			unique_texture.set_meta("wall_owner_id", owner_id)
			sprite_2d.texture = unique_texture

func _resolve_sprite() -> bool:
	if sprite_2d:
		return true
	sprite_2d = get_node_or_null("Sprite2D")
	if sprite_2d:
		return true
	sprite_2d = get_node_or_null("StaticBody/Sprite2D")
	if sprite_2d and not collision_shape_2d:
		collision_shape_2d = get_node_or_null("StaticBody/CollisionShape2D")
	if sprite_2d and not shadow:
		shadow = get_node_or_null("StaticBody/Shadow")
	return sprite_2d != null

func _smoke_generated_tile() -> void:
	if not is_in_group("generated_dungeon_tiles"):
		return
	var px := int(round(position.x))
	var py := int(round(position.y))
	if px % 128 != 0 or py % 128 != 0:
		push_warning("WallDoodad: generated tile off-grid at %s wall_type=%d wall_frame=%d (peer=%d)" % [position, wall_type, wall_frame, multiplayer.get_unique_id()])
