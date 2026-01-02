class_name InventoryData extends Resource

@export var slots: Array[SlotData]

func _init() -> void:
	connect_slots()
	SignalBus.inventory_updated.connect(on_inventory_changed)
	
func on_inventory_changed(items):
	# {"data": resource, "quantity": quantity}
	print ("on inventory changed - ", items.size())
	for item_qty in items:
		add_item(item_qty["data"], item_qty["quantity"])

func add_item(_item: ItemData, _quantity: int = 1) -> bool:
	print("adding " + _item.name + " with qty " + str(_quantity))

	for i in slots.size():
		var new = SlotData.new()
		new.item_data = _item
		new.quantity = _quantity
		new.changed.connect(slot_changed)
		slots[i] = new
		SignalBus.inventory_slots_changed.emit()
		return true
			
	print("inventory was full")
	return false
	
func connect_slots() -> void:
	for s in slots:
		if s != null:
			s.changed.connect(slot_changed)
			
func slot_changed() -> void:
	for s in slots:
		if s != null:
			if s.quantity < 1:
				s.changed.disconnect(slot_changed)
				var idx = slots.find(s)
				slots[idx] = null
				emit_changed()
	
func serialize() -> Array:
	var item_save: Array = []
	for i in slots.size():
		item_save.append(serialize_item(slots[i]))
	return item_save
	
func serialize_item(slot: SlotData) -> Dictionary:
	var result = { item = "", quantity = 0, }
	
	if slot != null:
		result.quantity = slot.quantity
		if slot.item_data != null:
			result.item = slot.item_data.resource_path
	
	return result
	
func deserialize(save_data: Array) -> void:
	var array_size = slots.size()
	slots.clear()
	slots.resize(array_size)
	for i in save_data.size():
		slots[i] = deserialize_item(save_data[i])
	connect_slots()

func deserialize_item(slot: Dictionary) -> SlotData:
	if slot.item == "":
		return null
	var new_slot: SlotData = SlotData.new()
	new_slot.item_data = load(slot.item)
	new_slot.quantity = int(slot.quantity)
	return new_slot
	
