extends Node

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.register_player(1, "Paper Pusher")

	var tree: TreeDoodad = load("res://doodads/tree.tscn").instantiate() as TreeDoodad
	tree.tree_type = 0
	tree.position = DungeonGrid.to_world_center(Vector2i(1, 1))
	add_child(tree)

	var player: Player = Player.new()
	player.name = "1"
	player.position = DungeonGrid.to_world_center(Vector2i(1, 1))

	var fantasy: FantasyZone = load("res://zones/fantasy_zone.tscn").instantiate()
	add_child(fantasy)
	await get_tree().process_frame
	fantasy.home_rect = Rect2i(0, 0, 4, 4)

	if tree.apply_harvest_hit(player):
		_fail("US-006 T004: player inside Fantasy must not harvest")
		return
	if tree.hits_taken != 0:
		_fail("US-006 T004: Fantasy player swing must leave hits_taken at 0")
		return

	player.position = DungeonGrid.to_world_center(Vector2i(10, 10))
	if tree.apply_harvest_hit(player):
		_fail("US-006 T004: tree inside Fantasy must not be harvestable")
		return

	fantasy.home_rect = Rect2i()
	fantasy.claim.home_rect = Rect2i()
	tree.position = DungeonGrid.to_world_center(Vector2i(8, 8))
	player.position = DungeonGrid.to_world_center(Vector2i(8, 8))

	var dm: DM = DM.new()
	dm.position = player.position
	if tree.apply_harvest_hit(dm):
		_fail("US-006 T004: DM must not harvest")
		return

	var root := Node2D.new()
	root.add_to_group("building_root")
	add_child(root)
	var factory: PaperFactory = load("res://buildings/buildables/paper_factory.tscn").instantiate() as PaperFactory
	factory.position = tree.position
	factory.is_ghost = false
	root.add_child(factory)
	await get_tree().process_frame
	if tree.apply_harvest_hit(player):
		_fail("US-006 T004: tree under an enabled building must not harvest")
		return

	factory.is_ghost = true
	if not tree.apply_harvest_hit(player):
		_fail("US-006 T004: ghost building must not lock harvest")
		return
	if tree.hits_taken != 1:
		_fail("US-006 T004: legal Reality harvest must still apply a hit")
		return

	print("US-006 T004 harvest lockout test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
