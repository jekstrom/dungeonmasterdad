extends Node

func _ready() -> void:
	var interior := Rect2i(0, 0, 16, 10)
	var dungeon := Rect2i(8, 2, 8, 6)
	var exit_cell := Vector2i(8, 5)
	var building_cell := Vector2i(4, 4)

	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	add_child(level)
	await get_tree().process_frame

	var building_root := Node2D.new()
	building_root.add_to_group("building_root")
	var building := Node2D.new()
	building.position = DungeonGrid.to_world_center(building_cell)
	building_root.add_child(building)
	level.add_child(building_root)

	level.tree_scatter_density = 1.0
	level.apply_map_interior(interior, dungeon, exit_cell)
	await get_tree().process_frame

	var parent: Node = level.get_node_or_null("ScatteredTrees")
	if parent == null:
		push_error("US-024 T012: ScatteredTrees missing")
		get_tree().quit(1)
		return

	var eligible: Array[Vector2i] = level.tree_scatter_eligible_cells()
	if eligible.is_empty():
		push_error("US-024 T012: expected eligible cells")
		get_tree().quit(1)
		return
	if eligible.has(building_cell):
		push_error("US-024 T012: building cell must not be eligible")
		get_tree().quit(1)
		return
	if eligible.has(exit_cell):
		push_error("US-024 T012: exit cell must not be eligible")
		get_tree().quit(1)
		return
	for neighbor in DungeonGrid.neighbors(exit_cell):
		if eligible.has(neighbor):
			push_error("US-024 T012: exit neighbor %s must not be eligible" % neighbor)
			get_tree().quit(1)
			return
	for west in level.map_bounds.west_spawn_strip_cells(dungeon):
		if eligible.has(west):
			push_error("US-024 T012: west spawn %s must not be eligible" % west)
			get_tree().quit(1)
			return
	if eligible.has(dungeon.position):
		push_error("US-024 T012: dungeon cell must not be eligible")
		get_tree().quit(1)
		return

	if parent.get_child_count() != eligible.size():
		push_error("US-024 T012: density 1.0 expected %d trees, got %d" % [eligible.size(), parent.get_child_count()])
		get_tree().quit(1)
		return

	var occupied: Dictionary = {}
	for child in parent.get_children():
		if not (child is TreeDoodad):
			push_error("US-024 T012: child is not TreeDoodad")
			get_tree().quit(1)
			return
		var doodad: TreeDoodad = child
		if doodad.scene_file_path != "res://doodads/tree.tscn":
			push_error("US-024 T012: tree scene path")
			get_tree().quit(1)
			return
		if doodad.tree_type < 0 or doodad.tree_type > 9:
			push_error("US-024 T012: tree_type out of range %s" % doodad.tree_type)
			get_tree().quit(1)
			return
		var cell: Vector2i = DungeonGrid.from_world(doodad.position)
		if occupied.has(cell):
			push_error("US-024 T012: two trees on cell %s" % cell)
			get_tree().quit(1)
			return
		occupied[cell] = true
		if not eligible.has(cell):
			push_error("US-024 T012: tree on ineligible cell %s" % cell)
			get_tree().quit(1)
			return
		if dungeon.has_point(cell):
			push_error("US-024 T012: tree on dungeon %s" % cell)
			get_tree().quit(1)
			return
		if level.map_bounds.is_cliff_cell(cell):
			push_error("US-024 T012: tree on cliff %s" % cell)
			get_tree().quit(1)
			return

	level.apply_map_interior(interior, dungeon, exit_cell)
	await get_tree().process_frame
	if parent.get_child_count() != eligible.size():
		push_error("US-024 T012: rebuild stacked trees")
		get_tree().quit(1)
		return

	level.tree_scatter_density = 0.08
	level.apply_map_interior(interior, dungeon, exit_cell)
	await get_tree().process_frame
	var expected_default: int = int(round(float(eligible.size()) * 0.08))
	if parent.get_child_count() != expected_default:
		push_error("US-024 T012: default density expected %d trees, got %d" % [expected_default, parent.get_child_count()])
		get_tree().quit(1)
		return
	var ratio: float = float(parent.get_child_count()) / float(eligible.size())
	if ratio < 0.04 or ratio > 0.12:
		push_error("US-024 T012: default density %s outside 4-12%%" % ratio)
		get_tree().quit(1)
		return

	var other := Node2D.new()
	other.set_script(load("res://_globals/level_manager.gd"))
	add_child(other)
	await get_tree().process_frame
	other.tree_scatter_density = 0.08
	other.apply_map_interior(interior, dungeon, exit_cell)
	await get_tree().process_frame
	var a_sig: Array[int] = []
	var b_sig: Array[int] = []
	for child in parent.get_children():
		var cell: Vector2i = DungeonGrid.from_world(child.position)
		a_sig.append(cell.x * 1000 + cell.y * 10 + int(child.tree_type))
	for child in other.get_node("ScatteredTrees").get_children():
		var cell: Vector2i = DungeonGrid.from_world(child.position)
		b_sig.append(cell.x * 1000 + cell.y * 10 + int(child.tree_type))
	if a_sig != b_sig:
		push_error("US-024 T012: tree scatter seed must match across peers")
		get_tree().quit(1)
		return

	print("US-024 T012 tree scatter test passed")
	get_tree().quit(0)
