extends Node

func _ready() -> void:
	Zone.debug_claim_overlays = true
	PlayerManager.reality_level = 0
	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	add_child(level)
	await get_tree().process_frame

	var interior := Rect2i(0, 0, 16, 10)
	var dungeon := Rect2i(8, 2, 8, 6)
	level.apply_map_interior(interior, dungeon)
	await get_tree().process_frame

	var reality: RealityZone = load("res://zones/reality_zone.tscn").instantiate()
	reality.add_to_group("RealityZone")
	add_child(reality)
	await get_tree().process_frame

	if reality.home_rect.position.x != interior.position.x:
		push_error("US-001: Reality home must west-anchor")
		get_tree().quit(1)
		return
	if not interior.encloses(reality.home_rect) and reality.home_rect != interior:
		if reality.home_rect.position.x < interior.position.x or reality.home_rect.end.x > interior.end.x:
			push_error("US-001: Reality home left interior %s" % reality.home_rect)
			get_tree().quit(1)
			return
	if not _rect_inside_interior(reality.home_rect, level.map_bounds):
		push_error("US-001: Reality home covers non-interior cells")
		get_tree().quit(1)
		return

	if not reality._resolve_collision_shape():
		push_error("US-001: missing CollisionShape2D")
		get_tree().quit(1)
		return
	if reality.collision_shape_2d.shape is CircleShape2D:
		push_error("US-001: Reality collision must not be a circle")
		get_tree().quit(1)
		return
	if not (reality.collision_shape_2d.shape is RectangleShape2D):
		push_error("US-001: Reality collision must be a rectangle")
		get_tree().quit(1)
		return
	var shape: RectangleShape2D = reality.collision_shape_2d.shape
	var expected := Vector2(reality.home_rect.size) * DungeonGrid.CELL_PX
	if shape.size != expected:
		push_error("US-001: rect collision size %s expected %s" % [shape.size, expected])
		get_tree().quit(1)
		return

	var overlay: Node2D = reality.get_node_or_null("HomeOverlay")
	if overlay == null:
		push_error("US-001: HomeOverlay missing")
		get_tree().quit(1)
		return
	var expected_cells: int = reality.home_rect.size.x * reality.home_rect.size.y
	if overlay.get_child_count() != expected_cells:
		push_error("US-001: overlay cells %d expected %d" % [overlay.get_child_count(), expected_cells])
		get_tree().quit(1)
		return
	var sprite: Sprite2D = overlay.get_child(0) as Sprite2D
	if sprite == null or sprite.texture == null:
		push_error("US-001: overlay sprite missing texture")
		get_tree().quit(1)
		return
	if str(sprite.texture.resource_path).find("reality_home_overlay.png") == -1:
		push_error("US-001: overlay must use reality_home_overlay.png")
		get_tree().quit(1)
		return
	var first_cell := reality.home_rect.position
	var expected_pos: Vector2 = DungeonGrid.to_world(first_cell) - reality.global_position + Vector2(0, -63)
	if not sprite.position.is_equal_approx(expected_pos):
		push_error("US-001: overlay offset %s expected %s" % [sprite.position, expected_pos])
		get_tree().quit(1)
		return

	var inside: Vector2 = DungeonGrid.to_world_center(reality.home_rect.position)
	var outside: Vector2 = DungeonGrid.to_world_center(Vector2i(interior.end.x - 1, interior.position.y))
	if not reality.contains_world_position(inside):
		push_error("US-001: west cell must be claimed")
		get_tree().quit(1)
		return
	if not reality.is_position_within_zone(inside):
		push_error("US-001: is_position_within_zone must use the rect")
		get_tree().quit(1)
		return
	if reality.contains_world_position(outside) and not reality.home_rect.has_point(Vector2i(interior.end.x - 1, interior.position.y)):
		push_error("US-001: east interior cell must not be claimed at level 0")
		get_tree().quit(1)
		return

	var start_width: int = reality.home_rect.size.x
	PlayerManager.reality_level = 2
	reality.on_level_changed(2)
	if reality.home_rect.size.x != start_width + 2:
		push_error("US-001: Reality Level should grow width by 2, got %s from %s" % [reality.home_rect.size.x, start_width])
		get_tree().quit(1)
		return
	if not _rect_inside_interior(reality.home_rect, level.map_bounds):
		push_error("US-001: grown home left interior")
		get_tree().quit(1)
		return
	if reality.collision_shape_2d.shape is CircleShape2D:
		push_error("US-001: growth must not restore circle collision")
		get_tree().quit(1)
		return

	PlayerManager.reality_level = 10000
	reality.on_level_changed(10000)
	if reality.home_rect != interior:
		push_error("US-001: huge growth should clip to interior, got %s" % reality.home_rect)
		get_tree().quit(1)
		return

	PlayerManager.reality_level = 0
	print("US-001 Reality home rect test passed")
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
