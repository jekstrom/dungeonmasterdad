extends Node

const BLANK := "res://pickups/blank_form.tres"
const TAX := "res://pickups/tax_form.tres"
const WOOD := "res://pickups/wood.tres"

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.register_player(1, "Paper Pusher")
	PlayerManager.add_item_to_inventory(1, load(BLANK) as ItemData, 1)
	PlayerManager.add_item_to_inventory(1, load(TAX) as ItemData, 1)
	PlayerManager.add_item_to_inventory(1, load(WOOD) as ItemData, 1)
	if not PlayerManager.swap_slots(1, 0, 1):
		_fail("US-030 T007: same-row swap must succeed")
		return
	var slots: Array = PlayerManager.get_slots(1)
	if str(slots[0].get("path", "")) != TAX or str(slots[1].get("path", "")) != BLANK:
		_fail("US-030 T007: active 0/1 must swap")
		return
	if PlayerManager.swap_slots(1, 0, 4):
		_fail("US-030 T007: cross-row swap must fail")
		return
	slots = PlayerManager.get_slots(1)
	if str(slots[0].get("path", "")) != TAX or str(slots[4].get("path", "")) != WOOD:
		_fail("US-030 T007: cross-row must leave stacks")
		return
	if not PlayerManager.swap_slots(1, 1, 2):
		_fail("US-030 T007: move into empty active must succeed")
		return
	slots = PlayerManager.get_slots(1)
	if str(slots[2].get("path", "")) != BLANK or str(slots[1].get("path", "")) != "":
		_fail("US-030 T007: blank must move to empty slot 2")
		return
	print("US-030 T007 drag swap test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
