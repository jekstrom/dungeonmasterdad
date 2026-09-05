extends Control

const SHADOW := Color(0.0, 0.0, 0.0, 0.62)
const HAND := Color(0.08, 0.08, 0.08, 0.9)
const TEXT := Color(1.0, 1.0, 1.0, 1.0)

var ability_id: String = ""
var _ratio: float = 0.0
var _remaining: float = 0.0
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	visible = false
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.add_theme_color_override("font_color", TEXT)
	_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	_label.add_theme_constant_override("outline_size", 5)
	_label.add_theme_font_size_override("font_size", 18)
	_label.visible = false
	add_child(_label)


func cooldown_ratio() -> float:
	return _ratio


func cooldown_text() -> String:
	if _label == null:
		return ""
	return _label.text


func _process(_delta: float) -> void:
	var remaining: float = 0.0
	var ratio: float = 0.0
	if not ability_id.is_empty() and DmManager:
		remaining = DmManager.ability_cooldown_remaining(ability_id)
		ratio = DmManager.ability_cooldown_ratio(ability_id)
	_remaining = remaining
	_ratio = ratio
	var active: bool = remaining > 0.0
	visible = active
	if _label:
		if active:
			_label.text = "%.1f" % remaining
		else:
			_label.text = ""
		_label.visible = active
	if active:
		queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if _ratio <= 0.001:
		return
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5
	if radius <= 1.0:
		return
	if _ratio >= 0.999:
		draw_circle(center, radius, SHADOW)
		return
	var start: float = -PI * 0.5
	var sweep: float = -TAU * _ratio
	var steps: int = maxi(8, int(ceil(absf(sweep) / 0.1)))
	var pts := PackedVector2Array()
	pts.append(center)
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var angle: float = start + sweep * t
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	if pts.size() >= 3:
		draw_colored_polygon(pts, SHADOW)
	var hand_end: Vector2 = center + Vector2(cos(start + sweep), sin(start + sweep)) * radius
	draw_line(center, hand_end, HAND, 2.0, true)
