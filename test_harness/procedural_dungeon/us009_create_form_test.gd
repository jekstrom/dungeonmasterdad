extends Node

const PAPER := "res://pickups/paper.tres"
const BLANK := "res://pickups/blank_form.tres"
const COAL := "res://pickups/coal.tres"

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.max_inv_slots = 8
	PlayerManager.register_player(1, "Paper Pusher")
	var paper: ItemData = load(PAPER) as ItemData
	PlayerManager.add_item_to_inventory(1, paper, 1)
	if not PlayerManager.create_form(1):
		_fail("US-009 T002: create_form must succeed with paper")
		return
	if PlayerManager.get_item_count(1, PAPER) != 0:
		_fail("US-009 T002: paper must be consumed")
		return
	if PlayerManager.get_item_count(1, BLANK) != 1:
		_fail("US-009 T002: blank form must be granted")
		return
	if PlayerManager.create_form(1):
		_fail("US-009 T002: create_form must fail with 0 paper")
		return
	if PlayerManager.get_item_count(1, BLANK) != 1:
		_fail("US-009 T002: failed create must not change blanks")
		return

	var drops: Array = []
	SignalBus.on_item_drop.connect(func(data: Dictionary) -> void:
		drops.append(data)
	)
	PlayerManager.players_data.clear()
	PlayerManager.max_inv_slots = 1
	PlayerManager.register_player(1, "Paper Pusher")
	var coal: ItemData = load(COAL) as ItemData
	PlayerManager.add_item_to_inventory(1, coal, 1)
	PlayerManager.players_data[1]["inventory"][PAPER] = 1
	if not PlayerManager.create_form(1):
		_fail("US-009 T002: overflow create must still consume paper")
		return
	if PlayerManager.get_item_count(1, PAPER) != 0:
		_fail("US-009 T002: overflow must consume paper")
		return
	if PlayerManager.get_item_count(1, BLANK) != 0:
		_fail("US-009 T002: full unique inventory must drop the blank")
		return
	if drops.is_empty() or str(drops[0].get("item_type", "")) != BLANK:
		_fail("US-009 T002: full inventory must drop blank_form.tres")
		return

	print("US-009 T002 create form test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
