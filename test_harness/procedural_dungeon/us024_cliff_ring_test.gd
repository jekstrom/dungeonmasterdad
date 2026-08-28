extends Node

func _ready() -> void:
	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	add_child(level)
	await get_tree().process_frame

	var interior := Rect2i(0, 0, 8, 6)
	level.apply_map_interior(interior)
	await get_tree().process_frame

	var parent: Node = level.get_node_or_null("CliffTiles")
	if parent == null:
		push_error("US-024 T006: CliffTiles parent missing")
		get_tree().quit(1)
		return
	var catalog := CliffCatalog.new()
	var cliffs: Array[Node] = []
	for child in parent.get_children():
		cliffs.append(child)
	if cliffs.size() != 32:
		push_error("US-024 T006: expected 32 cliff tiles for 8x6 interior, got %d" % cliffs.size())
		get_tree().quit(1)
		return

	var by_cell: Dictionary = {}
	for node in cliffs:
		if not (node is CliffDoodad):
			push_error("US-024 T006: cliff child is not CliffDoodad")
			get_tree().quit(1)
			return
		var cliff: CliffDoodad = node
		if catalog.is_dungeon_tile_path(cliff.scene_file_path):
			push_error("US-024 T006: cliff must not be a dungeon tile")
			get_tree().quit(1)
			return
		if cliff.scene_file_path != catalog.get_cliff_scene_path():
			push_error("US-024 T006: cliff scene path must be cliff.tscn")
			get_tree().quit(1)
			return
		var cell: Vector2i = DungeonGrid.from_world(cliff.grid_world_position())
		by_cell[cell] = cliff
		var expected_frame: int = catalog.cliff_frame_for_cell(interior, cell)
		if int(cliff.cliff_frame) != expected_frame:
			push_error("US-024 T006: cell %s frame %s expected %s" % [cell, cliff.cliff_frame, expected_frame])
			get_tree().quit(1)
			return
		var body: StaticBody2D = cliff.get_node_or_null("StaticBody")
		if body == null or body.collision_layer != 16:
			push_error("US-024 T006: cliff collision layer")
			get_tree().quit(1)
			return

	for x in range(interior.position.x, interior.end.x):
		if not by_cell.has(Vector2i(x, interior.position.y - 1)):
			push_error("US-024 T006: missing north cliff at x=%d" % x)
			get_tree().quit(1)
			return
		if not by_cell.has(Vector2i(x, interior.end.y)):
			push_error("US-024 T006: missing south cliff at x=%d" % x)
			get_tree().quit(1)
			return
	for y in range(interior.position.y, interior.end.y):
		if not by_cell.has(Vector2i(interior.position.x - 1, y)):
			push_error("US-024 T006: missing west cliff at y=%d" % y)
			get_tree().quit(1)
			return
		if not by_cell.has(Vector2i(interior.end.x, y)):
			push_error("US-024 T006: missing east cliff at y=%d" % y)
			get_tree().quit(1)
			return
	var corners: Array[Vector2i] = [
		Vector2i(interior.position.x - 1, interior.position.y - 1),
		Vector2i(interior.end.x, interior.position.y - 1),
		Vector2i(interior.position.x - 1, interior.end.y),
		Vector2i(interior.end.x, interior.end.y),
	]
	for corner in corners:
		if not by_cell.has(corner):
			push_error("US-024 T006: missing corner %s" % corner)
			get_tree().quit(1)
			return
	if int(by_cell[corners[0]].cliff_frame) != int(CliffDoodad.CliffFrame.NW):
		push_error("US-024 T006: NW corner frame")
		get_tree().quit(1)
		return
	if int(by_cell[corners[3]].cliff_frame) != int(CliffDoodad.CliffFrame.SE):
		push_error("US-024 T006: SE corner frame")
		get_tree().quit(1)
		return

	level.apply_map_interior(interior)
	await get_tree().process_frame
	if parent.get_child_count() != 32:
		push_error("US-024 T006: rebuild should replace the ring, not stack tiles")
		get_tree().quit(1)
		return

	print("US-024 T006 cliff ring test passed")
	get_tree().quit(0)
