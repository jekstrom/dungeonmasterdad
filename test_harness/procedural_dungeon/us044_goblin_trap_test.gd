extends Node

func _ready() -> void:
	DmUnlocks.reset_unlocks()
	var goblin: Enemy = load("res://monsters/goblin.tscn").instantiate() as Enemy
	goblin.position = Vector2(128, 128)
	goblin.collision_layer = 0
	goblin.collision_mask = 0
	add_child(goblin)
	await get_tree().process_frame
	var trap_node: Node = goblin.get_node_or_null("EnemyStateMachine/trap")
	var idle: EnemyStateIdle = goblin.get_node_or_null("EnemyStateMachine/idle") as EnemyStateIdle
	if trap_node == null or not (trap_node is TrapState) or idle == null:
		return _fail("US-044: goblin TrapState missing from state machine")
	var trap_state: TrapState = trap_node as TrapState
	goblin.trap_cooldown = 0.0
	if goblin.can_lay_trap():
		return _fail("US-044: unowned Random Encounter must not lay traps")
	var before: int = get_tree().get_nodes_in_group("goblin_traps").size()
	trap_state.enter()
	await get_tree().process_frame
	if get_tree().get_nodes_in_group("goblin_traps").size() != before:
		return _fail("US-044: unowned goblin must not spawn a GoblinTrap")
	var idle_next: EnemyState = idle.process(0.0)
	if idle_next == trap_state:
		return _fail("US-044: idle must not enter trap while unowned")

	DmUnlocks.dm_unlocks["random_encounter"] = true
	goblin.trap_cooldown = 0.0
	if not goblin.can_lay_trap():
		return _fail("US-044: owned Random Encounter must allow traps")
	if idle.process(0.0) != trap_state:
		return _fail("US-044: idle must enter trap when owned and ready")
	trap_state.enter()
	await get_tree().process_frame
	var traps: Array = get_tree().get_nodes_in_group("goblin_traps")
	if traps.is_empty():
		return _fail("US-044: owned goblin must spawn GoblinTrap")
	var laid: GoblinTrap = traps[0] as GoblinTrap
	if laid == null:
		return _fail("US-044: spawned node must be GoblinTrap")
	var expected_cell: Vector2i = DungeonGrid.from_world(goblin.global_position)
	var expected: Vector2 = DungeonGrid.to_world(expected_cell) + Vector2(DungeonGrid.CELL_PX * 0.5, DungeonGrid.SPRITE_TOP)
	if not laid.position.is_equal_approx(expected):
		return _fail("US-044: trap must sit on the goblin cell south foot")
	if goblin.can_lay_trap():
		return _fail("US-044: cooldown must block a second trap immediately")

	var hp_script := load("res://player/player.gd") as Script
	var victim := CharacterBody2D.new()
	victim.set_script(hp_script)
	victim.add_to_group("players")
	add_child(victim)
	await get_tree().process_frame
	if "hitpoints" in victim:
		victim.set("invulnerable", false)
		victim.set("hitpoints", 6)
	laid._on_body_entered(victim)
	if not laid.triggered:
		return _fail("US-044: Paper Pusher must spring the trap")
	if "hitpoints" in victim and int(victim.get("hitpoints")) >= 6:
		return _fail("US-044: sprung trap must damage the Paper Pusher")
	if not bool(victim.call("is_stunned")):
		return _fail("US-044: sprung trap must stun the Paper Pusher")
	if float(victim.get("stun_remaining")) < 2.99:
		return _fail("US-044: trap stun must last 3 seconds")
	victim.call("_physics_process", 2.9)
	if not bool(victim.call("is_stunned")):
		return _fail("US-044: stun must still hold before 3 seconds")
	victim.call("_physics_process", 0.2)
	if bool(victim.call("is_stunned")):
		return _fail("US-044: stun must end after 3 seconds")
	laid._on_body_entered(victim)
	if "hitpoints" in victim and int(victim.get("hitpoints")) < 5:
		return _fail("US-044: sprung trap must not keep damaging")

	DmUnlocks.dm_unlocks["random_encounter"] = false
	goblin.trap_cooldown = 0.0
	if goblin.can_lay_trap():
		return _fail("US-044: clearing ownership must restore baseline")

	print("US-044 goblin trap test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
