extends Node

const METAL := "res://pickups/metal.tres"
const SMOKE_ID := "res://buildings/buildables/SmokeFactory.tres"

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.max_inv_slots = 8
	PlayerManager.reality_level = 0
	var peer_id: int = multiplayer.get_unique_id()
	PlayerManager.register_player(peer_id, "Paper Pusher")

	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	level.add_to_group("level_manager")
	add_child(level)
	await get_tree().process_frame

	var interior := Rect2i(0, 0, 16, 10)
	var dungeon := Rect2i(8, 2, 8, 6)
	level.tree_scatter_density = 0.0
	level.mine_scatter_count = 3
	level.apply_map_interior(interior, dungeon, Vector2i(8, 5))
	await get_tree().process_frame

	var mines_parent: Node = level.get_node_or_null("ScatteredMines")
	if mines_parent == null or mines_parent.get_child_count() < 1:
		_fail("US-007 independent: overworld must contain a mine")
		return
	var mine: MineDoodad = mines_parent.get_child(0) as MineDoodad
	if mine == null:
		_fail("US-007 independent: first scatter child must be a mine")
		return
	if DungeonGrid.from_world(mine.position) == Vector2i(8, 5):
		_fail("US-007 independent: mine must not sit on the dungeon exit")
		return

	var player: Player = Player.new()
	player.name = str(peer_id)
	player.position = mine.global_position
	if not mine.is_harvest_prompt_target(player):
		_fail("US-007 independent: in-range mine must show SPACE")
		return

	for _i in range(4):
		if not mine.apply_harvest_hit(player):
			_fail("US-007 independent: harvest hit failed")
			return
	if PlayerManager.get_item_count(peer_id, METAL) != 1:
		_fail("US-007 independent: four hits must grant 1 iron")
		return
	if mine.is_depleted:
		_fail("US-007 independent: first yield must leave the mine standing")
		return

	for _y in range(2):
		for _h in range(4):
			if not mine.apply_harvest_hit(player):
				_fail("US-007 independent: follow-up harvest failed")
				return
	if PlayerManager.get_item_count(peer_id, METAL) != 3:
		_fail("US-007 independent: three yields must grant 3 iron")
		return

	_free_group_children(level.get_node_or_null("ScatteredTrees"))
	_free_group_children(mines_parent)
	await get_tree().process_frame
	await get_tree().physics_frame

	var reality: RealityZone = load("res://zones/reality_zone.tscn").instantiate()
	add_child(reality)
	await get_tree().process_frame

	var root := Node2D.new()
	root.add_to_group("building_root")
	add_child(root)
	var data: BuildingData = BuildingDatabase.get_building(SMOKE_ID)
	if data == null:
		_fail("US-007 independent: SmokeFactory BuildingData missing")
		return
	var size := Vector2(data.size)
	var legal: Vector2 = _first_clear(size)
	if legal == Vector2.INF:
		_fail("US-007 independent: expected a legal building cell")
		return

	BuildingManager.request_placement(SMOKE_ID, legal, legal)
	await get_tree().process_frame
	if root.get_child_count() != 1:
		_fail("US-007 independent: 3 iron must place a factory")
		return
	if PlayerManager.get_item_count(peer_id, METAL) != 0:
		_fail("US-007 independent: placing must spend 3 iron")
		return

	var metal: ItemData = load(METAL) as ItemData
	PlayerManager.add_item_to_inventory(peer_id, metal, 2)
	var second: Vector2 = _first_clear(size)
	if second == Vector2.INF:
		_fail("US-007 independent: expected a second legal cell for the cheap reject")
		return
	BuildingManager.request_placement(SMOKE_ID, second, second)
	if root.get_child_count() != 1:
		_fail("US-007 independent: 2 iron must not spawn a second building")
		return
	if PlayerManager.get_item_count(peer_id, METAL) != 2:
		_fail("US-007 independent: 2 iron reject must leave metal at 2")
		return

	print("US-007 independent test passed")
	get_tree().quit(0)

func _first_clear(size: Vector2) -> Vector2:
	var zone: Node = get_tree().get_first_node_in_group("RealityZone")
	if zone == null or not ("home_rect" in zone):
		return Vector2.INF
	var home: Rect2i = zone.home_rect
	for y in range(home.position.y, home.end.y):
		for x in range(home.position.x, home.end.x):
			var pos: Vector2 = DungeonGrid.to_world_center(Vector2i(x, y))
			if BuildingManager.is_area_clear(pos, size):
				return pos
	return Vector2.INF

func _free_group_children(parent: Node) -> void:
	if parent == null:
		return
	for child in parent.get_children():
		child.free()

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
