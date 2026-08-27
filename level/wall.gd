@tool
class_name WallDoodad extends Node2D

const WALL_Z_INDEX := 1

@export var wall_type: int = -1: set = _set_wall_type
@onready var sprite_2d: Sprite2D = $StaticBody/Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $StaticBody/CollisionShape2D
@onready var shadow: Sprite2D = $StaticBody/Shadow

func _enter_tree() -> void:
	z_index = WALL_Z_INDEX
	if Engine.is_editor_hint():
		_ensure_unique_texture()

func _ready() -> void:
	z_index = WALL_Z_INDEX
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
		wall_type = randi_range(0, 9)
	if wall_type == 2: #vertical
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
	(sprite_2d.texture as AtlasTexture).region = Rect2(wall_type * 128, 0, 128, 128)

func _set_wall_type(_value: int) -> void:
	wall_type = _value
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
		push_warning("WallDoodad: generated tile off-grid at %s wall_type=%d (peer=%d)" % [position, wall_type, multiplayer.get_unique_id()])
