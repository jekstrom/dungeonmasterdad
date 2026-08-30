extends Node

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.register_player(1, "Paper Pusher")
	PlayerManager.add_item_to_inventory(1, load("res://pickups/blank_form.tres") as ItemData, 1)
	PlayerManager.add_item_to_inventory(1, load("res://pickups/wood.tres") as ItemData, 1)
	var player: Player = Player.new()
	player.name = "1"
	player.standard_fill_sec = 0.05
	if player.use_active_slot(1):
		_fail("US-030 T005: empty active slot must no-op")
		return
	if not player.use_active_slot(0):
		_fail("US-030 T005: blank in slot 0 must start use")
		return
	if not player.is_filling():
		_fail("US-030 T005: blank form use must start a fill")
		return
	player.cancel_fill()
	player.try_use_active_slot(0)
	if player.is_filling():
		_fail("US-030: blank hotkey must open a type choice, not start fill")
		return
	if player._form_choice == null:
		_fail("US-030: blank hotkey must show the fill-type dialog")
		return
	player._on_form_fill_chosen("tax")
	if not player.is_filling() or player._fill_type != "tax":
		_fail("US-030: choosing tax must start a tax fill")
		return
	player.cancel_fill()
	if PlayerManager.use_instant_slot(1, 4):
		_fail("US-030 T005: static index must not use")
		return
	if PlayerManager.get_item_count(1, "res://pickups/wood.tres") != 1:
		_fail("US-030 T005: wood must be unchanged")
		return
	PlayerManager.add_item_to_inventory(1, load("res://pickups/paper.tres") as ItemData, 1)
	if not player.use_active_slot(1):
		_fail("US-030 T005: paper in an active slot must create a form")
		return
	if PlayerManager.get_item_count(1, "res://pickups/paper.tres") != 0:
		_fail("US-030 T005: using paper must consume 1 paper")
		return
	if PlayerManager.get_item_count(1, "res://pickups/blank_form.tres") != 2:
		_fail("US-030 T005: using paper must grant a blank form")
		return
	print("US-030 T005 use slot test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
