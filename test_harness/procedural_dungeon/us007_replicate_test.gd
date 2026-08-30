extends Node

const METAL := "res://pickups/metal.tres"

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.max_inv_slots = 8
	PlayerManager.register_player(1, "Paper Pusher")

	var host := Node2D.new()
	host.set_script(load("res://_globals/level_manager.gd"))
	add_child(host)
	await get_tree().process_frame

	var interior := Rect2i(0, 0, 16, 10)
	var dungeon := Rect2i(8, 2, 8, 6)
	var exit_cell := Vector2i(8, 5)
	host.tree_scatter_density = 0.0
	host.mine_scatter_count = 3
	host.apply_map_interior(interior, dungeon, exit_cell)
	await get_tree().process_frame

	var parent: Node = host.get_node_or_null("ScatteredMines")
	if parent == null or parent.get_child_count() < 1:
		_fail("US-007 T008: host must scatter mines")
		return
	var first: MineDoodad = parent.get_child(0) as MineDoodad
	if first == null:
		_fail("US-007 T008: scattered child must be MineDoodad")
		return
	first.apply_replicated_mine_state(2, 4, true)
	if not first.is_depleted or first.hits_taken != 2 or first.yields_taken != 4:
		_fail("US-007 T008: host mine state must stick")
		return

	var payload: Dictionary = host.build_map_sync_payload()
	var mines: Array = payload.get("mines", [])
	if mines.is_empty():
		_fail("US-007 T008: map payload must include mines")
		return
	var found_depleted := false
	for item in mines:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		if int(item.get("d", 0)) == 1:
			found_depleted = true
			if int(item.get("h", 0)) != 2 or int(item.get("ylds", 0)) != 4:
				_fail("US-007 T008: depleted payload must include hits and yields")
				return
	if not found_depleted:
		_fail("US-007 T008: map payload must include depleted mine state")
		return

	var joiner := Node2D.new()
	joiner.set_script(load("res://_globals/level_manager.gd"))
	add_child(joiner)
	await get_tree().process_frame
	joiner.apply_map_sync_payload(payload)
	await get_tree().process_frame

	var join_parent: Node = joiner.get_node_or_null("ScatteredMines")
	if join_parent == null:
		_fail("US-007 T008: joiner missing ScatteredMines")
		return
	if join_parent.get_child_count() != parent.get_child_count():
		_fail("US-007 T008: late join must receive the same mine count")
		return
	var joiner_depleted: MineDoodad = null
	for child in join_parent.get_children():
		if child is MineDoodad and (child as MineDoodad).is_depleted:
			joiner_depleted = child as MineDoodad
	if joiner_depleted == null:
		_fail("US-007 T008: late join must see the depleted mine")
		return
	if joiner_depleted.hits_taken != 2 or joiner_depleted.yields_taken != 4:
		_fail("US-007 T008: late join must see leftover hits and yields")
		return

	var host_hits: int = first.hits_taken
	joiner_depleted.hits_taken = 99
	if first.hits_taken != host_hits:
		_fail("US-007 T008: client hits_taken write must not change the host mine")
		return

	var metal: ItemData = load(METAL) as ItemData
	if not PlayerManager.add_item_to_inventory(1, metal, 3):
		_fail("US-007 T008: host must grant metal to inventory")
		return
	if PlayerManager.get_item_count(1, METAL) != 3:
		_fail("US-007 T008: owner metal count must match host")
		return
	if PlayerManager.add_item_to_inventory(99, metal, 1):
		_fail("US-007 T008: unknown peer must not receive metal")
		return

	print("US-007 T008 replicate test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
