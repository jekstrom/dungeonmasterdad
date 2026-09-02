extends Node
## US-013: gremlin ≠ goblin spawn; relocate claim/drop; no double-pickup.

func _ready() -> void:
	# T001 / AC8: dedicated scene + sheet
	var gremlin_scene: PackedScene = load("res://monsters/gremlin.tscn") as PackedScene
	var goblin_scene: PackedScene = load("res://monsters/goblin.tscn") as PackedScene
	if gremlin_scene == null:
		return _fail("US-013: monsters/gremlin.tscn missing")
	if gremlin_scene == goblin_scene:
		return _fail("US-013: gremlin scene must not be goblin.tscn")
	var g: Node = gremlin_scene.instantiate()
	add_child(g)
	await get_tree().process_frame
	if not (g is Gremlin):
		return _fail("US-013: instance must be Gremlin class")
	if g.get_script() == load("res://monsters/goblin.tscn"):
		return _fail("US-013: gremlin must not use goblin scene")
	var spr: Sprite2D = g.get_node_or_null("Sprite2D") as Sprite2D
	if spr == null or spr.texture == null:
		return _fail("US-013: gremlin Sprite2D/texture missing")
	var tex_path := str(spr.texture.resource_path)
	if tex_path.find("gremlin.png") == -1:
		return _fail("US-013: sheet must be monsters/gremlin.png got %s" % tex_path)
	if tex_path.find("goblin.png") != -1:
		return _fail("US-013: must not use goblin.png")
	if bool(g.get("raids_buildings")):
		return _fail("US-013: gremlin must not raid buildings")
	if not g.is_in_group("gremlins"):
		return _fail("US-013: must be in group gremlins")

	# Spawner export must point at gremlin scene (playground wiring).
	var spawner_script := load("res://scripts/multiplayer_spawner.gd")
	if spawner_script == null:
		return _fail("US-013: multiplayer_spawner missing")
	var catalog = load("res://scripts/procedural_dungeon/monster_catalog.gd").new()
	var grem_path: String = str(catalog.get_scene_path("gremlin"))
	if grem_path != "res://monsters/gremlin.tscn":
		return _fail("US-013: MonsterCatalog gremlin path wrong: %s" % grem_path)
	if str(catalog.get_scene_path("goblin")) == grem_path:
		return _fail("US-013: catalog must keep goblin distinct")

	# T002/T004: claim + no double-pickup
	var wood: ItemPickup = load("res://pickups/pickup.tscn").instantiate() as ItemPickup
	wood.item_data = load("res://pickups/wood.tres")
	wood.global_position = g.global_position
	add_child(wood)
	await get_tree().process_frame
	wood.can_be_picked_up = true
	wood.grace_time_remaining = 0.0
	if not wood.has_method("claim_for_gremlin"):
		return _fail("US-013: ItemPickup.claim_for_gremlin missing")
	var path1: String = wood.claim_for_gremlin(g)
	if path1 != "res://pickups/wood.tres":
		return _fail("US-013: first claim should get wood, got %s" % path1)
	var path2: String = wood.claim_for_gremlin(g)
	if path2 != "":
		return _fail("US-013: second claim must fail (no double-pickup)")

	# Drop signal preserves identity
	var dropped: Array = []
	var on_drop := func(data: Dictionary) -> void:
		dropped.append(data)
	SignalBus.on_item_drop.connect(on_drop)
	(g as Gremlin).carried_item_path = "res://pickups/wood.tres"
	(g as Gremlin)._drop_carried_now()
	if dropped.is_empty() or str(dropped[0].get("item_type", "")) != "res://pickups/wood.tres":
		return _fail("US-013: drop must emit same item_type")
	if (g as Gremlin).carried_item_path != "":
		return _fail("US-013: carried_item_path must clear after drop")

	# Prefer factory-near pile (FR-007) — score check via two candidates
	var far := Node2D.new()
	far.name = "FarPile"
	far.position = Vector2(800, 0)
	add_child(far)
	var near := Node2D.new()
	near.name = "NearFactoryPile"
	near.position = Vector2(40, 0)
	add_child(near)
	var factory := Node2D.new()
	factory.name = "PaperFactory"
	factory.position = Vector2(50, 0)
	factory.add_to_group("factories")
	add_child(factory)
	g.global_position = Vector2.ZERO
	# Build fake claimable pickups using real ItemPickup
	var p_far: ItemPickup = load("res://pickups/pickup.tscn").instantiate() as ItemPickup
	p_far.item_data = load("res://pickups/paper.tres")
	p_far.global_position = far.global_position
	add_child(p_far)
	var p_near: ItemPickup = load("res://pickups/pickup.tscn").instantiate() as ItemPickup
	p_near.item_data = load("res://pickups/paper.tres")
	p_near.global_position = near.global_position
	add_child(p_near)
	await get_tree().process_frame
	p_far.can_be_picked_up = true
	p_far.grace_time_remaining = 0.0
	p_near.can_be_picked_up = true
	p_near.grace_time_remaining = 0.0
	var chosen: Node2D = (g as Gremlin)._choose_preferred_pickup()
	if chosen != p_near:
		return _fail("US-013: should prefer near-factory pile")

	# James notes (PR #17 follow-up): 2× speed, staple Hitbox, flee PP, walkable clamp.
	var grem := g as Gremlin
	if float(grem.move_speed) < 139.0:
		return _fail("US-013: move_speed must be 2× prior (140), got %s" % grem.move_speed)
	var hitbox: Area2D = g.get_node_or_null("Hitbox") as Area2D
	if hitbox == null:
		return _fail("US-013: Hitbox missing")
	if hitbox.collision_layer != 8:
		return _fail("US-013: Hitbox collision_layer must be 8 for staples, got %s" % hitbox.collision_layer)
	if not hitbox.monitorable:
		return _fail("US-013: Hitbox must be monitorable for staple Hurtbox overlap")
	var hit_shape := hitbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if hit_shape == null or hit_shape.shape == null:
		return _fail("US-013: Hitbox needs CollisionShape2D for staple hits")
	# Flee: fake Paper Pusher nearby — velocity must point away.
	var pp := Node2D.new()
	pp.name = "FakePaperPusher"
	pp.add_to_group("players")
	pp.global_position = grem.global_position + Vector2(40, 0)
	add_child(pp)
	await get_tree().process_frame
	grem.phase = Gremlin.RelocatePhase.SEEK
	grem._target_pickup = p_near  # would otherwise seek rightward toward near pile
	var fled: bool = grem._try_flee_paper_pushers(0.016)
	if not fled:
		return _fail("US-013: must flee Paper Pushers in radius")
	if grem.velocity.x >= -1.0:
		return _fail("US-013: flee velocity should run away from PP (negative X), got %s" % grem.velocity)
	# Walkable clamp helper must be present.
	if not grem.has_method("_clamp_to_walkable"):
		return _fail("US-013: _clamp_to_walkable missing")

	print("US-013 gremlin relocate test passed")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
