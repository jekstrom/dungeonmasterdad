extends Node

const TICK := 1.0 / 60.0
const CHASE_TICKS := 40

func _ready() -> void:
	if not multiplayer.is_server():
		_fail("US-011 T002: offline peer must be server")
		return

	var factory: SmokeFactory = load("res://buildings/buildables/smoke_factory.tscn").instantiate() as SmokeFactory
	factory.position = Vector2(400, 0)
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
	if not goblin.raids_buildings:
		_fail("US-011 T002: goblin raids_buildings must be true")
		return
	if goblin.acquire_aggro_target() != factory:
		_fail("US-011 T002: goblin must acquire the enabled factory")
		return
	var start: Vector2 = goblin.global_position
	_tick_goblin(goblin, CHASE_TICKS)
	if goblin.global_position.distance_to(factory.factory_origin()) >= start.distance_to(factory.factory_origin()) - 8.0:
		_fail("US-011 T002: goblin must move closer to the factory")
		return

	goblin.queue_free()
	factory.queue_free()
	await get_tree().process_frame

	var ghost: SmokeFactory = load("res://buildings/buildables/smoke_factory.tscn").instantiate() as SmokeFactory
	ghost.name = "ghost"
	ghost.position = Vector2(200, 0)
	add_child(ghost)
	ghost.set_ghost()
	await get_tree().process_frame
	var wanderer: Enemy = load("res://monsters/goblin.tscn").instantiate() as Enemy
	wanderer.position = Vector2.ZERO
	wanderer.collision_layer = 0
	wanderer.collision_mask = 0
	add_child(wanderer)
	await get_tree().process_frame
	if wanderer.acquire_aggro_target() == ghost:
		_fail("US-011 T002: goblin must ignore ghost factories")
		return
	wanderer.queue_free()
	ghost.queue_free()
	await get_tree().process_frame

	var paper: PaperFactory = load("res://buildings/buildables/paper_factory.tscn").instantiate() as PaperFactory
	paper.position = Vector2(300, 0)
	add_child(paper)
	await get_tree().process_frame
	paper.enable()
	paper.is_ghost = false
	var irs: IrsBuilding = load("res://buildings/buildables/irs.tscn").instantiate() as IrsBuilding
	irs.position = Vector2(80, 0)
	add_child(irs)
	await get_tree().process_frame
	irs.enable()
	irs.is_ghost = false
	var chooser: Enemy = load("res://monsters/goblin.tscn").instantiate() as Enemy
	chooser.position = Vector2.ZERO
	chooser.collision_layer = 0
	chooser.collision_mask = 0
	add_child(chooser)
	await get_tree().process_frame
	if chooser.acquire_aggro_target() != paper:
		_fail("US-011 T002: goblin must prefer factories over IRS")
		return
	paper.queue_free()
	await get_tree().process_frame
	if chooser.acquire_aggro_target() != irs:
		_fail("US-011 T002: goblin must raid IRS when no factory exists")
		return

	var player := Node2D.new()
	player.name = "pp"
	player.add_to_group("players")
	player.position = chooser.global_position
	add_child(player)
	await get_tree().process_frame
	if chooser.acquire_aggro_target() != player:
		_fail("US-011 T002: player in screen range must beat raid")
		return

	var knight: Enemy = load("res://monsters/knight/knight.tscn").instantiate() as Enemy
	knight.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(knight)
	await get_tree().process_frame
	if knight.raids_buildings:
		_fail("US-011 T002: knight raids_buildings must be false")
		return
	var skeleton: Enemy = load("res://monsters/skeleton/skeleton.tscn").instantiate() as Enemy
	skeleton.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(skeleton)
	await get_tree().process_frame
	if skeleton.raids_buildings:
		_fail("US-011 T002: skeleton raids_buildings must be false")
		return
	if skeleton.acquire_aggro_target() == irs:
		_fail("US-011 T002: skeleton must not acquire buildings")
		return

	print("US-011 T002 raid targeting test passed")
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
