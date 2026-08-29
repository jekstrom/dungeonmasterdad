extends Node

func _ready() -> void:
	DmManager.fantasy_level = 0
	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	level.add_to_group("level_manager")
	add_child(level)
	await get_tree().process_frame

	var interior := Rect2i(0, 0, 16, 10)
	var dungeon := Rect2i(8, 2, 8, 6)
	level.apply_map_interior(interior, dungeon)
	await get_tree().process_frame

	var fantasy: Zone = load("res://zones/fantasy_zone.tscn").instantiate()
	add_child(fantasy)
	await get_tree().process_frame

	if not fantasy.home_rect.intersects(dungeon):
		push_error("US-003: Fantasy home must cover the east dungeon AABB")
		get_tree().quit(1)
		return
	if fantasy.home_rect.end.x != interior.end.x:
		push_error("US-003: Fantasy home must east-anchor, end.x %s interior %s" % [fantasy.home_rect.end.x, interior.end.x])
		get_tree().quit(1)
		return
	if not _rect_inside_interior(fantasy.home_rect, level.map_bounds):
		push_error("US-003: Fantasy home covers non-interior cells")
		get_tree().quit(1)
		return

	if not fantasy._resolve_collision_shape():
		push_error("US-003: missing CollisionShape2D")
		get_tree().quit(1)
		return
	if fantasy.collision_shape_2d.shape is CircleShape2D:
		push_error("US-003: Fantasy collision must not be a circle")
		get_tree().quit(1)
		return
	if not (fantasy.collision_shape_2d.shape is RectangleShape2D):
		push_error("US-003: Fantasy collision must be a rectangle")
		get_tree().quit(1)
		return
	var shape: RectangleShape2D = fantasy.collision_shape_2d.shape
	var expected := Vector2(fantasy.home_rect.size) * DungeonGrid.CELL_PX
	if shape.size != expected:
		push_error("US-003: rect collision size %s expected %s" % [shape.size, expected])
		get_tree().quit(1)
		return

	var overlay: Node2D = fantasy.get_node_or_null("HomeOverlay")
	if overlay == null:
		push_error("US-003: HomeOverlay missing")
		get_tree().quit(1)
		return
	var expected_cells: int = fantasy.home_rect.size.x * fantasy.home_rect.size.y
	if overlay.get_child_count() != expected_cells:
		push_error("US-003: overlay cells %d expected %d" % [overlay.get_child_count(), expected_cells])
		get_tree().quit(1)
		return
	var sprite: Sprite2D = overlay.get_child(0) as Sprite2D
	if sprite == null or sprite.texture == null:
		push_error("US-003: overlay sprite missing texture")
		get_tree().quit(1)
		return
	if str(sprite.texture.resource_path).find("fantasy_home_overlay.png") == -1:
		push_error("US-003: overlay must use fantasy_home_overlay.png")
		get_tree().quit(1)
		return
	var first_cell := fantasy.home_rect.position
	var expected_pos: Vector2 = DungeonGrid.to_world(first_cell) - fantasy.global_position + Vector2(0, -63)
	if not sprite.position.is_equal_approx(expected_pos):
		push_error("US-003: overlay offset %s expected %s" % [sprite.position, expected_pos])
		get_tree().quit(1)
		return

	var inside: Vector2 = DungeonGrid.to_world_center(dungeon.position)
	var outside: Vector2 = DungeonGrid.to_world_center(interior.position)
	if not fantasy.contains_world_position(inside):
		push_error("US-003: dungeon cell must be Fantasy-claimed")
		get_tree().quit(1)
		return
	if fantasy.contains_world_position(outside) and not fantasy.home_rect.has_point(interior.position):
		push_error("US-003: west interior cell must not be Fantasy-claimed at level 0")
		get_tree().quit(1)
		return

	var start_rect: Rect2i = fantasy.home_rect
	DmManager.fantasy_level = 2
	fantasy.on_level_changed(2)
	if fantasy.home_rect == start_rect:
		push_error("US-003: Fantasy Level should grow the home rect")
		get_tree().quit(1)
		return
	if fantasy.home_rect.end.x != interior.end.x:
		push_error("US-003: grown Fantasy home must stay east-anchored")
		get_tree().quit(1)
		return
	if not _rect_inside_interior(fantasy.home_rect, level.map_bounds):
		push_error("US-003: grown home left interior")
		get_tree().quit(1)
		return
	if fantasy.collision_shape_2d.shape is CircleShape2D:
		push_error("US-003: growth must not restore circle collision")
		get_tree().quit(1)
		return
	var grown_cells: int = fantasy.home_rect.size.x * fantasy.home_rect.size.y
	if overlay.get_child_count() != grown_cells:
		push_error("US-003: grown overlay cells %d expected %d" % [overlay.get_child_count(), grown_cells])
		get_tree().quit(1)
		return

	DmManager.fantasy_level = 10000
	fantasy.on_level_changed(10000)
	if fantasy.home_rect != interior:
		push_error("US-003: huge growth should clip to interior, got %s" % fantasy.home_rect)
		get_tree().quit(1)
		return

	DmManager.fantasy_level = 0
	print("US-003 Fantasy home rect test passed")
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
