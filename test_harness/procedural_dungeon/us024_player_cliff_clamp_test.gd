extends Node

func _ready() -> void:
	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	add_child(level)
	await get_tree().process_frame

	var interior := Rect2i(0, 0, 4, 4)
	level.apply_map_interior(interior)
	await get_tree().process_frame

	var body := CharacterBody2D.new()
	add_child(body)
	body.global_position = Vector2(-400, 64)
	body.velocity = Vector2(-200, 0)
	level.enforce_body_interior(body)
	if not level.map_bounds.is_world_position_walkable(body.global_position):
		push_error("US-024 T007: west push was not clamped to walkable bounds")
		get_tree().quit(1)
		return
	var origin: Vector2 = DungeonGrid.to_world(interior.position)
	if body.global_position.x >= origin.x:
		push_error("US-024 T007: clamp must allow walking west of the cell origin to the cliff lip")
		get_tree().quit(1)
		return
	if not body.velocity.is_equal_approx(Vector2.ZERO):
		push_error("US-024 T007: clamp should zero velocity")
		get_tree().quit(1)
		return

	body.global_position = Vector2(200, 900)
	level.enforce_body_interior(body)
	if not level.map_bounds.is_world_position_walkable(body.global_position):
		push_error("US-024 T007: south push was not clamped to walkable bounds")
		get_tree().quit(1)
		return

	var inside := Vector2(200, 200)
	body.global_position = inside
	body.velocity = Vector2(10, 0)
	level.enforce_body_interior(body)
	if not body.global_position.is_equal_approx(inside):
		push_error("US-024 T007: interior position should not move")
		get_tree().quit(1)
		return
	if not body.velocity.is_equal_approx(Vector2(10, 0)):
		push_error("US-024 T007: interior velocity should stay")
		get_tree().quit(1)
		return

	var outside := Vector2(-500, -500)
	var clamped: Vector2 = level.clamp_world_to_interior(outside)
	if not level.map_bounds.is_world_position_walkable(clamped):
		push_error("US-024 T007: clamp_world_to_interior missed")
		get_tree().quit(1)
		return
	if not is_instance_valid(body):
		push_error("US-024 T007: clamp must not free the body")
		get_tree().quit(1)
		return

	print("US-024 T007 player cliff clamp test passed")
	get_tree().quit(0)
