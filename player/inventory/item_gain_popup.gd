class_name ItemGainPopup
extends Sprite2D

const DURATION := 0.5
const RISE_PX := 32.0
const START_Y := -64.0

static func spawn_on(parent: Node2D, tex: Texture2D) -> ItemGainPopup:
	if parent == null or tex == null:
		return null
	if not parent.is_inside_tree():
		return null
	var popup := ItemGainPopup.new()
	popup.texture = tex
	parent.add_child(popup)
	return popup

func _ready() -> void:
	centered = true
	z_index = 40
	z_as_relative = true
	y_sort_enabled = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	position = Vector2(0.0, START_Y)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position:y", START_Y - RISE_PX, DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 0.0, DURATION)
	tw.finished.connect(queue_free)
