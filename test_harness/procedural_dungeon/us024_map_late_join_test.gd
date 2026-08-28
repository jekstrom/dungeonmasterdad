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

	host.commit_map_interior(interior)
	if host.map_bounds.get_interior() != interior:
		push_error("US-024 T014: offline commit must not clear a generated map")
		get_tree().quit(1)
		return
	if Lobby.is_network_server():
		push_error("US-024 T014: test must run on OfflineMultiplayerPeer")
		get_tree().quit(1)
		return

	var ghost := Node2D.new()
	ghost.set_script(load("res://_globals/level_manager.gd"))
	add_child(ghost)
	await get_tree().process_frame
	ghost.commit_map_interior(interior)
	if ghost.has_map_bounds():
		push_error("US-024 T014: OfflineMultiplayerPeer must wait for host payload")
		get_tree().quit(1)
		return

	var payload: Dictionary = host.build_map_sync_payload()
	if int(payload.get("iw", 0)) != interior.size.x or int(payload.get("ih", 0)) != interior.size.y:
		push_error("US-024 T014: payload interior mismatch")
		get_tree().quit(1)
		return
	if int(payload.get("dx", -1)) != dungeon.position.x or int(payload.get("dw", 0)) != dungeon.size.x:
		push_error("US-024 T014: payload dungeon origin mismatch")
		get_tree().quit(1)
		return
	if int(payload.get("ex", 0)) != exit_cell.x or int(payload.get("ey", 0)) != exit_cell.y:
		push_error("US-024 T014: payload exit mismatch")
		get_tree().quit(1)
		return
	var cliffs: Array = payload.get("cliffs", [])
	var outs: Array = payload.get("out", [])
	var trees: Array = payload.get("trees", [])
	if cliffs.size() != host.get_node("CliffTiles").get_child_count():
		push_error("US-024 T014: payload cliff count")
		get_tree().quit(1)
		return
	if outs.size() != host.get_node("OutsideTiles").get_child_count():
		push_error("US-024 T014: payload outside count")
		get_tree().quit(1)
		return
	if trees.size() != host.get_node("ScatteredTrees").get_child_count():
		push_error("US-024 T014: payload tree count")
		get_tree().quit(1)
		return
	if outs.is_empty() or cliffs.is_empty() or trees.is_empty():
		push_error("US-024 T014: payload missing overworld lists")
		get_tree().quit(1)
		return

	var joiner := Node2D.new()
	joiner.set_script(load("res://_globals/level_manager.gd"))
	add_child(joiner)
	await get_tree().process_frame
	joiner.tree_scatter_density = 1.0
	joiner.apply_map_sync_payload(payload)
	await get_tree().process_frame

	if joiner.map_bounds.get_interior() != interior:
		push_error("US-024 T014: joiner interior mismatch")
		get_tree().quit(1)
		return
	if joiner.dungeon_cell_bounds() != dungeon:
		push_error("US-024 T014: joiner dungeon AABB mismatch")
		get_tree().quit(1)
		return
	if _sig_cliffs(host) != _sig_cliffs(joiner):
		push_error("US-024 T014: joiner cliff ring mismatch")
		get_tree().quit(1)
		return
	if _sig_outside(host) != _sig_outside(joiner):
		push_error("US-024 T014: joiner outside fill mismatch")
		get_tree().quit(1)
		return
	if _sig_trees(host) != _sig_trees(joiner):
		push_error("US-024 T014: joiner tree set mismatch")
		get_tree().quit(1)
		return
	if joiner.get_node("ScatteredTrees").get_child_count() == joiner.tree_scatter_eligible_cells().size():
		push_error("US-024 T014: joiner regenerated trees from local density")
		get_tree().quit(1)
		return
	for child in joiner.get_node("OutsideTiles").get_children():
		if child.is_in_group("generated_dungeon_tiles"):
			push_error("US-024 T014: outside tile on spawn-path tile group")
			get_tree().quit(1)
			return
	for child in joiner.get_node("CliffTiles").get_children():
		if child.get_node_or_null("MultiplayerSynchronizer") != null:
			push_error("US-024 T014: cliff kept MultiplayerSynchronizer")
			get_tree().quit(1)
			return

	print("US-024 T014 late join map sync test passed")
	get_tree().quit(0)

func _sig_cliffs(level: Node) -> Array[String]:
	var sig: Array[String] = []
	var parent: Node = level.get_node_or_null("CliffTiles")
	if parent == null:
		return sig
	for child in parent.get_children():
		var world: Vector2 = child.position
		if child.has_method("grid_world_position"):
			world = child.grid_world_position()
		var cell: Vector2i = DungeonGrid.from_world(world)
		var frame := -1
		if "cliff_frame" in child:
			frame = int(child.cliff_frame)
		sig.append("%d:%d:%d" % [cell.x, cell.y, frame])
	sig.sort()
	return sig

func _sig_outside(level: Node) -> Array[String]:
	var sig: Array[String] = []
	var parent: Node = level.get_node_or_null("OutsideTiles")
	if parent == null:
		return sig
	for child in parent.get_children():
		var cell: Vector2i = DungeonGrid.from_world(child.position)
		sig.append("%d:%d:%d:%d" % [cell.x, cell.y, int(child.ground_kind), int(child.variety)])
	sig.sort()
	return sig

func _sig_trees(level: Node) -> Array[String]:
	var sig: Array[String] = []
	var parent: Node = level.get_node_or_null("ScatteredTrees")
	if parent == null:
		return sig
	for child in parent.get_children():
		var cell: Vector2i = DungeonGrid.from_world(child.position)
		sig.append("%d:%d:%d" % [cell.x, cell.y, int(child.tree_type)])
	sig.sort()
	return sig
