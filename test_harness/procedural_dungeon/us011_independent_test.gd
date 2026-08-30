extends Node

const TICK := 1.0 / 60.0

func _ready() -> void:
	PlayerManager.smoke_amt = 2
	var factory: SmokeFactory = load("res://buildings/buildables/smoke_factory.tscn").instantiate() as SmokeFactory
	factory.position = Vector2(240, 0)
	add_child(factory)
	await get_tree().process_frame
	factory.enable()
	factory.is_ghost = false
	factory.set_process(false)

	var goblin: Enemy = load("res://monsters/goblin.tscn").instantiate() as Enemy
	goblin.position = Vector2.ZERO
	goblin.collision_layer = 0
	goblin.collision_mask = 0
	add_child(goblin)
	await get_tree().process_frame
	if goblin.acquire_aggro_target() != factory:
		_fail("US-011 independent: goblin must path to the factory")
		return
	_tick_goblin(goblin, 30)
	if goblin.global_position.x <= 1.0:
		_fail("US-011 independent: goblin must move toward the factory")
		return
	var hurtbox: Hurtbox = goblin.get_node("Hurtbox") as Hurtbox
	var hp_start: int = factory.hitpoints
	factory.take_damage(hurtbox)
	if factory.hitpoints >= hp_start:
		_fail("US-011 independent: factory HP must drop")
		return
	while factory.hitpoints > 0 and not factory.destroyed:
		factory.take_damage(hurtbox)
	if not factory.destroyed or factory.is_operating():
		_fail("US-011 independent: factory must be removed from production at 0 HP")
		return
	var smoke_before: int = PlayerManager.smoke_amt
	factory._process(factory.interval)
	if PlayerManager.smoke_amt != smoke_before:
		_fail("US-011 independent: destroyed factory must not produce")
		return
	goblin.die()
	goblin.queue_free()
	await get_tree().process_frame

	var saved: SmokeFactory = load("res://buildings/buildables/smoke_factory.tscn").instantiate() as SmokeFactory
	saved.position = Vector2(80, 80)
	add_child(saved)
	await get_tree().process_frame
	saved.enable()
	saved.is_ghost = false
	var raider: Enemy = load("res://monsters/goblin.tscn").instantiate() as Enemy
	raider.position = Vector2(80, 80)
	raider.collision_layer = 0
	raider.collision_mask = 0
	add_child(raider)
	var raider_sm: Node = raider.get_node_or_null("EnemyStateMachine")
	if raider_sm:
		raider_sm.process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().process_frame
	var player := Node2D.new()
	player.add_to_group("players")
	player.position = Vector2(80, 80)
	add_child(player)
	if raider.acquire_aggro_target() != player:
		_fail("US-011 independent: damaging / nearby Paper Pusher must pull aggro off the factory")
		return
	raider.die()
	await get_tree().process_frame
	if saved.destroyed or saved.hitpoints != saved.max_hitpoints:
		_fail("US-011 independent: killing the goblin must save the factory")
		return
	if not saved.is_operating():
		_fail("US-011 independent: saved factory must still operate")
		return

	print("US-011 independent test passed")
	get_tree().quit(0)

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
