class_name InventorySlotUi extends Button

const ACTIVE_BG := Color(0.22, 0.28, 0.38, 1)
const STATIC_BG := Color(0.36, 0.28, 0.18, 1)
const LOCKED_BG := Color(0.18, 0.18, 0.2, 1)
const LOCKED_TINT := Color(0.45, 0.48, 0.52, 1)
const SLOT_ACTIONS := ["inv_slot_0", "inv_slot_1", "inv_slot_2", "inv_slot_3"]
const THERMOSTAT_ICON := preload("res://gui/dm/skill_tree/icon_thermostat_lock.png")

var slot_index: int = 0
var slot_data: SlotData: set = set_slot_data
var _locked: bool = false
var _lock_dim: ColorRect
var _lock_icon: TextureRect

@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label
@onready var hotkey: Label = $Hotkey
@onready var bg: ColorRect = $Bg

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	if texture_rect:
		texture_rect.texture = null
	if label:
		label.text = ""
	_ensure_lock_overlay()
	_apply_row_chrome()
	_apply_lock_chrome()
	pressed.connect(item_pressed)


func is_locked() -> bool:
	return _locked


func set_locked(locked: bool) -> void:
	_locked = locked
	_apply_lock_chrome()

func is_active_cell() -> bool:
	return slot_index >= 0 and slot_index < 4

func _ensure_lock_overlay() -> void:
	_lock_dim = get_node_or_null("LockDim") as ColorRect
	if _lock_dim == null:
		_lock_dim = ColorRect.new()
		_lock_dim.name = "LockDim"
		_lock_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_lock_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_lock_dim.color = Color(0.08, 0.08, 0.1, 0.72)
		add_child(_lock_dim)
	_lock_icon = get_node_or_null("LockIcon") as TextureRect
	if _lock_icon == null:
		_lock_icon = TextureRect.new()
		_lock_icon.name = "LockIcon"
		_lock_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_lock_icon.offset_left = 8.0
		_lock_icon.offset_top = 8.0
		_lock_icon.offset_right = -8.0
		_lock_icon.offset_bottom = -8.0
		_lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_lock_icon.texture = THERMOSTAT_ICON
		add_child(_lock_icon)
	_lock_dim.visible = false
	_lock_icon.visible = false


func _apply_lock_chrome() -> void:
	_ensure_lock_overlay()
	disabled = _locked
	modulate = Color.WHITE
	if texture_rect:
		texture_rect.modulate = LOCKED_TINT if _locked else Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_IGNORE if _locked else Control.MOUSE_FILTER_STOP
	if bg:
		if _locked:
			bg.color = LOCKED_BG
		else:
			bg.color = ACTIVE_BG if is_active_cell() else STATIC_BG
	if _lock_dim:
		_lock_dim.visible = _locked
	if _lock_icon:
		_lock_icon.visible = _locked
		_lock_icon.texture = THERMOSTAT_ICON


func _apply_row_chrome() -> void:
	if bg and not _locked:
		bg.color = ACTIVE_BG if is_active_cell() else STATIC_BG
	if hotkey:
		if is_active_cell():
			hotkey.visible = true
			hotkey.text = _action_key_label(SLOT_ACTIONS[slot_index])
		else:
			hotkey.visible = false
			hotkey.text = ""

func _action_key_label(action: String) -> String:
	if not InputMap.has_action(action):
		return ["Q", "E", "R", "T"][slot_index] if is_active_cell() else ""
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	for event in events:
		if event is InputEventKey:
			var key: InputEventKey = event
			var code: int = key.physical_keycode if key.physical_keycode != 0 else key.keycode
			return OS.get_keycode_string(code)
	return ["Q", "E", "R", "T"][slot_index] if is_active_cell() else ""

func set_slot_data(value: SlotData) -> void:
	slot_data = value
	_apply_row_chrome()
	if texture_rect == null:
		texture_rect = get_node_or_null("TextureRect")
	if label == null:
		label = get_node_or_null("Label")
	if slot_data == null or slot_data.item_data == null or slot_data.quantity < 1:
		if texture_rect:
			texture_rect.texture = null
		if label:
			label.text = ""
		return
	if texture_rect:
		texture_rect.texture = slot_data.item_data.texture
	if label:
		label.text = str(slot_data.quantity) if slot_data.quantity > 1 else ""

func item_pressed() -> void:
	if _locked:
		return
	if not is_active_cell():
		return
	if slot_data == null or slot_data.item_data == null:
		return
	var players := get_tree().get_nodes_in_group("players") if get_tree() else []
	for node in players:
		if node is Player and (node as Player).is_multiplayer_authority():
			(node as Player).try_use_active_slot(slot_index)
			return

func _get_drag_data(_at_position: Vector2) -> Variant:
	if _locked:
		return null
	if slot_data == null or slot_data.item_data == null:
		return null
	var preview := TextureRect.new()
	preview.texture = slot_data.item_data.texture
	preview.custom_minimum_size = Vector2(32, 32)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)
	return {"from": slot_index}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if not data.has("from"):
		return false
	var from_i: int = int(data.get("from", -1))
	if from_i < 0:
		return false
	var local_id: int = 1
	if multiplayer.has_multiplayer_peer():
		local_id = multiplayer.get_unique_id()
	if not PlayerManager.is_slot_usable(local_id, from_i) or not PlayerManager.is_slot_usable(local_id, slot_index):
		return false
	var from_row: int = 0 if from_i < 4 else 1
	var to_row: int = 0 if slot_index < 4 else 1
	return from_row == to_row

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		return
	var from_i: int = int(data.get("from", -1))
	if from_i == slot_index:
		return
	if multiplayer.is_server():
		var pid: int = multiplayer.get_unique_id()
		PlayerManager.swap_slots(pid, from_i, slot_index)
	else:
		PlayerManager.request_swap_slots.rpc_id(1, from_i, slot_index)
