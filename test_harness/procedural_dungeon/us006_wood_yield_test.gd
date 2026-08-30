extends Node

const WOOD_PATH := "res://pickups/wood.tres"
const COAL_PATH := "res://pickups/coal.tres"

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.max_inv_slots = 8
	PlayerManager.register_player(1, "Paper Pusher")
	PlayerManager.register_player(2, "Paper Pusher 2")

	var tree: TreeDoodad = _make_tree()
	var player: Player = _make_player("1")
	await get_tree().process_frame
	if tree.harvest_hitbox == null:
		_fail("US-006 T003: tree must have a harvest Hitbox")
		return

	tree.hits_taken = 2
	if not tree.apply_harvest_hit(player):
		_fail("US-006 T003: completing hit must succeed")
		return
	if not tree.is_stump:
		_fail("US-006 T003: completed tree must become a stump")
		return
	if tree.sprite_2d.scale.x >= TreeDoodad.LIVING_SPRITE_SCALE.x - 0.01:
		_fail("US-006 T003: stump must be smaller than the living tree sprite")
		return
	if tree.sprite_2d.texture != TreeDoodad.STUMP_TEXTURE:
		_fail("US-006 T003: stump must use tree_stump.png")
		return
	var first_yield: int = PlayerManager.get_item_count(1, WOOD_PATH)
	if first_yield < 3 or first_yield > 6:
		_fail("US-006 T003: completing harvest must grant 3-6 wood, got %d" % first_yield)
		return
	if tree.apply_harvest_hit(player):
		_fail("US-006 T003: stump must not take further harvest hits")
		return
	if PlayerManager.get_item_count(1, WOOD_PATH) != first_yield:
		_fail("US-006 T003: stump must not grant more wood")
		return

	var drops: Array = []
	SignalBus.on_item_drop.connect(func(data: Dictionary) -> void:
		drops.append(data)
	)
	PlayerManager.players_data.clear()
	PlayerManager.max_inv_slots = 1
	PlayerManager.register_player(1, "Paper Pusher")
	var coal: ItemData = load(COAL_PATH) as ItemData
	if not PlayerManager.add_item_to_inventory(1, coal, 1):
		_fail("US-006 T003: setup coal fill failed")
		return
	var full_tree: TreeDoodad = _make_tree()
	full_tree.hits_taken = 2
	full_tree.apply_harvest_hit(player)
	if PlayerManager.get_item_count(1, WOOD_PATH) != 0:
		_fail("US-006 T003: full unique inventory without wood must not grant to inventory")
		return
	if drops.is_empty() or str(drops[0].get("item_type", "")) != WOOD_PATH:
		_fail("US-006 T003: full inventory must drop wood as a world pickup")
		return

	PlayerManager.players_data.clear()
	PlayerManager.max_inv_slots = 1
	PlayerManager.register_player(1, "Paper Pusher")
	var wood: ItemData = load(WOOD_PATH) as ItemData
	PlayerManager.add_item_to_inventory(1, wood, 1)
	var stack_tree: TreeDoodad = _make_tree()
	stack_tree.hits_taken = 2
	stack_tree.apply_harvest_hit(player)
	var stacked: int = PlayerManager.get_item_count(1, WOOD_PATH)
	if stacked < 4 or stacked > 7:
		_fail("US-006 T003: existing wood stack must grow by 3-6 when slots are full, got %d" % stacked)
		return

	var race: TreeDoodad = _make_tree()
	race.hits_taken = 2
	var p2: Player = _make_player("2")
	PlayerManager.players_data.clear()
	PlayerManager.max_inv_slots = 8
	PlayerManager.register_player(1, "Paper Pusher")
	PlayerManager.register_player(2, "Paper Pusher 2")
	race.apply_harvest_hit(player)
	race.apply_harvest_hit(p2)
	var total_wood: int = PlayerManager.get_item_count(1, WOOD_PATH) + PlayerManager.get_item_count(2, WOOD_PATH)
	if total_wood < 3 or total_wood > 6:
		_fail("US-006 T003: same-frame last hits must yield wood once (3-6), got %d" % total_wood)
		return
	var p1: int = PlayerManager.get_item_count(1, WOOD_PATH)
	var p2_count: int = PlayerManager.get_item_count(2, WOOD_PATH)
	if p1 > 0 and p2_count > 0:
		_fail("US-006 T003: one completing hit must not split wood across both players")
		return

	print("US-006 T003 wood yield test passed")
	get_tree().quit(0)

func _make_tree() -> TreeDoodad:
	var tree: TreeDoodad = load("res://doodads/tree.tscn").instantiate() as TreeDoodad
	tree.tree_type = 1
	add_child(tree)
	return tree

func _make_player(id_name: String) -> Player:
	var player: Player = Player.new()
	player.name = id_name
	return player

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
