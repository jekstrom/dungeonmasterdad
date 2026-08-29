@tool
class_name DungeonPortalDoodad extends Node2D

const SPRITE_GRID_Y := -63.0

## When true, y-sorts with walls/actors (entrance). Ground portals stay on the floor layer.
@export var y_sort_with_actors: bool = false

func _enter_tree() -> void:
	y_sort_enabled = true
	_apply_sort()
	_apply_sprite()

func _ready() -> void:
	y_sort_enabled = true
	_apply_sort()
	_apply_sprite()

func _apply_sort() -> void:
	if y_sort_with_actors:
		z_index = DungeonConstants.WALL_Z_INDEX
	else:
		z_index = DungeonConstants.FLOOR_Z_INDEX

func _apply_sprite() -> void:
	var sprite: Sprite2D = get_node_or_null("Sprite2D")
	if sprite == null:
		return
	sprite.y_sort_enabled = true
	sprite.position = Vector2(0, SPRITE_GRID_Y)
	sprite.offset = Vector2.ZERO
