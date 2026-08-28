@tool
class_name FloorDoodad extends Node2D

const FLOOR_Z_INDEX := -1

@export var floor_type: int = -1: set = _set_floor_type
@onready var sprite_2d: Sprite2D = $Sprite2D

func _enter_tree() -> void:
	z_index = FLOOR_Z_INDEX
	if Engine.is_editor_hint():
		_ensure_unique_texture()

func _ready() -> void:
	z_index = FLOOR_Z_INDEX
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
	(sprite_2d.texture as AtlasTexture).region = Rect2(_visual_frame() * 128, 0, 128, 128)


func _visual_frame() -> int:
	# 4x4 megatile sliced from a 512px seamless floor. Grid placement
	# reconstructs it so adjacent cells do not share one repeating stamp.
	var gx := int(round(position.x / 128.0))
	var gy := int(round(position.y / 128.0))
	if absf(position.x - float(gx * 128)) < 1.0 and absf(position.y - float(gy * 128)) < 1.0:
		return posmod(gx, 4) + posmod(gy, 4) * 4
	if floor_type < 0:
		return randi_range(0, 15)
	return clampi(floor_type, 0, 15)

func _set_floor_type(_value: int) -> void:
	floor_type = _value
	if not is_inside_tree() or not _resolve_sprite():
		if Engine.is_editor_hint():
			call_deferred("_apply_floor_type")
		return
	_apply_floor_type()

func _apply_floor_type() -> void:
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
	return sprite_2d != null

func _smoke_generated_tile() -> void:
	if not is_in_group("generated_dungeon_tiles"):
		return
	var px := int(round(position.x))
	var py := int(round(position.y))
	if px % 128 != 0 or py % 128 != 0:
		push_warning("FloorDoodad: generated tile off-grid at %s (peer=%d)" % [position, multiplayer.get_unique_id()])
