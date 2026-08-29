extends Node

func _ready() -> void:
	PlayerManager.reality_level = 0
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
	level.rebuild_outside_fill()
	await get_tree().process_frame

	var reality: RealityZone = load("res://zones/reality_zone.tscn").instantiate()
	reality.add_to_group("RealityZone")
	add_child(reality)
	var fantasy: FantasyZone = load("res://zones/fantasy_zone.tscn").instantiate()
	add_child(fantasy)
	await get_tree().process_frame

	var size := Vector2(128, 128)
	var home_cell: Vector2i = reality.home_rect.position
	var home_pos: Vector2 = DungeonGrid.to_world_center(home_cell)
	if not BuildingManager.is_area_clear(home_pos, size):
		push_error("US-003 T007: Reality home outside Fantasy must still accept")
		get_tree().quit(1)
		return

	var fantasy_cell: Vector2i = fantasy.home_rect.position
	var fantasy_pos: Vector2 = DungeonGrid.to_world_center(fantasy_cell)
	if BuildingManager.is_area_clear(fantasy_pos, size):
		push_error("US-003 T007: footprint intersecting Fantasy home must reject")
		get_tree().quit(1)
		return

	var pocket_id: int = fantasy.spawn_pocket(home_cell, Vector2i(2, 2), 8.0)
	if pocket_id < 0:
		push_error("US-003 T007: Fantasy pocket over Reality home failed")
		get_tree().quit(1)
		return
	await get_tree().process_frame
	if BuildingManager.is_area_clear(home_pos, size):
		push_error("US-003 T007: footprint intersecting a Fantasy pocket must reject")
		get_tree().quit(1)
		return
	if not fantasy.expire_pocket(pocket_id):
		push_error("US-003 T007: pocket expire failed")
		get_tree().quit(1)
		return
	await get_tree().process_frame
	if not BuildingManager.is_area_clear(home_pos, size):
		push_error("US-003 T007: Reality home must accept again after Fantasy pocket expires")
		get_tree().quit(1)
		return

	var factory: Node2D = load("res://buildings/buildables/paper_factory.tscn").instantiate() as Node2D
	add_child(factory)
	factory.global_position = home_pos
	await get_tree().process_frame
	var cover_id: int = fantasy.spawn_pocket(home_cell, Vector2i(2, 2), 8.0)
	if cover_id < 0:
		push_error("US-003 T007: Fantasy pocket over factory failed")
		get_tree().quit(1)
		return
	await get_tree().process_frame
	if not is_instance_valid(factory):
		push_error("US-003 T007: existing building must not be auto-destroyed")
		get_tree().quit(1)
		return

	print("US-003 T007 building reject test passed")
	get_tree().quit(0)
