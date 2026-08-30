extends Node

const BLANK := "res://pickups/blank_form.tres"
const FILLED := "res://pickups/filled_form.tres"
const TAX := "res://pickups/tax_form.tres"

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.max_inv_slots = 8
	PlayerManager.reality_level = 0
	PlayerManager.standard_form_rl = 5
	PlayerManager.tax_file_rl = 10
	PlayerManager.register_player(1, "Paper Pusher")
	var blank: ItemData = load(BLANK) as ItemData
	PlayerManager.add_item_to_inventory(1, blank, 2)

	var player: Player = Player.new()
	player.name = "1"
	player.standard_fill_sec = 0.05
	player.tax_fill_sec = 0.05

	player.begin_fill("standard")
	player.tick_fill(0.05)
	if PlayerManager.reality_level != 5:
		_fail("US-009 T004: standard fill must grant +5 Reality, got %d" % PlayerManager.reality_level)
		return
	if PlayerManager.get_item_count(1, FILLED) != 1:
		_fail("US-009 T004: standard fill must leave a filled form")
		return

	var rl: int = PlayerManager.reality_level
	player.begin_fill("tax")
	player.tick_fill(0.05)
	if PlayerManager.reality_level != rl:
		_fail("US-009 T004: tax fill must not change Reality")
		return
	if PlayerManager.get_item_count(1, TAX) != 1:
		_fail("US-009 T004: tax fill must grant a tax form")
		return

	print("US-009 T004 fill outcomes test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
