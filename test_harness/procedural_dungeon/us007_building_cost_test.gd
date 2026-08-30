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
	level.apply_map_interior(interior, dungeon)
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
	var data: BuildingData = BuildingDatabase.get_building(SMOKE_ID)
	if data == null:
		_fail("US-007 T007: BuildingDatabase must load SmokeFactory.tres")
		return
	var size := Vector2(data.size)
	var legal: Vector2 = _first_clear(size)
	if legal == Vector2.INF:
		_fail("US-007 T007: expected a legal Reality outside cell")
		return

	PlayerManager.add_item_to_inventory(peer_id, metal, 2)
	BuildingManager.request_placement(SMOKE_ID, legal, legal)
	if root.get_child_count() != 0:
		_fail("US-007 T007: 2 metal must not spawn a building")
		return
	if PlayerManager.get_item_count(peer_id, METAL) != 2:
		_fail("US-007 T007: rejected cheap place must leave metal at 2")
		return

	PlayerManager.add_item_to_inventory(peer_id, metal, 1)
	var blocked: Vector2 = DungeonGrid.to_world_center(dungeon.position)
	BuildingManager.request_placement(SMOKE_ID, blocked, blocked)
	if root.get_child_count() != 0:
		_fail("US-007 T007: blocked footprint must not spawn a building")
		return
	if PlayerManager.get_item_count(peer_id, METAL) != 3:
		_fail("US-007 T007: blocked footprint must not spend metal")
		return

	BuildingManager.request_placement(SMOKE_ID, legal, legal)
	await get_tree().process_frame
	if root.get_child_count() != 1:
		_fail("US-007 T007: 3 metal on a legal cell must spawn a building")
		return
	if PlayerManager.get_item_count(peer_id, METAL) != 0:
		_fail("US-007 T007: legal place must consume 3 metal")
		return
	var placed: Node = root.get_child(0)
	if placed is Building and (placed as Building).is_ghost:
		_fail("US-007 T007: placed factory must be enabled")
		return

	print("US-007 T007 building cost test passed")
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
