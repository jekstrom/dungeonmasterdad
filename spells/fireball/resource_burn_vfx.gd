extends Node2D

const FRAME_COUNT: int = 17
const PLAY_SEC: float = 0.4
const SCALE := Vector2(0.4, 0.4)

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if sprite == null:
		queue_free()
		return
	sprite.frame = 0
	sprite.scale = SCALE
	var tween := create_tween()
	tween.tween_method(_set_frame, 0.0, float(FRAME_COUNT - 1), PLAY_SEC)
	tween.tween_callback(queue_free)


func _set_frame(value: float) -> void:
	if sprite:
		sprite.frame = clampi(int(round(value)), 0, FRAME_COUNT - 1)
