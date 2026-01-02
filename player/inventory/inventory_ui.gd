class_name InventoryUi extends GridContainer

const INVENTORY_SLOT = preload("res://player/inventory/inventory_slot.tscn")

var focus_index: int = 0

@export var data: InventoryData

func _ready() -> void:
	#PauseMenu.shown.connect(update_inventory)
	#PauseMenu.hidden.connect(clear_inventory)
	data.slots.resize(PlayerManager.max_inv_slots)

	update_inventory()
	
	SignalBus.inventory_slots_changed.connect(on_inventory_changed)
	
func clear_inventory() -> void:
	for c in get_children():
		c.queue_free()

func update_inventory() -> void:
	if data.slots.size() > 0:
		for s in data.slots:
			var new_slot = INVENTORY_SLOT.instantiate()
			add_child(new_slot)
			new_slot.slot_data = s
			new_slot.focus_entered.connect(item_focus)
			
		await get_tree().process_frame
		#get_child(focus_index).grab_focus()

func on_inventory_changed() -> void:
	clear_inventory()
	update_inventory()
	
func item_focus() -> void:
	for i in get_child_count():
		if get_child(i).has_focus():
			focus_index = i
			return
