@tool
class_name OutsideTile extends Node2D

const FLOOR_Z_INDEX := -1
const SPRITE_GRID_Y := -63.0
const CELL_SIZE := 128

enum GroundKind { GRASS, DIRT }
enum ElementPresentation { NEUTRAL, REALITY, FANTASY }

const _GRASS_STRIPS: Array[Texture2D] = [
	preload("res://sprites/outside_grass_neutral.png"),
	preload("res://sprites/outside_grass_reality.png"),
	preload("res://sprites/outside_grass_fantasy.png"),
]
const _DIRT_STRIPS: Array[Texture2D] = [
	preload("res://sprites/outside_dirt_neutral.png"),
	preload("res://sprites/outside_dirt_reality.png"),
	preload("res://sprites/outside_dirt_fantasy.png"),
]

@export var ground_kind: GroundKind = GroundKind.GRASS: set = _set_ground_kind
@export var variety: int = 0: set = _set_variety
@export var element_presentation: ElementPresentation = ElementPresentation.NEUTRAL: set = _set_element_presentation
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

func _set_element_presentation(value: ElementPresentation) -> void:
	element_presentation = value
	if is_inside_tree():
		_update_visual()

func atlas_frame() -> int:
	return clampi(variety, 0, OutsideCatalog.VARIETY_COUNT - 1)

func strip_texture() -> Texture2D:
	return strip_for(element_presentation)

func strip_for(presentation: ElementPresentation) -> Texture2D:
	var pres: int = clampi(int(presentation), 0, 2)
	if ground_kind == GroundKind.DIRT:
		return _DIRT_STRIPS[pres]
	return _GRASS_STRIPS[pres]

func has_presentation_strip(presentation: ElementPresentation) -> bool:
	return strip_for(presentation) != null

func _update_visual() -> void:
	if not _resolve_sprite():
		return
	_ensure_unique_texture()
	if sprite_2d.texture is AtlasTexture:
		var atlas := sprite_2d.texture as AtlasTexture
		var strip: Texture2D = strip_texture()
		if strip != null and atlas.atlas != strip:
			atlas.atlas = strip
		atlas.region = Rect2(atlas_frame() * CELL_SIZE, 0, CELL_SIZE, CELL_SIZE)
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
