extends Node

const WOOD_PATH := "res://pickups/wood.tres"
const PAPER_PATH := "res://pickups/paper.tres"

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.max_inv_slots = 8
	PlayerManager.smoke_amt = 5
	PlayerManager.reality_level = 0
	PlayerManager.register_player(1, "Paper Pusher")

	var drops: Array = []
	SignalBus.on_item_drop.connect(func(data: Dictionary) -> void:
		drops.append(data)
	)

	var tree: TreeDoodad = load("res://doodads/tree.tscn").instantiate() as TreeDoodad
	tree.tree_type = 2
	tree.position = Vector2(64, 64)
	add_child(tree)

	var player: Player = Player.new()
	player.name = "1"
	player.position = Vector2(64, 64)
	var body := Node2D.new()
	body.name = "1"
	body.add_to_group("players")
	body.position = Vector2(64, 64)
	add_child(body)
	await get_tree().process_frame

	for _i in range(tree.hits_required):
		if not tree.apply_harvest_hit(player):
			_fail("US-006 independent: harvest hit %d failed" % _i)
			return
	if not tree.is_stump:
		_fail("US-006 independent: tree must become a stump")
		return
	var harvested: int = PlayerManager.get_item_count(1, WOOD_PATH)
	if harvested < 3 or harvested > 6:
		_fail("US-006 independent: harvest must grant 3-6 wood, got %d" % harvested)
		return

	var factory: PaperFactory = load("res://buildings/buildables/paper_factory.tscn").instantiate() as PaperFactory
	factory.position = Vector2(64, 64)
	add_child(factory)
	factory.enable()
	factory.is_ghost = false
	factory.set_process(false)
	await get_tree().process_frame
	if not factory.try_deposit_wood(1):
		_fail("US-006 independent: deposit must accept harvested wood")
		return
	if PlayerManager.get_item_count(1, WOOD_PATH) != harvested - 1:
		_fail("US-006 independent: deposit must consume 1 inventory wood")
		return
	if factory.stored_wood != 1:
		_fail("US-006 independent: factory must hold deposited wood")
		return

	var reality_before: int = PlayerManager.reality_level
	var smoke_before: int = PlayerManager.smoke_amt
	factory._process(factory.interval)
	if factory.stored_wood != 0:
		_fail("US-006 independent: production must consume wood")
		return
	if PlayerManager.smoke_amt != smoke_before - factory.smoke_consume_amt:
		_fail("US-006 independent: production must consume smoke")
		return
	if PlayerManager.reality_level != reality_before + 10:
		_fail("US-006 independent: production must raise Reality by 10")
		return
	var saw_paper := false
	for drop in drops:
		if str(drop.get("item_type", "")) == PAPER_PATH:
			saw_paper = true
	if not saw_paper:
		_fail("US-006 independent: factory must emit paper")
		return

	var smoke_mid: int = PlayerManager.smoke_amt
	var reality_mid: int = PlayerManager.reality_level
	factory._process(factory.interval)
	if PlayerManager.smoke_amt != smoke_mid:
		_fail("US-006 independent: empty wood buffer must not spend smoke")
		return
	if PlayerManager.reality_level != reality_mid:
		_fail("US-006 independent: empty wood buffer must not raise Reality")
		return

	print("US-006 independent test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
