extends Node

func _ready() -> void:
	PlayerManager.reality_level = 0
	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	level.add_to_group("level_manager")
	add_child(level)
	await get_tree().process_frame

	var interior := Rect2i(0, 0, 16, 10)
	var dungeon := Rect2i(8, 2, 8, 6)
	level.apply_map_interior(interior, dungeon)
	await get_tree().process_frame
	level.rebuild_outside_fill()
	await get_tree().process_frame

	var reality: RealityZone = load("res://zones/reality_zone.tscn").instantiate()
	reality.add_to_group("RealityZone")
	add_child(reality)
	await get_tree().process_frame

	var occupied := Vector2i(dungeon.position)
	var dungeon_tile: Node2D = load("res://level/floor.tscn").instantiate() as Node2D
	dungeon_tile.position = DungeonGrid.to_world(occupied)
	dungeon_tile.add_to_group("generated_dungeon_tiles")
	add_child(dungeon_tile)
	await get_tree().process_frame

	var home_cell: Vector2i = reality.home_rect.position
	if not level.is_outside_build_cell(home_cell):
		push_error("US-001 T006: west home cell should be outside grass/dirt")
		get_tree().quit(1)
		return
	if level.is_outside_build_cell(occupied):
		push_error("US-001 T006: dungeon cell must not be a build cell")
		get_tree().quit(1)
		return

	var size := Vector2(128, 128)
	var home_pos: Vector2 = DungeonGrid.to_world_center(home_cell)
	if not BuildingManager.is_area_clear(home_pos, size):
		push_error("US-001 T006: full Reality outside footprint must accept")
		get_tree().quit(1)
		return

	var outside_home := Vector2i(interior.end.x - 2, interior.position.y + 1)
	if reality.home_rect.has_point(outside_home):
		outside_home = Vector2i(interior.end.x - 1, interior.end.y - 1)
	var outside_pos: Vector2 = DungeonGrid.to_world_center(outside_home)
	if BuildingManager.is_area_clear(outside_pos, size):
		push_error("US-001 T006: footprint outside Reality must reject")
		get_tree().quit(1)
		return

	var dungeon_pos: Vector2 = DungeonGrid.to_world_center(occupied)
	if BuildingManager.is_area_clear(dungeon_pos, size):
		push_error("US-001 T006: dungeon footprint must reject")
		get_tree().quit(1)
		return

	var pocket_id: int = reality.spawn_pocket(outside_home, Vector2i(2, 2), 8.0)
	if pocket_id < 0:
		push_error("US-001 T006: pocket for building test failed")
		get_tree().quit(1)
		return
	if not level.is_outside_build_cell(outside_home):
		push_error("US-001 T006: pocket cell on overworld should stay outside tile")
		get_tree().quit(1)
		return
	if not BuildingManager.is_area_clear(outside_pos, size):
		push_error("US-001 T006: pocket on outside tiles must accept")
		get_tree().quit(1)
		return

	print("US-001 T006 building placement test passed")
	get_tree().quit(0)
