@tool
class_name OutsideTile extends Node2D

const FLOOR_Z_INDEX := -1
const SPRITE_GRID_Y := -63.0

enum GroundKind { GRASS, DIRT }

@export var ground_kind: GroundKind = GroundKind.GRASS: set = _set_ground_kind
@export var variety: int = 0: set = _set_variety
@onready var sprite_2d: Sprite2D = $Sprite2D

func _enter_tree() -> void:
	z_index = FLOOR_Z_INDEX
	if Engine.is_editor_hint():
		_ensure_unique_texture()

func _ready() -> void:
	z_index = FLOOR_Z_INDEX
	_ensure_unique_texture()
	_update_visual()

func _set_ground_kind(value: GroundKind) -> void:
	ground_kind = value
	if is_inside_tree():
		_update_visual()

func _set_variety(value: int) -> void:
	variety = clampi(value, 0, OutsideCatalog.VARIETY_COUNT - 1)
	if is_inside_tree():
		_update_visual()

func atlas_frame() -> int:
	var kind_offset: int = 0 if ground_kind == GroundKind.GRASS else OutsideCatalog.VARIETY_COUNT
	return kind_offset + clampi(variety, 0, OutsideCatalog.VARIETY_COUNT - 1)

func _update_visual() -> void:
	if not _resolve_sprite():
		return
	_ensure_unique_texture()
	if sprite_2d.texture is AtlasTexture:
		(sprite_2d.texture as AtlasTexture).region = Rect2(atlas_frame() * 128, 0, 128, 128)
	sprite_2d.position = Vector2(0, SPRITE_GRID_Y)

func _ensure_unique_texture() -> void:
	if not _resolve_sprite():
		return
	if not sprite_2d.texture:
		return
	if sprite_2d.texture is AtlasTexture:
		var owner_id := get_instance_id()
		if sprite_2d.texture.get_meta("outside_owner_id", -1) != owner_id:
			var unique_texture = sprite_2d.texture.duplicate(true) as AtlasTexture
			unique_texture.resource_local_to_scene = true
			unique_texture.set_meta("outside_owner_id", owner_id)
			sprite_2d.texture = unique_texture

func _resolve_sprite() -> bool:
	if sprite_2d == null:
		sprite_2d = get_node_or_null("Sprite2D")
	return sprite_2d != null
