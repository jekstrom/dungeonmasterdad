@tool
class_name TreeDoodad extends Node2D

@export var tree_type: int = -1: set = _set_tree_type
@onready var sprite_2d: Sprite2D = $Sprite2D

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		_ensure_unique_texture()

func _ready() -> void:
	_ensure_unique_texture()
	_update_texture()
	if Engine.is_editor_hint(): return
	
func _update_texture() -> void:
	if not _resolve_sprite(): return
	if not sprite_2d.texture is AtlasTexture: return
	if tree_type < 0:
		tree_type = randi_range(0, 9)
	(sprite_2d.texture as AtlasTexture).region = Rect2(tree_type * 32, 0, 32, 32)
	
func _set_tree_type(_value: int) -> void:
	tree_type = _value
	if not is_inside_tree() or not _resolve_sprite():
		if Engine.is_editor_hint():
			call_deferred("_apply_tree_type")
		return
	_apply_tree_type()

func _apply_tree_type() -> void:
	_ensure_unique_texture()
	_update_texture()

func _ensure_unique_texture() -> void:
	if not _resolve_sprite(): return
	if not sprite_2d.texture: return
	if sprite_2d.texture is AtlasTexture:
		var owner_id := get_instance_id()
		var texture_owner_id = sprite_2d.texture.get_meta("tree_owner_id", -1)
		if texture_owner_id != owner_id:
			var unique_texture = sprite_2d.texture.duplicate(true) as AtlasTexture
			unique_texture.resource_local_to_scene = true
			unique_texture.set_meta("tree_owner_id", owner_id)
			sprite_2d.texture = unique_texture

func _resolve_sprite() -> bool:
	if sprite_2d: return true
	sprite_2d = get_node_or_null("Sprite2D")
	return sprite_2d != null
