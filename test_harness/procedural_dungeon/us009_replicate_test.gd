extends Node

const PAPER := "res://pickups/paper.tres"
const BLANK := "res://pickups/blank_form.tres"
const IRS_ID := "res://buildings/buildables/Irs.tres"

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.max_inv_slots = 8
	PlayerManager.reality_level = 0
	PlayerManager.register_player(1, "Paper Pusher")
	var paper: ItemData = load(PAPER) as ItemData
	PlayerManager.add_item_to_inventory(1, paper, 1)
	PlayerManager.create_form(1)
	if PlayerManager.get_item_count(1, BLANK) != 1:
		_fail("US-009 T007: host inventory must hold the blank form")
		return

	var player: Player = Player.new()
	player.name = "1"
	player.standard_fill_sec = 0.05
	player.begin_fill("standard")
	player.tick_fill(0.05)
	if PlayerManager.reality_level != PlayerManager.standard_form_rl:
		_fail("US-009 T007: host Reality must match the standard grant")
		return

	if PlayerManager.create_form(99):
		_fail("US-009 T007: unknown peer must not create a form")
		return

	if not multiplayer.is_server():
		_fail("US-009 T007: headless peer must be server")
		return

	var data: BuildingData = load(IRS_ID) as BuildingData
	if data == null or not data.unique_building:
		_fail("US-009 T007: IRS BuildingData must be unique")
		return

	print("US-009 T007 replicate test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
