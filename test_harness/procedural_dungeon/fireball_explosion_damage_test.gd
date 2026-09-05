extends Node

const BLAST := {
	"type": "fire",
	"damage": 5,
	"radius": 100.0,
}


func _ready() -> void:
	if not await _run_suite():
		return
	print("fireball explosion damage test passed")
	get_tree().quit(0)


func _run_suite() -> bool:
	DmUnlocks.reset_unlocks()
	if DmUnlocks.is_owned("everything_burns"):
		return _fail("fireball PP/building damage must not require everything_burns")
	var level: Node = Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	add_child(level)
	await get_tree().process_frame

	var paper: Player = _make_paper_pusher()
	if paper == null:
		return _fail("failed to instantiate Player")
	add_child(paper)
	paper.global_position = Vector2(16, 16)
	paper.max_hp = 6
	paper.hitpoints = 6
	await get_tree().process_frame

	var far_paper: Player = _make_paper_pusher()
	if far_paper == null:
		return _fail("failed to instantiate far Player")
	add_child(far_paper)
	far_paper.global_position = Vector2(800, 16)
	far_paper.max_hp = 6
	far_paper.hitpoints = 6
	await get_tree().process_frame

	var factory: SmokeFactory = load("res://buildings/buildables/smoke_factory.tscn").instantiate() as SmokeFactory
	factory.position = Vector2(24, 16)
	add_child(factory)
	await get_tree().process_frame
	factory.enable()
	factory.is_ghost = false
	var factory_hp: int = factory.hitpoints

	var ghost: SmokeFactory = load("res://buildings/buildables/smoke_factory.tscn").instantiate() as SmokeFactory
	ghost.name = "ghost"
	ghost.position = Vector2(32, 16)
	add_child(ghost)
	ghost.set_ghost()
	await get_tree().process_frame
	var ghost_hp: int = ghost.hitpoints

	var far_factory: SmokeFactory = load("res://buildings/buildables/smoke_factory.tscn").instantiate() as SmokeFactory
	far_factory.position = Vector2(800, 80)
	add_child(far_factory)
	await get_tree().process_frame
	far_factory.enable()
	far_factory.is_ghost = false
	var far_hp: int = far_factory.hitpoints

	level.handle_explosion(_blast_at(Vector2(16, 16)))
	if paper.hitpoints != 1:
		return _fail("in-radius PP must take fireball damage 6->1, got %d" % paper.hitpoints)
	if far_paper.hitpoints != 6:
		return _fail("out-of-radius PP must be unhurt, got %d" % far_paper.hitpoints)
	if factory.hitpoints != factory_hp - 5:
		return _fail("in-radius building must take fireball damage, got %d want %d" % [factory.hitpoints, factory_hp - 5])
	if ghost.hitpoints != ghost_hp:
		return _fail("ghost building must not take fireball damage")
	if far_factory.hitpoints != far_hp:
		return _fail("out-of-radius building must be unhurt")

	DmUnlocks.unlock("everything_burns")
	paper.hitpoints = 6
	factory.hitpoints = factory_hp
	level.handle_explosion(_blast_at(Vector2(16, 16)))
	if paper.hitpoints != 1:
		return _fail("everything_burns must not change PP fireball damage, got %d" % paper.hitpoints)
	if factory.hitpoints != factory_hp - 5:
		return _fail("everything_burns must not change building fireball damage, got %d" % factory.hitpoints)

	var dummy := Node2D.new()
	dummy.name = "pencil"
	add_child(dummy)
	var player_hurt := Hurtbox.new()
	player_hurt.damage = 4
	dummy.add_child(player_hurt)
	var raid_hp: int = factory.hitpoints
	factory.take_damage(player_hurt)
	if factory.hitpoints != raid_hp:
		return _fail("non-goblin melee must still not chip buildings")
	return true


func _blast_at(origin: Vector2) -> Dictionary:
	return {
		"type": BLAST["type"],
		"damage": BLAST["damage"],
		"radius": BLAST["radius"],
		"position": origin,
	}


func _make_paper_pusher() -> Player:
	var packed: PackedScene = load("res://player/player.tscn") as PackedScene
	if packed == null:
		return null
	var node: Node = packed.instantiate()
	if node is Player:
		return node as Player
	return null


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
