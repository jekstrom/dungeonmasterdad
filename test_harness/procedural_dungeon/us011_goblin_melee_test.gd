extends Node

const TICK := 1.0 / 60.0

func _ready() -> void:
	if not multiplayer.is_server():
		_fail("US-011 T003: offline peer must be server")
		return

	var factory: SmokeFactory = load("res://buildings/buildables/smoke_factory.tscn").instantiate() as SmokeFactory
	factory.position = Vector2.ZERO
	add_child(factory)
	await get_tree().process_frame
	factory.enable()
	factory.is_ghost = false
	if factory.hitpoints != 8:
		_fail("US-011 T003: smoke factory must start at 8 HP")
		return

	var goblin: Enemy = load("res://monsters/goblin.tscn").instantiate() as Enemy
	goblin.position = Vector2(40, 40)
	goblin.collision_layer = 0
	goblin.collision_mask = 0
	add_child(goblin)
	await get_tree().process_frame
	var sm: Node = goblin.get_node_or_null("EnemyStateMachine")
	if sm:
		sm.process_mode = Node.PROCESS_MODE_DISABLED
	if goblin.acquire_aggro_target() != factory:
		_fail("US-011 T003: goblin must target the factory")
		return
	if not goblin.can_melee_current_target():
		_fail("US-011 T003: goblin must be in melee range of the factory")
		return
	var hurtbox: Hurtbox = goblin.get_node_or_null("Hurtbox") as Hurtbox
	if hurtbox == null:
		_fail("US-011 T003: goblin must have a Hurtbox")
		return
	factory.take_damage(hurtbox)
	if factory.hitpoints != 7:
		_fail("US-011 T003: one goblin pulse must drop HP by 1, got %s" % factory.hitpoints)
		return
	if factory.destroyed or not factory.is_operating():
		_fail("US-011 T003: factory must still operate after one hit")
		return

	var ghost: SmokeFactory = load("res://buildings/buildables/smoke_factory.tscn").instantiate() as SmokeFactory
	ghost.name = "ghost"
	ghost.position = Vector2(80, 0)
	add_child(ghost)
	ghost.set_ghost()
	await get_tree().process_frame
	var ghost_hp: int = ghost.hitpoints
	ghost.take_damage(hurtbox)
	if ghost.hitpoints != ghost_hp:
		_fail("US-011 T003: ghost factory must take no damage")
		return

	var dummy := Node2D.new()
	dummy.name = "pencil"
	add_child(dummy)
	var player_hurt := Hurtbox.new()
	player_hurt.damage = 4
	dummy.add_child(player_hurt)
	var hp_before: int = factory.hitpoints
	factory.take_damage(player_hurt)
	if factory.hitpoints != hp_before:
		_fail("US-011 T003: non-goblin hurtbox must not chip the factory")
		return

	for _i in range(6):
		factory.take_damage(hurtbox)
	if factory.hitpoints != 1:
		_fail("US-011 T003: seven pulses from 8 must leave 1 HP, got %s" % factory.hitpoints)
		return
	if not factory.is_operating():
		_fail("US-011 T003: factory at 1 HP must still produce")
		return

	print("US-011 T003 goblin melee test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
