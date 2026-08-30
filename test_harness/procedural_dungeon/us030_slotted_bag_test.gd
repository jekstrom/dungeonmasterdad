extends Node

const WOOD := "res://pickups/wood.tres"
const BLANK := "res://pickups/blank_form.tres"
const METAL := "res://pickups/metal.tres"
const TAX := "res://pickups/tax_form.tres"
const FILLED := "res://pickups/filled_form.tres"
const CLOAK := "res://pickups/cloak.tres"

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.max_inv_slots = 8
	PlayerManager.register_player(1, "Paper Pusher")
	var wood: ItemData = load(WOOD) as ItemData
	var blank: ItemData = load(BLANK) as ItemData
	if not PlayerManager.add_item_to_inventory(1, wood, 1):
		_fail("US-030 T002: wood must add")
		return
	if not PlayerManager.add_item_to_inventory(1, blank, 1):
		_fail("US-030 T002: blank must add")
		return
	var slots: Array = PlayerManager.get_slots(1)
	if str(slots[4].get("path", "")) != WOOD:
		_fail("US-030 T002: wood must land in a static cell")
		return
	if str(slots[0].get("path", "")) != BLANK:
		_fail("US-030 T002: blank must land in an active cell")
		return
	if PlayerManager.get_item_count(1, WOOD) != 1:
		_fail("US-030 T002: path count must stay 1")
		return
	PlayerManager.add_item_to_inventory(1, wood, 1)
	if int(PlayerManager.get_slots(1)[4].get("qty", 0)) != 2:
		_fail("US-030 T002: wood must stack in one static cell")
		return
	if not PlayerManager.has_resources(1, METAL, 1):
		PlayerManager.add_item_to_inventory(1, load(METAL) as ItemData, 1)
	if not PlayerManager.has_resources(1, METAL, 1):
		_fail("US-030 T002: has_resources must see static metal")
		return
	PlayerManager.consume_resources(1, METAL, 1)
	if PlayerManager.get_item_count(1, METAL) != 0:
		_fail("US-030 T002: consume must clear metal")
		return

	PlayerManager.add_item_to_inventory(1, load(TAX) as ItemData, 1)
	PlayerManager.add_item_to_inventory(1, load(FILLED) as ItemData, 1)
	PlayerManager.add_item_to_inventory(1, load(CLOAK) as ItemData, 1)
	if PlayerManager.add_item_to_inventory(1, load("res://pickups/d6.tres") as ItemData, 1):
		_fail("US-030 T002: fifth unique active must fail")
		return

	print("US-030 T002 slotted bag test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
