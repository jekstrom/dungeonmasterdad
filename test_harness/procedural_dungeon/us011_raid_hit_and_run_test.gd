extends Node

const TICK := 1.0 / 60.0

func _ready() -> void:
	if not multiplayer.is_server():
		_fail("US-011 hit-and-run: offline peer must be server")
		return

	var factory: SmokeFactory = load("res://buildings/buildables/smoke_factory.tscn").instantiate() as SmokeFactory
	factory.position = Vector2(320, 0)
	add_child(factory)
	await get_tree().process_frame
	factory.enable()
	factory.is_ghost = false

	var goblin: Enemy = load("res://monsters/goblin.tscn").instantiate() as Enemy
	goblin.position = Vector2.ZERO
	goblin.collision_layer = 0
	goblin.collision_mask = 0
	add_child(goblin)
	await get_tree().process_frame
	if goblin.acquire_aggro_target() != factory:
		_fail("US-011 hit-and-run: goblin must raid the factory")
		return

	var origin: Vector2 = factory.factory_origin()
	var start_dist: float = goblin.global_position.distance_to(origin)
	_tick_goblin(goblin, 50)
	var approach_dist: float = goblin.global_position.distance_to(origin)
	if approach_dist >= start_dist - 24.0:
		_fail("US-011 hit-and-run: goblin must close on the factory first, %s -> %s" % [start_dist, approach_dist])
		return

	var hp_before: int = factory.hitpoints
	var dist_at_hit: float = -1.0
	for _i in range(180):
		_tick_goblin(goblin, 1)
		if factory.destroyed or factory.hitpoints < hp_before:
			dist_at_hit = goblin.global_position.distance_to(origin)
			break
	if dist_at_hit < 0.0:
		_fail("US-011 hit-and-run: strike must damage the factory, hp %s dist %s" % [
			factory.hitpoints,
			goblin.global_position.distance_to(origin),
		])
		return
	var saw_retreat := false
	for _k in range(90):
		_tick_goblin(goblin, 1)
		if goblin.global_position.distance_to(origin) >= dist_at_hit + 40.0:
			saw_retreat = true
			break
	if not saw_retreat:
		_fail("US-011 hit-and-run: after a landed hit the goblin must run a short distance away, at_hit=%s now=%s" % [
			dist_at_hit,
			goblin.global_position.distance_to(origin),
		])
		return

	var retreat_dist: float = goblin.global_position.distance_to(origin)
	var closed_again := false
	var nearest_after: float = retreat_dist
	for _j in range(120):
		_tick_goblin(goblin, 1)
		var d2: float = goblin.global_position.distance_to(origin)
		if d2 < nearest_after:
			nearest_after = d2
		if d2 <= retreat_dist - 16.0:
			closed_again = true
			break
	if not closed_again:
		_fail("US-011 hit-and-run: goblin must close again after retreating, %s -> %s" % [retreat_dist, nearest_after])
		return
	if goblin.global_position.distance_to(origin) < 16.0:
		_fail("US-011 hit-and-run: goblin must stand next to the factory, not on its origin")
		return

	if not await _assert_north_side_raid():
		return

	print("US-011 hit-and-run raid test passed")
	get_tree().quit(0)

func _assert_north_side_raid() -> bool:
	var factory: SmokeFactory = load("res://buildings/buildables/smoke_factory.tscn").instantiate() as SmokeFactory
	factory.position = Vector2(0, 0)
	add_child(factory)
	await get_tree().process_frame
	factory.enable()
	factory.is_ghost = false
	var origin: Vector2 = factory.factory_origin()
	var goblin: Enemy = load("res://monsters/goblin.tscn").instantiate() as Enemy
	goblin.position = origin + Vector2(0, -220)
	add_child(goblin)
	await get_tree().process_frame
	await get_tree().physics_frame
	if goblin.acquire_aggro_target() != factory:
		_fail("US-011 hit-and-run: north goblin must raid the factory")
		return false
	var hp_before: int = factory.hitpoints
	for _i in range(240):
		_tick_goblin(goblin, 1)
		if factory.destroyed or factory.hitpoints < hp_before:
			break
	if factory.hitpoints >= hp_before and not factory.destroyed:
		_fail("US-011 hit-and-run: north-side raid must damage the factory, hp %s dist %s" % [
			factory.hitpoints,
			goblin.global_position.distance_to(origin),
		])
		return false
	var dist_at_hit: float = goblin.global_position.distance_to(origin)
	var retreated := false
	for _k in range(90):
		_tick_goblin(goblin, 1)
		if goblin.global_position.distance_to(origin) >= dist_at_hit + 24.0:
			retreated = true
			break
	if not retreated:
		_fail("US-011 hit-and-run: north-side raid must retreat after a hit, dist %s" % goblin.global_position.distance_to(origin))
		return false
	return true

func _tick_goblin(goblin: Enemy, ticks: int) -> void:
	var sm: Node = goblin.get_node_or_null("EnemyStateMachine")
	for _i in ticks:
		if sm:
			sm._process(TICK)
			sm._physics_process(TICK)
		goblin._physics_process(TICK)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
