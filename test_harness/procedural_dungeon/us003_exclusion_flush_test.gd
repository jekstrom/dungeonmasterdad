extends Node

# Knightling unlock pickup fires Area2D.body_entered during a physics query flush
# and re-emits fantasy_level_changed. Deferred home-rect collision must not crash.
# T005 Exclusion rebuild is gone; Paper Pushers may stand in Fantasy.

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
	var paper := CharacterBody2D.new()
	paper.add_to_group("players")
	var paper_shape := CollisionShape2D.new()
	var paper_rect := RectangleShape2D.new()
	paper_rect.size = Vector2(16, 16)
	paper_shape.shape = paper_rect
	paper.add_child(paper_shape)
	paper.collision_layer = 1
	paper.collision_mask = 16
	add_child(paper)
	paper.global_position = home_world

	var pickup := Area2D.new()
	pickup.monitoring = true
	pickup.monitorable = true
	pickup.collision_layer = 1
	pickup.collision_mask = 1
	var pickup_shape := CollisionShape2D.new()
	var pickup_rect := RectangleShape2D.new()
	pickup_rect.size = Vector2(64, 64)
	pickup_shape.shape = pickup_rect
	pickup.add_child(pickup_shape)
	add_child(pickup)
	pickup.global_position = home_world

	var triggered := {"count": 0}
	pickup.body_entered.connect(func(_body: Node) -> void:
		triggered["count"] = int(triggered["count"]) + 1
		DmManager.unlock("knightling")
	)

	var body := CharacterBody2D.new()
	var body_shape := CollisionShape2D.new()
	var body_rect := RectangleShape2D.new()
	body_rect.size = Vector2(16, 16)
	body_shape.shape = body_rect
	body.add_child(body_shape)
	body.collision_layer = 1
	body.collision_mask = 1
	add_child(body)
	body.global_position = pickup.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame

	if int(triggered["count"]) <= 0:
		push_error("US-003 T011 exclusion flush: body_entered did not fire")
		get_tree().quit(1)
		return
	if fantasy.get_node_or_null("Exclusion") != null:
		push_error("US-003 T011 exclusion flush: Exclusion wall must not exist after unlock rebuild")
		get_tree().quit(1)
		return
	if not is_instance_valid(paper) or not fantasy.is_claimed_world(paper.global_position):
		push_error("US-003 T011 exclusion flush: Paper Pusher must still stand in Fantasy after unlock")
		get_tree().quit(1)
		return
	if not paper.global_position.is_equal_approx(home_world):
		push_error("US-003 T011 exclusion flush: Paper Pusher must not be snapped out during deferred collision")
		get_tree().quit(1)
		return

	print("US-003 exclusion flush test passed")
	get_tree().quit(0)
