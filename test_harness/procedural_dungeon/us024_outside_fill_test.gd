extends Node

func _ready() -> void:
	var catalog := OutsideCatalog.new()
	if catalog.get_outside_scene_path() != "res://level/outside_tile.tscn":
		push_error("US-024 T011: outside catalog path")
		get_tree().quit(1)
		return
	if catalog.is_dungeon_tile_path("res://level/outside_tile.tscn"):
		push_error("US-024 T011: outside tile must not be dungeon catalog")
		get_tree().quit(1)
		return
	if catalog.is_approved_scene_path("res://level/floor.tscn"):
		push_error("US-024 T011: floor.tscn must not be in outside catalog")
		get_tree().quit(1)
		return

	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	add_child(level)
	await get_tree().process_frame

	var interior := Rect2i(0, 0, 8, 6)
	var dungeon := Rect2i(4, 1, 4, 4)
	level.apply_map_interior(interior, dungeon)
	await get_tree().process_frame

	var parent: Node = level.get_node_or_null("OutsideTiles")
	if parent == null:
		push_error("US-024 T011: OutsideTiles missing")
		get_tree().quit(1)
		return
	var expected: int = interior.size.x * interior.size.y - dungeon.size.x * dungeon.size.y
	if parent.get_child_count() != expected:
		push_error("US-024 T011: expected %d outside tiles, got %d" % [expected, parent.get_child_count()])
		get_tree().quit(1)
		return

	var grass := 0
	var dirt := 0
	for child in parent.get_children():
		if not (child is OutsideTile):
			push_error("US-024 T011: child is not OutsideTile")
			get_tree().quit(1)
			return
		var tile: OutsideTile = child
		if tile.scene_file_path == "res://level/floor.tscn":
			push_error("US-024 T011: used dungeon floor as overworld")
			get_tree().quit(1)
			return
		var cell: Vector2i = DungeonGrid.from_world(tile.position)
		if dungeon.has_point(cell):
			push_error("US-024 T011: outside tile on dungeon cell %s" % cell)
			get_tree().quit(1)
			return
		if level.map_bounds.is_cliff_cell(cell):
			push_error("US-024 T011: outside tile on cliff %s" % cell)
			get_tree().quit(1)
			return
		if not level.map_bounds.is_interior_cell(cell):
			push_error("US-024 T011: outside tile outside interior %s" % cell)
			get_tree().quit(1)
			return
		if tile.ground_kind == OutsideTile.GroundKind.GRASS:
			grass += 1
		else:
			dirt += 1
	if grass == 0 or dirt == 0:
		push_error("US-024 T011: fill must include grass and dirt")
		get_tree().quit(1)
		return

	level.apply_map_interior(interior, dungeon)
	await get_tree().process_frame
	if parent.get_child_count() != expected:
		push_error("US-024 T011: rebuild stacked outside tiles")
		get_tree().quit(1)
		return

	var sequential := Node2D.new()
	sequential.set_script(load("res://_globals/level_manager.gd"))
	add_child(sequential)
	await get_tree().process_frame
	sequential.apply_map_interior(interior)
	await get_tree().process_frame
	var seq_parent: Node = sequential.get_node_or_null("OutsideTiles")
	if seq_parent == null or seq_parent.get_child_count() != interior.size.x * interior.size.y:
		push_error("US-024 T011: fill without dungeon AABB must cover interior")
		get_tree().quit(1)
		return
	sequential.apply_map_interior(interior, dungeon)
	await get_tree().process_frame
	if seq_parent.get_child_count() != expected:
		push_error("US-024 T011: dungeon commit must strip outside from dungeon cells")
		get_tree().quit(1)
		return

	var stray: Node2D = load("res://level/outside_tile.tscn").instantiate() as Node2D
	stray.name = "stray_outside"
	stray.position = DungeonGrid.to_world(dungeon.position)
	stray.add_to_group("outside_tiles")
	add_child(stray)
	level.strip_outside_tiles_from_dungeon_cells()
	await get_tree().process_frame
	if is_instance_valid(stray) and stray.is_inside_tree():
		push_error("US-024 T011: pre-placed outside tile remained on dungeon cell")
		get_tree().quit(1)
		return

	var west: Vector2i = Vector2i(interior.position.x, interior.position.y)
	var found_west := false
	for child in parent.get_children():
		if child.is_in_group("generated_dungeon_tiles"):
			push_error("US-024 T011: outside tile in generated_dungeon_tiles")
			get_tree().quit(1)
			return
		if DungeonGrid.from_world(child.position) == west:
			found_west = true
			if child.get_node_or_null("StaticBody2D") or child.get_node_or_null("StaticBody"):
				push_error("US-024 T011: outside tile must stay walkable")
				get_tree().quit(1)
				return
	if not found_west:
		push_error("US-024 T011: west spawn strip must be outside tiles")
		get_tree().quit(1)
		return

	var other := Node2D.new()
	other.set_script(load("res://_globals/level_manager.gd"))
	add_child(other)
	await get_tree().process_frame
	other.apply_map_interior(interior, dungeon)
	await get_tree().process_frame
	var a_kinds: Array[int] = []
	var b_kinds: Array[int] = []
	for child in parent.get_children():
		a_kinds.append(int(child.ground_kind) * 10 + int(child.variety))
	for child in other.get_node("OutsideTiles").get_children():
		b_kinds.append(int(child.ground_kind) * 10 + int(child.variety))
	if a_kinds != b_kinds:
		push_error("US-024 T011: fill seed must match across peers")
		get_tree().quit(1)
		return

	print("US-024 T011 outside fill test passed")
	get_tree().quit(0)
