@tool
class_name DungeonPortalDoodad extends Node2D

const SPRITE_GRID_Y := -63.0

func _enter_tree() -> void:
	y_sort_enabled = true
	z_index = DungeonConstants.WALL_Z_INDEX
	_apply_sprite()

func _ready() -> void:
	y_sort_enabled = true
	z_index = DungeonConstants.WALL_Z_INDEX
	_apply_sprite()

func _apply_sprite() -> void:
	var sprite: Sprite2D = get_node_or_null("Sprite2D")
	if sprite == null:
		return
	sprite.y_sort_enabled = true
	sprite.position = Vector2(0, SPRITE_GRID_Y)
