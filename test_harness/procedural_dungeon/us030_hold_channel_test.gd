extends Node

const BLANK := "res://pickups/blank_form.tres"
const FILLED := "res://pickups/filled_form.tres"

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.register_player(1, "Paper Pusher")
	PlayerManager.add_item_to_inventory(1, load(BLANK) as ItemData, 1)
	var player: Player = Player.new()
	player.name = "1"
	player.standard_fill_sec = 0.05
	if not player.use_active_slot(0):
		_fail("US-030 T006: hold channel must start")
		return
	player._fill_held = false
	player.tick_fill(0.01)
	if player.is_filling():
		_fail("US-030 T006: releasing hold must cancel")
		return
	if PlayerManager.get_item_count(1, BLANK) != 1:
		_fail("US-030 T006: cancel must keep the blank")
		return
	player._fill_require_hold = true
	if not player.use_active_slot(0):
		_fail("US-030 T006: second start must work")
		return
	player._fill_held = true
	player.tick_fill(0.05)
	if PlayerManager.get_item_count(1, FILLED) != 1:
		_fail("US-030 T006: held channel must complete")
		return
	print("US-030 T006 hold channel test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
