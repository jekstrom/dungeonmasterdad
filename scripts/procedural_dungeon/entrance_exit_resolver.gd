class_name EntranceExitResolver extends RefCounted

func resolve_positions(start_position: Vector2i, exit_position: Vector2i, generation_bounds: Rect2i) -> Dictionary:
	if start_position == exit_position:
		return DungeonGrid.fail("START_EQUALS_EXIT", "Start and exit positions must be different")
	if not generation_bounds.has_point(start_position) or not generation_bounds.has_point(exit_position):
		return DungeonGrid.fail("POSITION_OUT_OF_BOUNDS", "Start and exit positions must be inside generation bounds")
	return {
		"ok": true,
		"entrance_cell": start_position,
		"exit_cell": exit_position
	}
