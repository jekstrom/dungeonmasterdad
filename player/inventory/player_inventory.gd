class_name InventoryData extends Resource

@export var slots: Array[SlotData]

func _init() -> void:
	connect_slots()
	SignalBus.inventory_updated.connect(on_inventory_changed)
	
func on_inventory_changed(items):
	# {"data": resource, "quantity": quantity}
	print ("on inventory changed - ", items.size())
	for i in slots.size():
		slots[i] = null
	SignalBus.inventory_slots_changed.emit()

	for item_qty in items:
		add_item(item_qty["data"], item_qty["quantity"])

func add_item(_item: ItemData, _quantity: int = 1) -> bool:
	print("adding " + _item.name + " with qty " + str(_quantity))

	for i in slots.size():
		if !slots[i]:
			var new = SlotData.new()
			new.item_data = _item
			new.quantity = _quantity
			new.changed.connect(slot_changed)
			slots[i] = new
			SignalBus.inventory_slots_changed.emit()
			return true
		elif slots[i].item_data.name == _item.name:
			slots[i].quantity = _quantity
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

# =============================================================================
# DEATH SYSTEM INTEGRATION - Item Extraction for Dropping
# =============================================================================

func extract_all_items_for_death() -> Array:
	"""Extract all inventory items for dropping on death"""
	var extracted_items: Array = []
	
	for i in range(slots.size()):
		if slots[i] != null and slots[i].item_data != null and slots[i].quantity > 0:
			# Create dropped item data
			var dropped_item_data = {
				"network_id": "death_item_" + str(i) + "_" + str(Time.get_ticks_msec()),
				"item_type": slots[i].item_data.resource_path.get_file().get_basename(),
				"quantity": slots[i].quantity,
				"properties": {
					"resource_path": slots[i].item_data.resource_path,
					"original_slot": i
				}
			}
			extracted_items.append(dropped_item_data)
			
			# Clear the slot
			if slots[i].changed.is_connected(slot_changed):
				slots[i].changed.disconnect(slot_changed)
			slots[i] = null
	
	# Emit inventory changed signal
	SignalBus.inventory_slots_changed.emit()
	
	print("InventoryData: Extracted ", extracted_items.size(), " items for death drop")
	return extracted_items

func extract_all_items_for_death_with_manager_sync(player_id: int) -> Array:
	"""Extract all inventory items for dropping on death AND sync with PlayerManager"""
	var extracted_items = extract_all_items_for_death()
	
	# Clear PlayerManager inventory for this player (only if we have access to the PlayerManager)
	if PlayerManager and PlayerManager.players_data.has(player_id):
		var player_data = PlayerManager.players_data[player_id]
		if player_data.has("inventory"):
			player_data["inventory"].clear()
			# Update client to reflect empty inventory
			PlayerManager.update_client_inventory.rpc_id(player_id, player_data["inventory"])
			print("InventoryData: Cleared PlayerManager inventory for player ", player_id)
	
	return extracted_items

func get_items_count() -> int:
	"""Get total number of items in inventory"""
	var count = 0
	for slot in slots:
		if slot != null and slot.item_data != null and slot.quantity > 0:
			count += 1
	return count

func is_inventory_empty() -> bool:
	"""Check if inventory has no items"""
	return get_items_count() == 0

func get_inventory_value() -> float:
	"""Get total value of items in inventory (for future balancing)"""
	var total_value = 0.0
	for slot in slots:
		if slot != null and slot.item_data != null and slot.quantity > 0:
			# For now, assume all items have value 1.0
			# This could be enhanced with ItemData.value property later
			total_value += slot.quantity * 1.0
	return total_value
	
