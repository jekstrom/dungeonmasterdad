extends Node2D

const BAR_WIDTH: float = 50.0
const BAR_HEIGHT: float = 10.0

@onready var fill: ColorRect = $Fill
@onready var title: Label = $Title

func _ready() -> void:
	set_health_ratio(1.0)

func set_title(text: String) -> void:
	if title == null:
		title = get_node_or_null("Title") as Label
	if title == null:
		return
	title.text = text
	title.visible = not text.is_empty()

func set_health_ratio(ratio: float) -> void:
	var r: float = clampf(ratio, 0.0, 1.0)
	if fill == null:
		fill = get_node_or_null("Fill") as ColorRect
	if fill == null:
		return
	fill.size = Vector2(BAR_WIDTH * r, BAR_HEIGHT)
	fill.position = Vector2(-BAR_WIDTH * 0.5, -BAR_HEIGHT * 0.5)
	fill.color = Color(1.0 - r * 0.7, 0.2 + r * 0.65, 0.12, 1.0)
