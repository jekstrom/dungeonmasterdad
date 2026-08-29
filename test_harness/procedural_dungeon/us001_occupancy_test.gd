extends Node

func _ready() -> void:
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

	var home_cell: Vector2i = reality.home_rect.position
	var home_world: Vector2 = DungeonGrid.to_world_center(home_cell)
	var pocket_cell := Vector2i(interior.end.x - 3, interior.position.y + 2)
	if reality.home_rect.has_point(pocket_cell):
		push_error("US-001 T005: pocket fixture must sit outside home")
		get_tree().quit(1)
		return
	if not reality.is_claimed_world(home_world):
		push_error("US-001 T005: Paper Pusher home cell must be claimed")
		get_tree().quit(1)
		return
	if reality.is_claimed_cell(pocket_cell):
		push_error("US-001 T005: unclaimed cell must not be occupied as Reality")
		get_tree().quit(1)
		return

	var pocket_id: int = reality.spawn_pocket(pocket_cell, Vector2i(2, 2), 8.0)
	if pocket_id < 0:
		push_error("US-001 T005: pocket spawn failed")
		get_tree().quit(1)
		return
	var pocket_world: Vector2 = DungeonGrid.to_world_center(pocket_cell)
	if not reality.is_claimed_world(pocket_world):
		push_error("US-001 T005: Paper Pusher pocket cell must be claimed")
		get_tree().quit(1)
		return
	if not reality.is_position_within_zone(pocket_world):
		push_error("US-001 T005: DM/PP occupancy query must include pockets")
		get_tree().quit(1)
		return

	if reality.collision_shape_2d.shape is CircleShape2D:
		push_error("US-001 T005: occupancy must not use a circle")
		get_tree().quit(1)
		return

	var walker := _make_walker()
	add_child(walker)
	walker.global_position = DungeonGrid.to_world_center(pocket_cell + Vector2i(4, 0))
	if reality.is_claimed_world(walker.global_position):
		walker.global_position = DungeonGrid.to_world_center(Vector2i(interior.end.x - 1, interior.end.y - 1))
	await get_tree().physics_frame
	var into_home: Vector2 = home_world - walker.global_position
	var blocked_by_zone: bool = walker.test_move(walker.transform, into_home)
	if blocked_by_zone:
		push_error("US-001 T005: Reality Area2D must not be a zone wall")
		get_tree().quit(1)
		return
	walker.global_position = home_world
	await get_tree().physics_frame
	if not reality.is_claimed_world(walker.global_position):
		push_error("US-001 T005: walker inside home must occupy Reality")
		get_tree().quit(1)
		return

	var wall := StaticBody2D.new()
	var wall_shape := CollisionShape2D.new()
	var wall_rect := RectangleShape2D.new()
	wall_rect.size = Vector2(64, 64)
	wall_shape.shape = wall_rect
	wall.add_child(wall_shape)
	wall.collision_layer = 1
	add_child(wall)
	wall.global_position = home_world + Vector2(80, 0)
	await get_tree().physics_frame
	if not walker.test_move(walker.transform, Vector2(80, 0)):
		push_error("US-001 T005: walls/buildings must still collide")
		get_tree().quit(1)
		return

	var player_scene: PackedScene = load("res://player/player.tscn")
	var dm_scene: PackedScene = load("res://dm/dm.tscn")
	if player_scene == null or dm_scene == null:
		push_error("US-001 T005: player/dm scenes missing")
		get_tree().quit(1)
		return
	var paper: Node2D = player_scene.instantiate() as Node2D
	var dm: Node2D = dm_scene.instantiate() as Node2D
	add_child(paper)
	add_child(dm)
	paper.global_position = home_world
	dm.global_position = pocket_world
	await get_tree().process_frame
	if not reality.is_claimed_world(paper.global_position):
		push_error("US-001 T005: Paper Pusher must occupy home")
		get_tree().quit(1)
		return
	if not reality.is_claimed_world(dm.global_position):
		push_error("US-001 T005: DM must occupy a Reality pocket")
		get_tree().quit(1)
		return

	PlayerManager.reality_level = 0
	print("US-001 T005 occupancy test passed")
	get_tree().quit(0)

func _make_walker() -> CharacterBody2D:
	var body := CharacterBody2D.new()
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(16, 16)
	shape_node.shape = shape
	body.add_child(shape_node)
	body.collision_layer = 1
	body.collision_mask = 1
	return body
