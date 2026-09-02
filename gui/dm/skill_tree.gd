extends Control
## US-034: DM Skill Tree UI (UI only). Tabs DM + Dad; 3x3 + ultimate; tooltips;
## locked/available/owned chrome from gui/dm/skill_tree/ art. No spend, unlock RPC,
## spawn, or passive apply.

const ART := "res://gui/dm/skill_tree/"

const TEX_PANEL := ART + "panel_frame.png"
const TEX_TAB_DM_IDLE := ART + "tab_dm_idle.png"
const TEX_TAB_DM_ACTIVE := ART + "tab_dm_active.png"
const TEX_TAB_DAD_IDLE := ART + "tab_dad_idle.png"
const TEX_TAB_DAD_ACTIVE := ART + "tab_dad_active.png"
const TEX_NODE_LOCKED := ART + "node_locked.png"
const TEX_NODE_AVAILABLE := ART + "node_available.png"
const TEX_NODE_OWNED := ART + "node_owned.png"
const TEX_ROW_LIGHTNING := ART + "row_lightning.png"
const TEX_ROW_GREMLINS := ART + "row_gremlins.png"
const TEX_ROW_GOBLINS := ART + "row_goblins.png"
const TEX_TOOLTIP_BG := ART + "tooltip_bg.png"
const TEX_TOOLTIP_ARROW := ART + "tooltip_arrow.png"
const TEX_CONNECTOR_H := ART + "connector_h.png"
const TEX_CONNECTOR_V := ART + "connector_v.png"

const DM_ICON_PATHS: Array[String] = [
	ART + "icon_overcharged.png",
	ART + "icon_spark.png",
	ART + "icon_chain_lightning.png",
	ART + "icon_minions.png",
	ART + "icon_blind_monkeys.png",
	ART + "icon_crib_death.png",
	ART + "icon_challenge_rating.png",
	ART + "icon_plus1_swords.png",
	ART + "icon_random_encounter.png",
]
const DM_ULT_ICON := ART + "icon_tsb.png"
const DAD_ULT_ICON := ART + "icon_dad_ultimate.png"

const DM_PASSIVES: Array[Dictionary] = [
	{"id": "overcharged", "name": "Overcharged", "effect": "Increase distance traveled by knightlings.", "row": "Lightning"},
	{"id": "spark", "name": "Spark", "effect": "Reduces time between knightling attacks.", "row": "Lightning"},
	{"id": "chain_lightning", "name": "Chain Lightning", "effect": "Summon 3 knightlings instead of 1.", "row": "Lightning"},
	{"id": "minions", "name": "Minions", "effect": "Gremlins can carry 1 more item.", "row": "Gremlins"},
	{"id": "blind_one_legged_monkeys", "name": "Blind one-legged monkeys", "effect": "Gremlins turn invisible.", "row": "Gremlins"},
	{"id": "crib_death", "name": "Crib Death", "effect": "Automatically summon 1 gremlin from the dungeon exit every min, but they only live for 15 secs.", "row": "Gremlins"},
	{"id": "challenge_rating", "name": "Challenge Rating", "effect": "Increase goblin hp.", "row": "Goblins"},
	{"id": "plus_one_swords", "name": "+1 Swords", "effect": "Increase goblin atk dmg.", "row": "Goblins"},
	{"id": "random_encounter", "name": "Random Encounter", "effect": "Goblins can now lay traps.", "row": "Goblins"},
]

const DM_ULTIMATE: Dictionary = {
	"id": "tsb",
	"name": "TSB",
	"effect": "Summon the TSB.",
}

## Mock chrome (US-034 Open defaults): first column of each row looks available;
## remaining passives + ultimate look locked. Visual only — no spend/gates.
const MOCK_UNLOCKED_PASSIVE_INDICES: Array[int] = [0, 3, 6]

@onready var tab_container: TabContainer = $Panel/Margin/VBox/TabContainer
@onready var dm_grid: GridContainer = $Panel/Margin/VBox/TabContainer/DM/Body/PassivesGrid
@onready var dm_ultimate: Button = $Panel/Margin/VBox/TabContainer/DM/UltimateButton
@onready var dad_grid: GridContainer = $Panel/Margin/VBox/TabContainer/Dad/PassivesGrid
@onready var dad_ultimate: Button = $Panel/Margin/VBox/TabContainer/Dad/UltimateButton
@onready var tooltip_label: Label = $Panel/Margin/VBox/TooltipPanel/TooltipVBox/TooltipLabel
@onready var tooltip_panel: PanelContainer = $Panel/Margin/VBox/TooltipPanel
@onready var panel: PanelContainer = $Panel
@onready var tab_bar: HBoxContainer = $Panel/Margin/VBox/TabBar
@onready var tab_dm_btn: TextureButton = $Panel/Margin/VBox/TabBar/TabDM
@onready var tab_dad_btn: TextureButton = $Panel/Margin/VBox/TabBar/TabDad

var _dm_buttons: Array[Button] = []
var _dad_buttons: Array[Button] = []
var _focused_tooltip_text: String = ""
var _selected_btn: Button = null
var _tex_locked: Texture2D
var _tex_available: Texture2D
var _tex_owned: Texture2D
var _opaque_frame_cache: Dictionary = {}


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_tex_locked = load(TEX_NODE_LOCKED) as Texture2D
	_tex_available = load(TEX_NODE_AVAILABLE) as Texture2D
	_tex_owned = load(TEX_NODE_OWNED) as Texture2D
	_apply_panel_art()
	_apply_tooltip_art()
	_wire_custom_tabs()
	_build_dm_tree()
	_build_dad_tree()
	_apply_mock_lock_chrome()
	if tab_container:
		tab_container.set_tab_title(0, "DM")
		tab_container.set_tab_title(1, "Dad")
		tab_container.tabs_visible = false
		tab_container.current_tab = 0
		if not tab_container.tab_changed.is_connected(_on_tab_changed):
			tab_container.tab_changed.connect(_on_tab_changed)
	_refresh_tab_art()
	var dim := get_node_or_null("Dim")
	if dim and dim is ColorRect:
		if not dim.gui_input.is_connected(_on_dim_gui_input):
			dim.gui_input.connect(_on_dim_gui_input)
	_clear_tooltip()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		visible = false
		_clear_tooltip()
		get_viewport().set_input_as_handled()


func open_panel() -> void:
	visible = true
	if tab_container:
		tab_container.current_tab = 0
	_refresh_tab_art()


func close_panel() -> void:
	visible = false
	_clear_tooltip()


func toggle_panel() -> void:
	if visible:
		close_panel()
	else:
		open_panel()


func get_dm_passive_names() -> Array[String]:
	var names: Array[String] = []
	for entry in DM_PASSIVES:
		names.append(str(entry["name"]))
	return names


func get_dm_ultimate_name() -> String:
	return str(DM_ULTIMATE["name"])


func get_dad_passive_names() -> Array[String]:
	var names: Array[String] = []
	for i in range(9):
		names.append("Dad Passive %d" % (i + 1))
	return names


func get_dad_ultimate_name() -> String:
	return "Dad Ultimate"


func get_all_node_buttons() -> Array[Button]:
	var out: Array[Button] = []
	out.append_array(_dm_buttons)
	if dm_ultimate:
		out.append(dm_ultimate)
	out.append_array(_dad_buttons)
	if dad_ultimate:
		out.append(dad_ultimate)
	return out


func select_tab(tab_name: String) -> void:
	if tab_container == null:
		return
	if tab_name == "DM":
		tab_container.current_tab = 0
	elif tab_name == "Dad":
		tab_container.current_tab = 1
	_refresh_tab_art()


func current_tab_name() -> String:
	if tab_container == null:
		return ""
	if tab_container.current_tab == 0:
		return "DM"
	if tab_container.current_tab == 1:
		return "Dad"
	return ""


func tooltip_for_button(btn: Button) -> String:
	if btn == null:
		return ""
	if btn.has_meta("tooltip_copy"):
		return str(btn.get_meta("tooltip_copy"))
	var tip_name := str(btn.get_meta("skill_name", ""))
	var tip_effect := str(btn.get_meta("skill_effect", ""))
	if tip_name.is_empty() and tip_effect.is_empty():
		return ""
	return "%s\n%s" % [tip_name, tip_effect]


func is_button_unlocked_looking(btn: Button) -> bool:
	if btn == null:
		return false
	return bool(btn.get_meta("unlocked_looking", false))


func _apply_panel_art() -> void:
	if panel == null:
		return
	var tex := load(TEX_PANEL) as Texture2D
	if tex == null:
		return
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = 24
	sb.texture_margin_top = 24
	sb.texture_margin_right = 24
	sb.texture_margin_bottom = 24
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(480, 448)


func _apply_tooltip_art() -> void:
	if tooltip_panel == null:
		return
	var tex := load(TEX_TOOLTIP_BG) as Texture2D
	if tex == null:
		return
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = 8
	sb.texture_margin_top = 8
	sb.texture_margin_right = 8
	sb.texture_margin_bottom = 8
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	tooltip_panel.add_theme_stylebox_override("panel", sb)
	var arrow := tooltip_panel.get_node_or_null("TooltipVBox/TooltipArrow") as TextureRect
	if arrow:
		arrow.texture = load(TEX_TOOLTIP_ARROW) as Texture2D


func _wire_custom_tabs() -> void:
	if tab_dm_btn:
		tab_dm_btn.focus_mode = Control.FOCUS_NONE
		tab_dm_btn.tooltip_text = ""
		if not tab_dm_btn.pressed.is_connected(_on_tab_dm_pressed):
			tab_dm_btn.pressed.connect(_on_tab_dm_pressed)
	if tab_dad_btn:
		tab_dad_btn.focus_mode = Control.FOCUS_NONE
		tab_dad_btn.tooltip_text = ""
		if not tab_dad_btn.pressed.is_connected(_on_tab_dad_pressed):
			tab_dad_btn.pressed.connect(_on_tab_dad_pressed)


func _on_tab_dm_pressed() -> void:
	select_tab("DM")


func _on_tab_dad_pressed() -> void:
	select_tab("Dad")


func _on_tab_changed(_idx: int) -> void:
	_refresh_tab_art()


func _refresh_tab_art() -> void:
	var on_dm := current_tab_name() == "DM"
	if tab_dm_btn:
		tab_dm_btn.texture_normal = load(TEX_TAB_DM_ACTIVE if on_dm else TEX_TAB_DM_IDLE) as Texture2D
	if tab_dad_btn:
		tab_dad_btn.texture_normal = load(TEX_TAB_DAD_ACTIVE if not on_dm else TEX_TAB_DAD_IDLE) as Texture2D


func _build_dm_tree() -> void:
	_clear_children(dm_grid)
	_dm_buttons.clear()
	for i in range(DM_PASSIVES.size()):
		var entry: Dictionary = DM_PASSIVES[i]
		var btn := _make_node_button(
			str(entry["name"]),
			str(entry["name"]),
			str(entry["effect"]),
			str(entry["id"]),
			DM_ICON_PATHS[i]
		)
		dm_grid.add_child(btn)
		_dm_buttons.append(btn)
		# Optional horizontal connectors between columns (visual only).
		if i % 3 != 2:
			pass
	_configure_ultimate(
		dm_ultimate,
		str(DM_ULTIMATE["name"]),
		str(DM_ULTIMATE["effect"]),
		str(DM_ULTIMATE["id"]),
		DM_ULT_ICON
	)


func _build_dad_tree() -> void:
	_clear_children(dad_grid)
	_dad_buttons.clear()
	for i in range(9):
		var pname := "Dad Passive %d" % (i + 1)
		var effect := "Placeholder effect for %s." % pname
		var icon_path := ART + "icon_dad_passive_%02d.png" % (i + 1)
		var btn := _make_node_button(pname, pname, effect, "dad_passive_%d" % (i + 1), icon_path)
		dad_grid.add_child(btn)
		_dad_buttons.append(btn)
	_configure_ultimate(
		dad_ultimate,
		"Dad Ultimate",
		"Placeholder effect for Dad Ultimate.",
		"dad_ultimate",
		DAD_ULT_ICON
	)


func _make_node_button(
	label: String,
	tip_name: String,
	tip_effect: String,
	node_id: String,
	icon_path: String
) -> Button:
	var btn := Button.new()
	btn.name = node_id
	btn.text = label
	btn.custom_minimum_size = Vector2(128, 56)
	btn.focus_mode = Control.FOCUS_ALL
	# Bottom TooltipPanel only — no Control/cursor native tooltip.
	btn.tooltip_text = ""
	btn.expand_icon = true
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var icon_tex := load(icon_path) as Texture2D
	if icon_tex:
		btn.icon = icon_tex
	btn.set_meta("skill_id", node_id)
	btn.set_meta("skill_name", tip_name)
	btn.set_meta("skill_effect", tip_effect)
	btn.set_meta("tooltip_copy", "%s\n%s" % [tip_name, tip_effect])
	btn.pressed.connect(_on_node_pressed.bind(btn))
	btn.mouse_entered.connect(_on_node_hover.bind(btn))
	btn.focus_entered.connect(_on_node_hover.bind(btn))
	return btn


func _configure_ultimate(
	btn: Button,
	tip_name: String,
	tip_effect: String,
	node_id: String,
	icon_path: String
) -> void:
	if btn == null:
		return
	btn.text = tip_name
	btn.focus_mode = Control.FOCUS_ALL
	# Bottom TooltipPanel only — no Control/cursor native tooltip.
	btn.tooltip_text = ""
	btn.expand_icon = true
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var icon_tex := load(icon_path) as Texture2D
	if icon_tex:
		btn.icon = icon_tex
	btn.set_meta("skill_id", node_id)
	btn.set_meta("skill_name", tip_name)
	btn.set_meta("skill_effect", tip_effect)
	btn.set_meta("tooltip_copy", "%s\n%s" % [tip_name, tip_effect])
	for conn in btn.pressed.get_connections():
		btn.pressed.disconnect(conn["callable"])
	for conn in btn.mouse_entered.get_connections():
		btn.mouse_entered.disconnect(conn["callable"])
	for conn in btn.focus_entered.get_connections():
		btn.focus_entered.disconnect(conn["callable"])
	btn.pressed.connect(_on_node_pressed.bind(btn))
	btn.mouse_entered.connect(_on_node_hover.bind(btn))
	btn.focus_entered.connect(_on_node_hover.bind(btn))


func _apply_mock_lock_chrome() -> void:
	for i in range(_dm_buttons.size()):
		var unlocked: bool = i in MOCK_UNLOCKED_PASSIVE_INDICES
		_set_lock_chrome(_dm_buttons[i], unlocked, false)
	_set_lock_chrome(dm_ultimate, false, false)
	for i in range(_dad_buttons.size()):
		var unlocked: bool = i in MOCK_UNLOCKED_PASSIVE_INDICES
		_set_lock_chrome(_dad_buttons[i], unlocked, false)
	_set_lock_chrome(dad_ultimate, false, false)


func _set_lock_chrome(btn: Button, unlocked_looking: bool, owned_looking: bool) -> void:
	if btn == null:
		return
	btn.set_meta("unlocked_looking", unlocked_looking)
	btn.set_meta("owned_looking", owned_looking)
	# Keep buttons clickable for UI focus only; do not use disabled
	# (disabled suppresses tooltips/hover in some themes).
	var frame: Texture2D = _tex_locked
	if owned_looking:
		frame = _tex_owned
	elif unlocked_looking:
		frame = _tex_available
	var sb := _make_texture_style(frame)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus", sb)
	# Never use modulate alpha for lock state — keeps faces opaque.
	btn.modulate = Color(1, 1, 1, 1)
	if unlocked_looking or owned_looking:
		btn.add_theme_color_override("font_color", Color(0.95, 0.92, 0.75, 1))
	else:
		btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1))


## available/owned frames are hollow chrome; bake an opaque fill under the rim
## so StyleBoxTexture button faces are solid without inventing new art.
func _opaque_node_frame(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	var key: String = tex.resource_path if not tex.resource_path.is_empty() else str(tex.get_instance_id())
	if _opaque_frame_cache.has(key):
		return _opaque_frame_cache[key] as Texture2D
	var src := tex.get_image()
	if src == null:
		_opaque_frame_cache[key] = tex
		return tex
	var img := src.duplicate()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	# Match locked center chrome (~40,32,28) so hollow frames stay solid.
	var fill := Color(40.0 / 255.0, 32.0 / 255.0, 28.0 / 255.0, 1.0)
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c: Color = img.get_pixel(x, y)
			if c.a < 0.01:
				img.set_pixel(x, y, fill)
	var out := ImageTexture.create_from_image(img)
	_opaque_frame_cache[key] = out
	return out


func _make_texture_style(tex: Texture2D) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	if tex:
		sb.texture = _opaque_node_frame(tex)
	# Border thickness in art is ~12px on 64px frames; keep 9-slice rim intact.
	sb.texture_margin_left = 12
	sb.texture_margin_top = 12
	sb.texture_margin_right = 12
	sb.texture_margin_bottom = 12
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.draw_center = true
	return sb


func _on_node_pressed(_btn: Button) -> void:
	# UI-only: focus / owned chrome feedback. No mana, unlock, spawn, or passive apply.
	if _btn == null:
		return
	_btn.grab_focus()
	_show_tooltip_for(_btn)
	if _selected_btn and _selected_btn != _btn:
		var prev_unlocked: bool = bool(_selected_btn.get_meta("unlocked_looking", false))
		_set_lock_chrome(_selected_btn, prev_unlocked, false)
	_selected_btn = _btn
	var unlocked: bool = bool(_btn.get_meta("unlocked_looking", false))
	_set_lock_chrome(_btn, unlocked, true)


func _on_node_hover(btn: Button) -> void:
	_show_tooltip_for(btn)


func _show_tooltip_for(btn: Button) -> void:
	if btn == null:
		return
	_focused_tooltip_text = tooltip_for_button(btn)
	if tooltip_label:
		tooltip_label.text = _focused_tooltip_text


func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_panel()
		accept_event()


func _clear_tooltip() -> void:
	_focused_tooltip_text = ""
	if tooltip_label:
		tooltip_label.text = ""


func _clear_children(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
