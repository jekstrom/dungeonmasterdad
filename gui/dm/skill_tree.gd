extends Control
## US-034: DM Skill Tree UI (UI only). Tabs DM + Dad; 3x3 + ultimate; tooltips;
## locked/unlocked chrome. No spend, unlock RPC, spawn, or passive apply.

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

## Mock chrome (US-034 Open defaults): first column of each row looks unlocked;
## remaining passives + ultimate look locked. Visual only — no spend/gates.
const MOCK_UNLOCKED_PASSIVE_INDICES: Array[int] = [0, 3, 6]

const COLOR_UNLOCKED := Color(0.95, 0.88, 0.45, 1.0)
const COLOR_LOCKED := Color(0.38, 0.38, 0.42, 1.0)
const COLOR_OWNED_EMPHASIS := Color(1.0, 0.95, 0.7, 1.0)

@onready var tab_container: TabContainer = $Panel/Margin/VBox/TabContainer
@onready var dm_grid: GridContainer = $Panel/Margin/VBox/TabContainer/DM/Body/PassivesGrid
@onready var dm_ultimate: Button = $Panel/Margin/VBox/TabContainer/DM/UltimateButton
@onready var dad_grid: GridContainer = $Panel/Margin/VBox/TabContainer/Dad/PassivesGrid
@onready var dad_ultimate: Button = $Panel/Margin/VBox/TabContainer/Dad/UltimateButton
@onready var tooltip_label: Label = $Panel/Margin/VBox/TooltipPanel/TooltipLabel

var _dm_buttons: Array[Button] = []
var _dad_buttons: Array[Button] = []
var _focused_tooltip_text: String = ""


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_dm_tree()
	_build_dad_tree()
	_apply_mock_lock_chrome()
	if tab_container:
		tab_container.set_tab_title(0, "DM")
		tab_container.set_tab_title(1, "Dad")
		tab_container.current_tab = 0
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
	return str(btn.tooltip_text)


func is_button_unlocked_looking(btn: Button) -> bool:
	if btn == null:
		return false
	return bool(btn.get_meta("unlocked_looking", false))


func _build_dm_tree() -> void:
	_clear_children(dm_grid)
	_dm_buttons.clear()
	for i in range(DM_PASSIVES.size()):
		var entry: Dictionary = DM_PASSIVES[i]
		var btn := _make_node_button(str(entry["name"]), str(entry["name"]), str(entry["effect"]), str(entry["id"]))
		dm_grid.add_child(btn)
		_dm_buttons.append(btn)
	_configure_ultimate(dm_ultimate, str(DM_ULTIMATE["name"]), str(DM_ULTIMATE["effect"]), str(DM_ULTIMATE["id"]))


func _build_dad_tree() -> void:
	_clear_children(dad_grid)
	_dad_buttons.clear()
	for i in range(9):
		var pname := "Dad Passive %d" % (i + 1)
		var effect := "Placeholder effect for %s." % pname
		var btn := _make_node_button(pname, pname, effect, "dad_passive_%d" % (i + 1))
		dad_grid.add_child(btn)
		_dad_buttons.append(btn)
	_configure_ultimate(
		dad_ultimate,
		"Dad Ultimate",
		"Placeholder effect for Dad Ultimate.",
		"dad_ultimate"
	)


func _make_node_button(label: String, tip_name: String, tip_effect: String, node_id: String) -> Button:
	var btn := Button.new()
	btn.name = node_id
	btn.text = label
	btn.custom_minimum_size = Vector2(120, 48)
	btn.focus_mode = Control.FOCUS_ALL
	btn.tooltip_text = "%s\n%s" % [tip_name, tip_effect]
	btn.set_meta("skill_id", node_id)
	btn.set_meta("skill_name", tip_name)
	btn.set_meta("skill_effect", tip_effect)
	btn.pressed.connect(_on_node_pressed.bind(btn))
	btn.mouse_entered.connect(_on_node_hover.bind(btn))
	btn.focus_entered.connect(_on_node_hover.bind(btn))
	return btn


func _configure_ultimate(btn: Button, tip_name: String, tip_effect: String, node_id: String) -> void:
	if btn == null:
		return
	btn.text = tip_name
	btn.focus_mode = Control.FOCUS_ALL
	btn.tooltip_text = "%s\n%s" % [tip_name, tip_effect]
	btn.set_meta("skill_id", node_id)
	btn.set_meta("skill_name", tip_name)
	btn.set_meta("skill_effect", tip_effect)
	# Disconnect prior binds if reconfigured, then connect once.
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
		_set_lock_chrome(_dm_buttons[i], unlocked)
	_set_lock_chrome(dm_ultimate, false)
	for i in range(_dad_buttons.size()):
		var unlocked: bool = i in MOCK_UNLOCKED_PASSIVE_INDICES
		_set_lock_chrome(_dad_buttons[i], unlocked)
	_set_lock_chrome(dad_ultimate, false)


func _set_lock_chrome(btn: Button, unlocked_looking: bool) -> void:
	if btn == null:
		return
	btn.set_meta("unlocked_looking", unlocked_looking)
	# Keep buttons clickable for UI focus only; do not use disabled
	# (disabled suppresses tooltips/hover in some themes).
	if unlocked_looking:
		btn.modulate = COLOR_OWNED_EMPHASIS
		btn.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1))
		btn.add_theme_stylebox_override("normal", _make_style(COLOR_UNLOCKED))
		btn.add_theme_stylebox_override("hover", _make_style(COLOR_UNLOCKED.lightened(0.1)))
		btn.add_theme_stylebox_override("pressed", _make_style(COLOR_UNLOCKED.darkened(0.1)))
	else:
		btn.modulate = Color(0.75, 0.75, 0.8, 1)
		btn.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8, 1))
		btn.add_theme_stylebox_override("normal", _make_style(COLOR_LOCKED))
		btn.add_theme_stylebox_override("hover", _make_style(COLOR_LOCKED.lightened(0.08)))
		btn.add_theme_stylebox_override("pressed", _make_style(COLOR_LOCKED.darkened(0.05)))


func _make_style(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_border_width_all(2)
	sb.border_color = color.darkened(0.25)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb


func _on_node_pressed(_btn: Button) -> void:
	# UI-only: focus / click feedback. No mana, unlock, spawn, or passive apply.
	if _btn:
		_btn.grab_focus()
		_show_tooltip_for(_btn)


func _on_node_hover(btn: Button) -> void:
	_show_tooltip_for(btn)


func _show_tooltip_for(btn: Button) -> void:
	if btn == null:
		return
	_focused_tooltip_text = str(btn.tooltip_text)
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
