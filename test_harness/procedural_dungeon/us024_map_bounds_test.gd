extends Node

func _ready() -> void:
	var bounds := MapBounds.new()
	if bounds.has_committed_bounds():
		push_error("US-024 T001: empty MapBounds must not be committed")
		get_tree().quit(1)
		return
	if bounds.is_interior_cell(Vector2i.ZERO) or bounds.is_cliff_cell(Vector2i.ZERO):
		push_error("US-024 T001: uncommitted bounds must not treat void as walkable or cliff")
		get_tree().quit(1)
		return
	if bounds.is_world_position_in_interior(Vector2.ZERO):
		push_error("US-024 T001: uncommitted world position must not be interior")
		get_tree().quit(1)
		return
	if bounds.cliff_cells().size() != 0 or bounds.interior_cell_count() != 0:
		push_error("US-024 T001: uncommitted bounds must have empty cliff and interior counts")
		get_tree().quit(1)
		return

	var interior := Rect2i(10, 20, 8, 6)
	bounds.commit_interior(interior)
	if not bounds.has_committed_bounds():
		push_error("US-024 T001: commit_interior did not commit")
		get_tree().quit(1)
		return
	if bounds.get_interior() != interior:
		push_error("US-024 T001: get_interior mismatch")
		get_tree().quit(1)
		return
	if not bounds.is_interior_cell(Vector2i(10, 20)) or not bounds.is_interior_cell(Vector2i(17, 25)):
		push_error("US-024 T001: interior corners must be interior")
		get_tree().quit(1)
		return
	if bounds.is_interior_cell(Vector2i(18, 25)) or bounds.is_interior_cell(Vector2i(10, 19)):
		push_error("US-024 T001: cells just outside interior must not be interior")
		get_tree().quit(1)
		return
	if bounds.is_cliff_cell(Vector2i(10, 20)):
		push_error("US-024 T001: interior cell must not be cliff")
		get_tree().quit(1)
		return
	if not bounds.is_cliff_cell(Vector2i(9, 20)):
		push_error("US-024 T001: west neighbor must be cliff")
		get_tree().quit(1)
		return
	if not bounds.is_cliff_cell(Vector2i(10, 19)):
		push_error("US-024 T001: north neighbor must be cliff")
		get_tree().quit(1)
		return
	if not bounds.is_cliff_cell(Vector2i(18, 25)):
		push_error("US-024 T001: east neighbor must be cliff")
		get_tree().quit(1)
		return
	if not bounds.is_cliff_cell(Vector2i(9, 19)):
		push_error("US-024 T001: NW corner must be cliff")
		get_tree().quit(1)
		return
	if bounds.is_cliff_cell(Vector2i(0, 0)) or bounds.is_interior_cell(Vector2i(0, 0)):
		push_error("US-024 T001: far void must be neither interior nor cliff")
		get_tree().quit(1)
		return

	var world_inside: Vector2 = DungeonGrid.to_world(Vector2i(12, 22)) + Vector2(64, 64)
	if not bounds.is_world_position_in_interior(world_inside):
		push_error("US-024 T001: interior world position rejected")
		get_tree().quit(1)
		return
	var world_cliff: Vector2 = DungeonGrid.to_world(Vector2i(9, 20)) + Vector2(64, 64)
	if bounds.is_world_position_in_interior(world_cliff):
		push_error("US-024 T001: cliff world position treated as interior")
		get_tree().quit(1)
		return
	if not bounds.is_world_position_on_cliff(world_cliff):
		push_error("US-024 T001: cliff world position not on cliff")
		get_tree().quit(1)
		return
	var clamped: Vector2 = bounds.clamp_world_to_interior(world_cliff)
	if not bounds.is_world_position_walkable(clamped):
		push_error("US-024 T001: clamp_world_to_interior did not land in walkable bounds")
		get_tree().quit(1)
		return
	var walk: Rect2 = bounds.walk_world_rect()
	var origin: Vector2 = DungeonGrid.to_world(interior.position)
	if walk.position.y >= origin.y:
		push_error("US-024 T001: walk rect must extend north of the cell origin to the cliff lip")
		get_tree().quit(1)
		return
	if walk.position.x >= origin.x:
		push_error("US-024 T001: walk rect must extend west of the cell origin to the cliff lip")
		get_tree().quit(1)
		return

	var cliffs: Array[Vector2i] = bounds.cliff_cells()
	if cliffs.size() != 32:
		push_error("US-024 T001: expected 32 cliff cells for 8x6 interior, got %d" % cliffs.size())
		get_tree().quit(1)
		return
	if bounds.interior_cell_count() != 48:
		push_error("US-024 T001: expected 48 interior cells, got %d" % bounds.interior_cell_count())
		get_tree().quit(1)
		return

	bounds.commit_interior(Rect2i(0, 0, 0, 4))
	if bounds.has_committed_bounds():
		push_error("US-024 T001: zero-width rect must not commit")
		get_tree().quit(1)
		return

	print("US-024 T001 map bounds test passed")
	get_tree().quit(0)
