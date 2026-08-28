extends Node

func _ready() -> void:
	var dungeon := Rect2i(0, 0, 24, 24)
	var delta: Vector2i = MapBounds.cell_translation_for_east_flush(dungeon)
	var entrance_local := Vector2i(21, 12)
	var entrance_cell: Vector2i = entrance_local + delta
	var shifted_dungeon := Rect2i(dungeon.position + delta, dungeon.size)
	var interior: Rect2i = MapBounds.interior_from_dungeon_aabb(shifted_dungeon)
	var bounds := MapBounds.new()
	bounds.commit_interior(interior)
	var spawn: Vector2 = DungeonGrid.to_world_center(entrance_cell)

	if not interior.has_point(entrance_cell):
		push_error("US-024 T010: entrance cell not in interior")
		get_tree().quit(1)
		return
	if not shifted_dungeon.has_point(entrance_cell):
		push_error("US-024 T010: entrance cell not in east dungeon AABB")
		get_tree().quit(1)
		return
	if bounds.is_cliff_cell(entrance_cell):
		push_error("US-024 T010: entrance on cliff")
		get_tree().quit(1)
		return
	var west: Array[Vector2i] = bounds.west_spawn_strip_cells(shifted_dungeon)
	if west.has(entrance_cell):
		push_error("US-024 T010: entrance must not be on the west spawn strip")
		get_tree().quit(1)
		return
	if not bounds.is_world_position_in_interior(spawn):
		push_error("US-024 T010: entrance world position not interior")
		get_tree().quit(1)
		return
	if spawn.is_equal_approx(Vector2.ZERO):
		push_error("US-024 T010: DM must not spawn at world origin")
		get_tree().quit(1)
		return
	if entrance_cell.x <= interior.position.x:
		push_error("US-024 T010: entrance should sit on the east dungeon, not the west edge")
		get_tree().quit(1)
		return

	var layout := DungeonLayoutData.new()
	layout.layout_id = "t010"
	layout.entrance_cell = entrance_local
	layout.exit_cell = Vector2i(2, 12)
	layout.walkable_cells = [entrance_local, Vector2i(2, 12)]
	layout.translate_cells(delta)
	if layout.entrance_cell != entrance_cell:
		push_error("US-024 T010: translated entrance mismatch")
		get_tree().quit(1)
		return
	var from_manager: Vector2 = DungeonGrid.to_world_center(layout.entrance_cell)
	if not from_manager.is_equal_approx(spawn):
		push_error("US-024 T010: world-center entrance mismatch")
		get_tree().quit(1)
		return

	print("US-024 T010 dm entrance spawn test passed")
	get_tree().quit(0)
