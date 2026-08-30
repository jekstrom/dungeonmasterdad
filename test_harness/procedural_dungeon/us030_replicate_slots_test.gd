extends Node

const BLANK := "res://pickups/blank_form.tres"
const WOOD := "res://pickups/wood.tres"

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.register_player(1, "Paper Pusher")
	PlayerManager.register_player(2, "Other")
	PlayerManager.add_item_to_inventory(1, load(WOOD) as ItemData, 1)
	PlayerManager.add_item_to_inventory(1, load(BLANK) as ItemData, 1)
	PlayerManager.swap_slots(1, 0, 2)
	var slots: Array = PlayerManager.get_slots(1)
	if str(slots[2].get("path", "")) != BLANK:
		_fail("US-030 T008: snapshot must keep blank in slot 2")
		return
	if PlayerManager.swap_slots(2, 2, 0):
		pass
	if str(PlayerManager.get_slots(1)[2].get("path", "")) != BLANK:
		_fail("US-030 T008: peer 2 must not steal peer 1 slots")
		return
	# swap_slots(2,...) is allowed on host API with player_id 2 (empty). Foreign RPC is owner-checked.
	if not PlayerManager.swap_slots(1, 2, 0):
		_fail("US-030 T008: owner swap must still work")
		return
	print("US-030 T008 replicate slots test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
