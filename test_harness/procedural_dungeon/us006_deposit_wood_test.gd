extends Node

const WOOD_PATH := "res://pickups/wood.tres"

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.register_player(1, "Paper Pusher")
	var wood: ItemData = load(WOOD_PATH) as ItemData
	PlayerManager.add_item_to_inventory(1, wood, 2)

	var player := Node2D.new()
	player.name = "1"
	player.add_to_group("players")
	player.position = Vector2(0, 0)
	add_child(player)

	var factory: PaperFactory = load("res://buildings/buildables/paper_factory.tscn").instantiate() as PaperFactory
	factory.position = Vector2(0, 0)
	add_child(factory)
	await get_tree().process_frame
	if factory.try_deposit_wood(1):
		_fail("US-006 T005: ghost factory must not accept wood")
		return

	factory.enable()
	factory.is_ghost = false
	if not factory.can_prompt_deposit(player):
		_fail("US-006 T005: in-range factory with wood must prompt E interact")
		return
	if not factory.try_deposit_wood(1):
		_fail("US-006 T005: in-range deposit must succeed")
		return
	if factory.stored_wood != 1:
		_fail("US-006 T005: stored_wood must be 1 after deposit, got %d" % factory.stored_wood)
		return
	if PlayerManager.get_item_count(1, WOOD_PATH) != 1:
		_fail("US-006 T005: inventory wood must decrease by 1")
		return

	player.position = Vector2(400, 400)
	if factory.in_interact_range(player):
		_fail("US-006 T005: out of range factory must not prompt E")
		return
	if factory.try_deposit_wood(1):
		_fail("US-006 T005: out of range deposit must fail")
		return
	if factory.stored_wood != 1 or PlayerManager.get_item_count(1, WOOD_PATH) != 1:
		_fail("US-006 T005: out of range must not change wood")
		return

	player.position = Vector2.ZERO
	PlayerManager.consume_resources(1, WOOD_PATH, 1)
	if factory.try_deposit_wood(1):
		_fail("US-006 T005: deposit with no wood must fail")
		return
	if factory.stored_wood != 1:
		_fail("US-006 T005: empty inventory must leave stored_wood unchanged")
		return
	if factory.can_prompt_deposit(player):
		_fail("US-006 T005: no wood must not prompt E")
		return

	PlayerManager.players_data.clear()
	PlayerManager.register_player(1, "Paper Pusher")
	PlayerManager.add_item_to_inventory(1, wood, 6)
	factory.stored_wood = 0
	for i in range(5):
		if not factory.try_deposit_wood(1):
			_fail("US-006 T005: factory must accept 5 wood into the buffer, failed at %d" % (i + 1))
			return
	if factory.stored_wood != 5:
		_fail("US-006 T005: wood buffer cap is 5, got %d" % factory.stored_wood)
		return
	if factory.can_prompt_deposit(player):
		_fail("US-006 T005: full buffer must not prompt E")
		return
	if factory.try_deposit_wood(1):
		_fail("US-006 T005: sixth wood must be rejected at cap 5")
		return
	if PlayerManager.get_item_count(1, WOOD_PATH) != 1:
		_fail("US-006 T005: rejected deposit must leave leftover wood in inventory")
		return

	print("US-006 T005 deposit wood test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
