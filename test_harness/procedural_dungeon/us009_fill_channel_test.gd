extends Node

const BLANK := "res://pickups/blank_form.tres"
const FILLED := "res://pickups/filled_form.tres"
const TAX := "res://pickups/tax_form.tres"

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.max_inv_slots = 8
	PlayerManager.reality_level = 0
	PlayerManager.register_player(1, "Paper Pusher")
	var blank: ItemData = load(BLANK) as ItemData
	PlayerManager.add_item_to_inventory(1, blank, 2)

	var player: Player = Player.new()
	player.name = "1"
	player.standard_fill_sec = 0.05
	player.tax_fill_sec = 0.08

	if not player.begin_fill("standard"):
		_fail("US-009 T003: standard fill must start")
		return
	player.tick_fill(0.02)
	if PlayerManager.get_item_count(1, BLANK) != 2:
		_fail("US-009 T003: in-progress fill must keep the blank")
		return
	player.tick_fill(0.05)
	if PlayerManager.get_item_count(1, BLANK) != 1:
		_fail("US-009 T003: completed standard fill must consume one blank")
		return
	if PlayerManager.get_item_count(1, FILLED) != 1:
		_fail("US-009 T003: standard fill must grant a filled form")
		return
	player._complete_fill(player._fill_token)
	if PlayerManager.get_item_count(1, FILLED) != 1:
		_fail("US-009 T003: double complete must not grant a second form")
		return

	if not player.begin_fill("tax"):
		_fail("US-009 T003: tax fill must start")
		return
	player.tick_fill(player.tax_fill_sec)
	if PlayerManager.get_item_count(1, TAX) != 1:
		_fail("US-009 T003: tax fill must grant a tax form")
		return

	PlayerManager.add_item_to_inventory(1, blank, 1)
	if not player.begin_fill("standard"):
		_fail("US-009 T003: interrupt fill must start")
		return
	player.position = Vector2(40, 0)
	player.tick_fill(0.01)
	if player.is_filling():
		_fail("US-009 T003: moving must cancel fill")
		return
	if PlayerManager.get_item_count(1, BLANK) < 1:
		_fail("US-009 T003: cancelled fill must keep the blank")
		return

	if not player.begin_fill("standard"):
		_fail("US-009 T003: damage-cancel fill must start")
		return
	player.cancel_fill()
	if player.is_filling():
		_fail("US-009 T003: damage/cancel must stop fill")
		return

	print("US-009 T003 fill channel test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
