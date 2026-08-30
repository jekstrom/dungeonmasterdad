extends Node

const BLANK := "res://pickups/blank_form.tres"
const WOOD := "res://pickups/wood.tres"
const FILLED := "res://pickups/filled_form.tres"

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.register_player(1, "Paper Pusher")
	PlayerManager.add_item_to_inventory(1, load(WOOD) as ItemData, 1)
	PlayerManager.add_item_to_inventory(1, load(BLANK) as ItemData, 1)
	var slots: Array = PlayerManager.get_slots(1)
	if str(slots[0].get("path", "")) != BLANK or str(slots[4].get("path", "")) != WOOD:
		_fail("US-030 independent: items must split by row")
		return
	var player: Player = Player.new()
	player.name = "1"
	player.standard_fill_sec = 0.05
	player.use_active_slot(0)
	player._fill_held = true
	player.tick_fill(0.05)
	if PlayerManager.get_item_count(1, FILLED) != 1:
		_fail("US-030 independent: held fill must complete")
		return
	PlayerManager.add_item_to_inventory(1, load(BLANK) as ItemData, 1)
	if not PlayerManager.swap_slots(1, 0, 2):
		_fail("US-030 independent: active swap must work")
		return
	if PlayerManager.swap_slots(1, 2, 4):
		_fail("US-030 independent: cross-row swap must fail")
		return
	print("US-030 independent test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
