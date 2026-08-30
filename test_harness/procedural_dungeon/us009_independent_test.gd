extends Node

const PAPER := "res://pickups/paper.tres"
const BLANK := "res://pickups/blank_form.tres"
const FILLED := "res://pickups/filled_form.tres"
const TAX := "res://pickups/tax_form.tres"
const METAL := "res://pickups/metal.tres"
const IRS_ID := "res://buildings/buildables/Irs.tres"

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.max_inv_slots = 8
	PlayerManager.reality_level = 0
	PlayerManager.standard_form_rl = 15
	PlayerManager.tax_file_rl = 50
	var peer_id: int = multiplayer.get_unique_id()
	PlayerManager.register_player(peer_id, "Paper Pusher")

	var paper: ItemData = load(PAPER) as ItemData
	PlayerManager.add_item_to_inventory(peer_id, paper, 2)
	if not PlayerManager.create_form(peer_id):
		_fail("US-009 independent: first paper must become a blank")
		return

	var player: Player = Player.new()
	player.name = str(peer_id)
	player.standard_fill_sec = 0.05
	player.tax_fill_sec = 0.05
	add_child(player)
	player.set_process(false)
	player.set_physics_process(false)

	player.begin_fill("standard")
	player.tick_fill(0.05)
	if PlayerManager.reality_level != 15:
		_fail("US-009 independent: standard form must grant Reality")
		return
	if PlayerManager.get_item_count(peer_id, FILLED) != 1:
		_fail("US-009 independent: must hold a filled standard form")
		return

	if not PlayerManager.create_form(peer_id):
		_fail("US-009 independent: second paper must become a blank")
		return
	player.begin_fill("tax")
	player.tick_fill(0.05)
	if PlayerManager.reality_level != 15:
		_fail("US-009 independent: tax fill must not raise Reality")
		return
	if PlayerManager.get_item_count(peer_id, TAX) != 1:
		_fail("US-009 independent: must hold a tax form")
		return

	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	level.add_to_group("level_manager")
	add_child(level)
	await get_tree().process_frame
	level.tree_scatter_density = 0.0
	level.apply_map_interior(Rect2i(0, 0, 16, 10), Rect2i(8, 2, 8, 6))
	_free_group_children(level.get_node_or_null("ScatteredTrees"))
	_free_group_children(level.get_node_or_null("ScatteredMines"))
	await get_tree().process_frame
	await get_tree().physics_frame
	var reality: RealityZone = load("res://zones/reality_zone.tscn").instantiate()
	add_child(reality)
	await get_tree().process_frame
	var root := Node2D.new()
	root.add_to_group("building_root")
	add_child(root)
	var metal: ItemData = load(METAL) as ItemData
	PlayerManager.add_item_to_inventory(peer_id, metal, 3)
	var data: BuildingData = BuildingDatabase.get_building(IRS_ID)
	var size := Vector2(data.size)
	var legal: Vector2 = _first_clear(size)
	if legal == Vector2.INF:
		_fail("US-009 independent: expected a legal IRS cell")
		return
	BuildingManager.request_placement(IRS_ID, legal, legal)
	await get_tree().process_frame
	if root.get_child_count() != 1:
		_fail("US-009 independent: IRS must place")
		return

	player.position = legal
	var irs: IrsBuilding = root.get_child(0) as IrsBuilding
	if not irs.try_file_tax(peer_id):
		_fail("US-009 independent: filing must succeed")
		return
	if PlayerManager.get_item_count(peer_id, TAX) != 0:
		_fail("US-009 independent: tax form must be consumed")
		return
	if PlayerManager.reality_level != 65:
		_fail("US-009 independent: Reality should be 15+50, got %d" % PlayerManager.reality_level)
		return
	if PlayerManager.tax_file_rl <= PlayerManager.PAPER_FACTORY_RL:
		_fail("US-009 independent: tax file must beat a paper cycle")
		return

	print("US-009 independent test passed")
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
