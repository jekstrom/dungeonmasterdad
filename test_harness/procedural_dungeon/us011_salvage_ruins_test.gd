extends Node

const IRON := "res://pickups/metal.tres"

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.max_inv_slots = 8
	PlayerManager.register_player(1, "Paper Pusher")

	var goblin: Enemy = load("res://monsters/goblin.tscn").instantiate() as Enemy
	add_child(goblin)
	await get_tree().process_frame
	var hurtbox: Hurtbox = goblin.get_node("Hurtbox") as Hurtbox

	var factory: SmokeFactory = load("res://buildings/buildables/smoke_factory.tscn").instantiate() as SmokeFactory
	factory.position = Vector2.ZERO
	add_child(factory)
	await get_tree().process_frame
	factory.enable()
	factory.is_ghost = false
	factory.destroy()
	await get_tree().process_frame
	if not factory.destroyed or factory.is_operating():
		_fail("US-011 salvage: factory must be ruins before mining")
		return
	if factory.salvage_hits_required != 4:
		_fail("US-011 salvage: ruins must take 4 hits like a mine")
		return

	var player: Player = Player.new()
	player.name = "1"
	player.position = factory.global_position
	if not factory.is_harvest_prompt_target(player):
		_fail("US-011 salvage: nearby ruins must prompt SPACE")
		return
	if not factory.apply_harvest_hit(player):
		_fail("US-011 salvage: first harvest hit must apply")
		return
	if factory.salvage_hits_taken != 1:
		_fail("US-011 salvage: after 1 hit salvage_hits_taken must be 1, got %d" % factory.salvage_hits_taken)
		return
	FactoryStatusHud._process(0.0)
	if not FactoryStatusHud.mine_bar_visible(factory):
		_fail("US-011 salvage: first hit must show harvest progress")
		return
	factory.take_damage(hurtbox)
	if factory.salvage_hits_taken != 1:
		_fail("US-011 salvage: goblin must not mine ruins")
		return
	var dm: DM = DM.new()
	dm.position = factory.global_position
	if factory.apply_harvest_hit(dm):
		_fail("US-011 salvage: DM must not mine ruins")
		return
	factory.apply_harvest_hit(player)
	factory.apply_harvest_hit(player)
	if factory.salvage_hits_taken != 3:
		_fail("US-011 salvage: three hits must leave 3, got %d" % factory.salvage_hits_taken)
		return
	if not factory.apply_harvest_hit(player):
		_fail("US-011 salvage: fourth hit must complete salvage")
		return
	if PlayerManager.get_item_count(1, IRON) != 1:
		_fail("US-011 salvage: completing salvage must grant 1 iron, got %d" % PlayerManager.get_item_count(1, IRON))
		return
	await get_tree().process_frame
	if is_instance_valid(factory):
		_fail("US-011 salvage: ruins must be removed after the iron grant")
		return

	var irs: IrsBuilding = load("res://buildings/buildables/irs.tscn").instantiate() as IrsBuilding
	add_child(irs)
	await get_tree().process_frame
	irs.enable()
	irs.is_ghost = false
	irs.destroy()
	await get_tree().process_frame
	irs.salvage_hits_taken = 3
	if not irs.apply_harvest_hit(player):
		_fail("US-011 salvage: IRS ruins must also mine for iron")
		return
	if PlayerManager.get_item_count(1, IRON) != 2:
		_fail("US-011 salvage: IRS salvage must grant another iron, got %d" % PlayerManager.get_item_count(1, IRON))
		return
	await get_tree().process_frame
	if is_instance_valid(irs):
		_fail("US-011 salvage: IRS ruins must be removed")
		return

	print("US-011 salvage ruins test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
