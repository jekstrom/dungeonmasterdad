extends Node

func _ready() -> void:
	var bounds := MapBounds.new()
	if bounds.intersect_interior(Rect2i(0, 0, 4, 4)) != Rect2i():
		push_error("US-024 T013: uncommitted intersect must be empty")
		get_tree().quit(1)
		return
	bounds.commit_interior(Rect2i(0, 0, 16, 10))
	if bounds.intersect_interior(Rect2i(2, 2, 4, 4)) != Rect2i(2, 2, 4, 4):
		push_error("US-024 T013: interior rect must stay intact")
		get_tree().quit(1)
		return
	var overflow: Rect2i = bounds.intersect_interior(Rect2i(-4, -2, 8, 6))
	if overflow != Rect2i(0, 0, 4, 4):
		push_error("US-024 T013: overflow clip expected (0,0,4,4) got %s" % overflow)
		get_tree().quit(1)
		return
	if bounds.intersect_interior(Rect2i(-8, -8, 2, 2)) != Rect2i():
		push_error("US-024 T013: void rect must clip to empty")
		get_tree().quit(1)
		return
	if bounds.intersect_interior(Rect2i(0, 0, 0, 4)) != Rect2i():
		push_error("US-024 T013: degenerate rect must clip to empty")
		get_tree().quit(1)
		return
	var cliff_spill: Rect2i = bounds.intersect_interior(Rect2i(-1, 0, 4, 2))
	if cliff_spill.position.x < 0 or not bounds.get_interior().encloses(cliff_spill):
		push_error("US-024 T013: clipped rect must not include cliff cells")
		get_tree().quit(1)
		return

	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	add_child(level)
	await get_tree().process_frame

	var interior := Rect2i(0, 0, 16, 10)
	var dungeon := Rect2i(8, 2, 8, 6)
	level.apply_map_interior(interior, dungeon)
	await get_tree().process_frame

	var reality: RealityZone = load("res://zones/reality_zone.tscn").instantiate()
	var fantasy: Zone = load("res://zones/fantasy_zone.tscn").instantiate()
	add_child(reality)
	add_child(fantasy)
	await get_tree().process_frame

	if reality.home_rect.size.x <= 0 or reality.home_rect.size.y <= 0:
		push_error("US-024 T013: Reality home missing after commit")
		get_tree().quit(1)
		return
	if fantasy.home_rect.size.x <= 0 or fantasy.home_rect.size.y <= 0:
		push_error("US-024 T013: Fantasy home missing after commit")
		get_tree().quit(1)
		return
	if reality.home_rect.position.x != interior.position.x:
		push_error("US-024 T013: Reality home must anchor on west interior edge")
		get_tree().quit(1)
		return
	if not _rect_inside_interior(reality.home_rect, level.map_bounds):
		push_error("US-024 T013: Reality home covers non-interior cells")
		get_tree().quit(1)
		return
	if not _rect_inside_interior(fantasy.home_rect, level.map_bounds):
		push_error("US-024 T013: Fantasy home covers non-interior cells")
		get_tree().quit(1)
		return
	if not fantasy.home_rect.intersects(dungeon):
		push_error("US-024 T013: Fantasy home should cover dungeon AABB")
		get_tree().quit(1)
		return
	if fantasy.home_rect.end.x != interior.end.x:
		push_error("US-024 T013: Fantasy home should sit on east interior edge")
		get_tree().quit(1)
		return
	if reality.collision_shape_2d.shape is CircleShape2D:
		push_error("US-024 T013: Reality collision must not be a circle")
		get_tree().quit(1)
		return
	if not (reality.collision_shape_2d.shape is RectangleShape2D):
		push_error("US-024 T013: Reality collision must be a rectangle")
		get_tree().quit(1)
		return
	if fantasy.collision_shape_2d.shape is CircleShape2D:
		push_error("US-024 T013: Fantasy collision must not be a circle")
		get_tree().quit(1)
		return
	if not (fantasy.collision_shape_2d.shape is RectangleShape2D):
		push_error("US-024 T013: Fantasy collision must be a rectangle")
		get_tree().quit(1)
		return

	var pocket: Rect2i = fantasy.clip_pocket_rect(Rect2i(-3, -2, 6, 5))
	if pocket != Rect2i(0, 0, 3, 3):
		push_error("US-024 T013: pocket clip expected (0,0,3,3) got %s" % pocket)
		get_tree().quit(1)
		return
	if not _rect_inside_interior(pocket, level.map_bounds):
		push_error("US-024 T013: pocket covers non-interior cells")
		get_tree().quit(1)
		return

	PlayerManager.reality_level = 10000
	DmManager.fantasy_level = 10000
	reality.on_level_changed(10000)
	fantasy.on_level_changed(10000)
	if not _rect_inside_interior(reality.home_rect, level.map_bounds):
		push_error("US-024 T013: grown Reality home left the interior")
		get_tree().quit(1)
		return
	if not _rect_inside_interior(fantasy.home_rect, level.map_bounds):
		push_error("US-024 T013: grown Fantasy home left the interior")
		get_tree().quit(1)
		return
	if reality.home_rect.position.x < interior.position.x or reality.home_rect.end.x > interior.end.x:
		push_error("US-024 T013: huge Reality growth should stay inside interior, got %s" % reality.home_rect)
		get_tree().quit(1)
		return
	if fantasy.home_rect.end.x > interior.end.x or fantasy.home_rect.position.x < interior.position.x:
		push_error("US-024 T013: huge Fantasy growth should stay inside interior, got %s" % fantasy.home_rect)
		get_tree().quit(1)
		return
	if Zone.homes_occupy_same_cell(reality.home_rect, fantasy.home_rect):
		push_error("US-025 T001: huge growth must not leave overlapping homes %s vs %s" % [reality.home_rect, fantasy.home_rect])
		get_tree().quit(1)
		return

	print("US-024 T013 zone clip test passed")
	get_tree().quit(0)

func _rect_inside_interior(rect: Rect2i, bounds: MapBounds) -> bool:
	if rect.size.x <= 0 or rect.size.y <= 0:
		return false
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var cell := Vector2i(x, y)
			if not bounds.is_interior_cell(cell):
				return false
			if bounds.is_cliff_cell(cell):
				return false
	return true

