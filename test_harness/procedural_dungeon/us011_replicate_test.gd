extends Node

func _ready() -> void:
	var factory: SmokeFactory = load("res://buildings/buildables/smoke_factory.tscn").instantiate() as SmokeFactory
	add_child(factory)
	await get_tree().process_frame
	factory.enable()
	factory.is_ghost = false
	var sync: MultiplayerSynchronizer = factory.get_node_or_null("MultiplayerSynchronizer") as MultiplayerSynchronizer
	if sync == null or sync.replication_config == null:
		_fail("US-011 T006: factory must have MultiplayerSynchronizer")
		return
	var config: SceneReplicationConfig = sync.replication_config
	if not config.has_property(NodePath(".:hitpoints")):
		_fail("US-011 T006: replication config must include hitpoints")
		return
	if not config.has_property(NodePath(".:destroyed")):
		_fail("US-011 T006: replication config must include destroyed")
		return

	var goblin: Enemy = load("res://monsters/goblin.tscn").instantiate() as Enemy
	add_child(goblin)
	await get_tree().process_frame
	var hurtbox: Hurtbox = goblin.get_node("Hurtbox") as Hurtbox
	factory.take_damage(hurtbox)
	if factory.hitpoints != 7:
		_fail("US-011 T006: host take_damage must stick")
		return
	var bar: Node = factory.get_node_or_null("HealthBar")
	if bar == null or not bar.has_method("set_health_ratio"):
		_fail("US-011 T006: health bar must exist for replicated HP")
		return

	var replica: SmokeFactory = load("res://buildings/buildables/smoke_factory.tscn").instantiate() as SmokeFactory
	add_child(replica)
	await get_tree().process_frame
	replica.enable()
	replica.is_ghost = false
	replica.apply_timer_sync_dict(factory.to_timer_sync_dict())
	if replica.hitpoints != 7:
		_fail("US-011 T006: late-join payload must copy hitpoints, got %s" % replica.hitpoints)
		return

	var client_like: SmokeFactory = load("res://buildings/buildables/smoke_factory.tscn").instantiate() as SmokeFactory
	add_child(client_like)
	await get_tree().process_frame
	client_like.enable()
	client_like.is_ghost = false
	client_like.set_process(false)
	client_like.hitpoints = 0
	if client_like.destroyed:
		_fail("US-011 T006: assigning hitpoints=0 must not destroy")
		return
	if not client_like.is_operating():
		_fail("US-011 T006: HP write without destroy must leave the factory operating")
		return
	var smoke_before: int = PlayerManager.smoke_amt
	client_like._process(client_like.interval)
	if PlayerManager.smoke_amt <= smoke_before:
		_fail("US-011 T006: operating factory after fake HP write must still produce")
		return

	while factory.hitpoints > 0 and not factory.destroyed:
		factory.take_damage(hurtbox)
	if not factory.destroyed:
		_fail("US-011 T006: host destroy must set destroyed")
		return
	var join_copy: SmokeFactory = load("res://buildings/buildables/smoke_factory.tscn").instantiate() as SmokeFactory
	add_child(join_copy)
	await get_tree().process_frame
	join_copy.enable()
	join_copy.is_ghost = false
	join_copy.apply_timer_sync_dict(factory.to_timer_sync_dict())
	if not join_copy.destroyed or join_copy.is_operating():
		_fail("US-011 T006: late join must see destroyed rubble factory")
		return
	var rubble: Sprite2D = join_copy.get_node("Sprite2D") as Sprite2D
	if rubble == null or rubble.texture == null or rubble.texture.resource_path.find("smoke_factory_rubble") < 0:
		_fail("US-011 T006: late join must apply rubble texture")
		return

	var paper: PaperFactory = load("res://buildings/buildables/paper_factory.tscn").instantiate() as PaperFactory
	add_child(paper)
	await get_tree().process_frame
	var paper_sync: MultiplayerSynchronizer = paper.get_node("MultiplayerSynchronizer") as MultiplayerSynchronizer
	if not paper_sync.replication_config.has_property(NodePath(".:stored_wood")):
		_fail("US-011 T006: must not drop stored_wood replication")
		return
	if not paper_sync.replication_config.has_property(NodePath(".:hitpoints")):
		_fail("US-011 T006: paper factory must replicate hitpoints")
		return

	print("US-011 T006 replicate test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
