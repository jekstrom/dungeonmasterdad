extends Node

func _ready() -> void:
	DmManager.fantasy_level = 0
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

	var fantasy: FantasyZone = load("res://zones/fantasy_zone.tscn").instantiate()
	add_child(fantasy)
	await get_tree().process_frame
	await get_tree().physics_frame

	var home_cell: Vector2i = fantasy.home_rect.position
	var home_world: Vector2 = DungeonGrid.to_world_center(home_cell)
	var outside_cell := Vector2i(interior.position.x + 1, interior.position.y + 1)
	if fantasy.is_claimed_cell(outside_cell):
		outside_cell = Vector2i(interior.position.x, interior.position.y)
	var outside_world: Vector2 = DungeonGrid.to_world_center(outside_cell)
	if fantasy.is_claimed_world(outside_world):
		push_error("US-003 T005: west overworld cell must start unclaimed")
		get_tree().quit(1)
		return

	var paper := _make_body(true)
	paper.add_to_group("players")
	add_child(paper)
	paper.global_position = outside_world
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not paper.global_position.is_equal_approx(outside_world) and fantasy.is_claimed_world(paper.global_position):
		push_error("US-003 T005: unclaimed overworld must not displace a Paper Pusher")
		get_tree().quit(1)
		return
	if not paper.test_move(paper.transform, home_world - paper.global_position):
		push_error("US-003 T005: Paper Pusher must stop at the Fantasy boundary")
		get_tree().quit(1)
		return

	var dm := _make_body(false)
	dm.add_to_group("dm")
	add_child(dm)
	dm.global_position = outside_world
	await get_tree().physics_frame
	if dm.test_move(dm.transform, home_world - dm.global_position):
		push_error("US-003 T005: DM must walk into Fantasy-claimed space")
		get_tree().quit(1)
		return
	dm.global_position = home_world
	await get_tree().physics_frame
	if not fantasy.is_claimed_world(dm.global_position):
		push_error("US-003 T005: DM must remain inside Fantasy")
		get_tree().quit(1)
		return

	paper.global_position = home_world
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_instance_valid(paper):
		push_error("US-003 T005: displacement must not kill the Paper Pusher")
		get_tree().quit(1)
		return
	if fantasy.is_claimed_world(paper.global_position):
		push_error("US-003 T005: Paper Pusher inside Fantasy must be pushed out")
		get_tree().quit(1)
		return

	var pocket_id: int = fantasy.spawn_pocket(outside_cell, Vector2i(2, 2), 8.0)
	if pocket_id < 0:
		push_error("US-003 T005: pocket spawn failed")
		get_tree().quit(1)
		return
	await get_tree().physics_frame
	var trapped := _make_body(true)
	trapped.add_to_group("players")
	add_child(trapped)
	trapped.global_position = outside_world
	var trapped_b := _make_body(true)
	trapped_b.add_to_group("players")
	add_child(trapped_b)
	trapped_b.global_position = outside_world
	await get_tree().physics_frame
	await get_tree().physics_frame
	if fantasy.is_claimed_world(trapped.global_position) or fantasy.is_claimed_world(trapped_b.global_position):
		push_error("US-003 T005: pocket covering Paper Pushers must displace them")
		get_tree().quit(1)
		return
	if trapped.global_position.distance_to(trapped_b.global_position) < 1.0:
		push_error("US-003 T005: two Paper Pushers must not share the same escape cell")
		get_tree().quit(1)
		return
	if not is_instance_valid(trapped) or not is_instance_valid(trapped_b):
		push_error("US-003 T005: pocket displacement must not kill")
		get_tree().quit(1)
		return

	DmManager.fantasy_level = 0
	print("US-003 T005 Paper Pusher exclusion test passed")
	get_tree().quit(0)

func _make_body(blocked_by_fantasy: bool) -> CharacterBody2D:
	var body := CharacterBody2D.new()
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(16, 16)
	shape_node.shape = shape
	body.add_child(shape_node)
	body.collision_layer = 1
	body.collision_mask = 16
	if blocked_by_fantasy:
		body.collision_mask = body.collision_mask | 32
	return body
