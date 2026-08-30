extends Node

func _ready() -> void:
	var host := Node2D.new()
	host.set_script(load("res://_globals/level_manager.gd"))
	add_child(host)
	await get_tree().process_frame

	var interior := Rect2i(0, 0, 16, 10)
	var dungeon := Rect2i(8, 2, 8, 6)
	var exit_cell := Vector2i(8, 5)
	host.tree_scatter_density = 0.08
	host.apply_map_interior(interior, dungeon, exit_cell)
	await get_tree().process_frame

	var parent: Node = host.get_node_or_null("ScatteredTrees")
	if parent == null or parent.get_child_count() == 0:
		_fail("US-006 T007: host must scatter trees")
		return
	var first: TreeDoodad = parent.get_child(0) as TreeDoodad
	if first == null:
		_fail("US-006 T007: scattered child must be TreeDoodad")
		return
	first.apply_replicated_harvest_state(3, true)
	if not first.is_stump:
		_fail("US-006 T007: host stump flag must stick")
		return

	var payload: Dictionary = host.build_map_sync_payload()
	var trees: Array = payload.get("trees", [])
	var found_stump := false
	for item in trees:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		if int(item.get("s", 0)) == 1:
			found_stump = true
			if int(item.get("h", 0)) < 1:
				_fail("US-006 T007: stump payload must include hits")
				return
	if not found_stump:
		_fail("US-006 T007: map payload must include stump state")
		return

	var joiner := Node2D.new()
	joiner.set_script(load("res://_globals/level_manager.gd"))
	add_child(joiner)
	await get_tree().process_frame
	joiner.apply_map_sync_payload(payload)
	await get_tree().process_frame

	var join_parent: Node = joiner.get_node_or_null("ScatteredTrees")
	if join_parent == null:
		_fail("US-006 T007: joiner missing ScatteredTrees")
		return
	var joiner_stump := false
	for child in join_parent.get_children():
		if child is TreeDoodad and (child as TreeDoodad).is_stump:
			joiner_stump = true
	if not joiner_stump:
		_fail("US-006 T007: late join must see the stump")
		return

	var factory: PaperFactory = load("res://buildings/buildables/paper_factory.tscn").instantiate() as PaperFactory
	factory.stored_wood = 4
	add_child(factory)
	await get_tree().process_frame
	if factory.stored_wood != 4:
		_fail("US-006 T007: stored_wood must be an exported replicated field")
		return

	print("US-006 T007 replicate test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
