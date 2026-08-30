class_name InventoryUi extends GridContainer

const INVENTORY_SLOT = preload("res://player/inventory/inventory_slot.tscn")
const SLOT_COUNT := 8

var focus_index: int = 0

@export var data: InventoryData

func _ready() -> void:
	columns = 4
	mouse_filter = Control.MOUSE_FILTER_STOP
	if data and data.slots.size() < SLOT_COUNT:
		data.slots.resize(SLOT_COUNT)
	_ensure_cells()
	_apply_slots(PlayerManager.local_slots)
	if not SignalBus.inventory_slots_changed.is_connected(on_inventory_changed):
		SignalBus.inventory_slots_changed.connect(on_inventory_changed)

func _ensure_cells() -> void:
	while get_child_count() < SLOT_COUNT:
		var cell: InventorySlotUi = INVENTORY_SLOT.instantiate() as InventorySlotUi
		add_child(cell)
	for i in SLOT_COUNT:
		var cell: InventorySlotUi = get_child(i) as InventorySlotUi
		if cell:
			cell.slot_index = i
			cell.focus_mode = Control.FOCUS_NONE

func clear_inventory() -> void:
	for i in get_child_count():
		var cell: InventorySlotUi = get_child(i) as InventorySlotUi
		if cell:
			cell.slot_data = null

func update_inventory() -> void:
	_ensure_cells()
	_apply_slots(PlayerManager.local_slots)

func on_inventory_changed() -> void:
	update_inventory()

func _apply_slots(raw_slots: Array) -> void:
	_ensure_cells()
	for i in SLOT_COUNT:
		var cell: InventorySlotUi = get_child(i) as InventorySlotUi
		if cell == null:
			continue
		cell.slot_index = i
		var entry: Dictionary = {}
		if i < raw_slots.size() and typeof(raw_slots[i]) == TYPE_DICTIONARY:
			entry = raw_slots[i]
		var path := str(entry.get("path", ""))
		var qty := int(entry.get("qty", 0))
		if path.is_empty() or qty <= 0:
			cell.slot_data = null
			continue
		var item: ItemData = ItemDatabase.get_item(path)
		if item == null:
			cell.slot_data = null
			continue
		var slot := SlotData.new()
		slot.item_data = item
		slot.quantity = qty
		cell.slot_data = slot

func item_focus() -> void:
	for i in get_child_count():
		if get_child(i).has_focus():
			focus_index = i
			return
