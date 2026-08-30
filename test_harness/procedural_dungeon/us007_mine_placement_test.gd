extends Node

func _ready() -> void:
	var interior := Rect2i(0, 0, 16, 10)
	var dungeon := Rect2i(8, 2, 8, 6)
	var exit_cell := Vector2i(8, 5)

	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	add_child(level)
	await get_tree().process_frame
	level.tree_scatter_density = 0.08
	level.mine_scatter_count = 3
	level.apply_map_interior(interior, dungeon, exit_cell)
	await get_tree().process_frame

	var parent: Node = level.get_node_or_null("ScatteredMines")
	if parent == null or parent.get_child_count() < 1:
		_fail("US-007 T006: expected at least one mine")
		return
	if parent.get_child_count() > 3:
		_fail("US-007 T006: mine_scatter_count 3, got %d" % parent.get_child_count())
		return
	var eligible: Array[Vector2i] = level.mine_scatter_eligible_cells()
	var occupied: Dictionary = {}
	for child in parent.get_children():
		if not (child is MineDoodad):
			_fail("US-007 T006: child is not MineDoodad")
			return
		var cell: Vector2i = DungeonGrid.from_world(child.position)
		if occupied.has(cell):
			_fail("US-007 T006: two mines on one cell")
			return
		occupied[cell] = true
		if not eligible.has(cell) and not _was_eligible_before_place(level, cell):
			# After placement the cell is still outside-eligible except tree subtraction;
			# mine cells are removed from mine_scatter_eligible only via trees, so check tree eligible.
			if not level.tree_scatter_eligible_cells().has(cell):
				_fail("US-007 T006: mine on ineligible cell %s" % cell)
				return
		if dungeon.has_point(cell):
			_fail("US-007 T006: mine on dungeon cell")
			return
		if cell == exit_cell:
			_fail("US-007 T006: mine on exit")
			return

	var other := Node2D.new()
	other.set_script(load("res://_globals/level_manager.gd"))
	add_child(other)
	await get_tree().process_frame
	other.tree_scatter_density = 0.08
	other.mine_scatter_count = 3
	other.apply_map_interior(interior, dungeon, exit_cell)
	await get_tree().process_frame
	if _mine_sig(level) != _mine_sig(other):
		_fail("US-007 T006: same seed must place the same mines")
		return

	print("US-007 T006 mine placement test passed")
	get_tree().quit(0)

func _was_eligible_before_place(level: Node, cell: Vector2i) -> bool:
	return level.tree_scatter_eligible_cells().has(cell)

func _mine_sig(level: Node) -> Array[String]:
	var sig: Array[String] = []
	var parent: Node = level.get_node_or_null("ScatteredMines")
	if parent == null:
		return sig
	for child in parent.get_children():
		var cell: Vector2i = DungeonGrid.from_world(child.position)
		sig.append("%d:%d" % [cell.x, cell.y])
	sig.sort()
	return sig

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
