class_name FormFillChoice
extends CanvasLayer

signal chosen(kind: String)

const STANDARD_TEX: Texture2D = preload("res://pickups/forms/filled_form.png")
const TAX_TEX: Texture2D = preload("res://pickups/forms/tax_form.png")

func _ready() -> void:
	layer = 200
	_build()

func _build() -> void:
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_input)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -170.0
	panel.offset_top = -90.0
	panel.offset_right = 170.0
	panel.offset_bottom = 90.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Fill form"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 1, 0.75, 1))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title.add_theme_constant_override("outline_size", 6)
	box.add_child(title)

	var hint := Label.new()
	hint.text = "Choose a type"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
	box.add_child(hint)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)
	row.add_child(_make_choice_button("Standard", STANDARD_TEX, "standard"))
	row.add_child(_make_choice_button("Tax", TAX_TEX, "tax"))

func _make_choice_button(caption: String, tex: Texture2D, kind: String) -> Button:
	var btn := Button.new()
	btn.text = caption
	btn.icon = tex
	btn.expand_icon = true
	btn.custom_minimum_size = Vector2(150, 56)
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(func() -> void:
		chosen.emit(kind)
	)
	return btn

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		chosen.emit("")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		chosen.emit("")
		get_viewport().set_input_as_handled()
