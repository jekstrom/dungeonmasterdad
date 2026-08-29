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

	var fantasy: FantasyZone = load("res://zones/fantasy_zone.tscn").instantiate()
	add_child(fantasy)
	await get_tree().process_frame
	await get_tree().physics_frame

	var home_world: Vector2 = DungeonGrid.to_world_center(fantasy.home_rect.position)
	var outside_cell := Vector2i(interior.position.x + 1, interior.position.y + 1)
	if fantasy.is_claimed_cell(outside_cell):
		outside_cell = Vector2i(interior.position.x, interior.position.y)
	var outside_world: Vector2 = DungeonGrid.to_world_center(outside_cell)

	var dm_scene: PackedScene = load("res://dm/dm.tscn")
	if dm_scene == null:
		push_error("US-003 T006: dm.tscn missing")
		get_tree().quit(1)
		return
	var dm: Node2D = dm_scene.instantiate() as Node2D
	add_child(dm)
	dm.global_position = outside_world
	await get_tree().process_frame
	if dm is CharacterBody2D:
		var body := dm as CharacterBody2D
		if body.test_move(body.transform, home_world - body.global_position):
			push_error("US-003 T006: DM must enter Fantasy home freely")
			get_tree().quit(1)
			return
	dm.global_position = home_world
	await get_tree().process_frame
	if not fantasy.is_claimed_world(dm.global_position):
		push_error("US-003 T006: DM must remain in Fantasy home")
		get_tree().quit(1)
		return

	var pocket_id: int = fantasy.spawn_pocket(outside_cell, Vector2i(2, 2), 8.0)
	if pocket_id < 0:
		push_error("US-003 T006: pocket spawn failed")
		get_tree().quit(1)
		return
	dm.global_position = outside_world
	await get_tree().process_frame
	if not fantasy.is_claimed_world(dm.global_position):
		push_error("US-003 T006: DM must occupy a Fantasy pocket")
		get_tree().quit(1)
		return

	if dm is CharacterBody2D:
		var wall := StaticBody2D.new()
		var wall_shape := CollisionShape2D.new()
		var wall_rect := RectangleShape2D.new()
		wall_rect.size = Vector2(64, 64)
		wall_shape.shape = wall_rect
		wall.add_child(wall_shape)
		wall.collision_layer = 16
		add_child(wall)
		wall.global_position = dm.global_position + Vector2(80, 0)
		await get_tree().physics_frame
		if not (dm as CharacterBody2D).test_move(dm.transform, Vector2(80, 0)):
			push_error("US-003 T006: walls must still collide for the DM")
			get_tree().quit(1)
			return

	print("US-003 T006 DM occupancy test passed")
	get_tree().quit(0)
