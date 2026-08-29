extends Node

# Knightling unlock pickup fires Area2D.body_entered during a physics query flush
# and re-emits fantasy_level_changed. Exclusion shape rebuild must not crash.

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
	pickup.global_position = DungeonGrid.to_world_center(fantasy.home_rect.position)

	var triggered := {"count": 0}
	pickup.body_entered.connect(func(_body: Node) -> void:
		triggered["count"] = int(triggered["count"]) + 1
		DmManager.unlock("knightling")
		fantasy._rebuild_exclusion()
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
		push_error("US-003 exclusion flush: body_entered did not fire")
		get_tree().quit(1)
		return
	var exclusion: Node = fantasy.get_node_or_null("Exclusion")
	if exclusion == null or exclusion.get_child_count() <= 0:
		push_error("US-003 exclusion flush: Exclusion must still exist after deferred rebuild")
		get_tree().quit(1)
		return

	print("US-003 exclusion flush test passed")
	get_tree().quit(0)
