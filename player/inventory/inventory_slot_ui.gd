class_name InventorySlotUi extends Button

const ACTIVE_BG := Color(0.22, 0.28, 0.38, 1)
const STATIC_BG := Color(0.36, 0.28, 0.18, 1)
const SLOT_ACTIONS := ["inv_slot_0", "inv_slot_1", "inv_slot_2", "inv_slot_3"]

var slot_index: int = 0
var slot_data: SlotData: set = set_slot_data

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
	_apply_row_chrome()
	pressed.connect(item_pressed)

func is_active_cell() -> bool:
	return slot_index >= 0 and slot_index < 4

func _apply_row_chrome() -> void:
	if bg:
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
