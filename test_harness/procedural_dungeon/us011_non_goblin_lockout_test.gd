extends Node

func _ready() -> void:
	var factory: PaperFactory = load("res://buildings/buildables/paper_factory.tscn").instantiate() as PaperFactory
	add_child(factory)
	await get_tree().process_frame
	factory.enable()
	factory.is_ghost = false
	if factory.hitpoints != 12:
		_fail("US-011 T005: paper factory must start at 12 HP")
		return

	var skeleton: Enemy = load("res://monsters/skeleton/skeleton.tscn").instantiate() as Enemy
	skeleton.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(skeleton)
	await get_tree().process_frame
	if skeleton.raids_buildings:
		_fail("US-011 T005: skeleton raids_buildings must be false")
		return
	var sk_hurt: Hurtbox = skeleton.get_node_or_null("Hurtbox") as Hurtbox
	if sk_hurt:
		factory.take_damage(sk_hurt)
	if factory.hitpoints != 12:
		_fail("US-011 T005: skeleton must not damage buildings")
		return

	var knight: Enemy = load("res://monsters/knight/knight.tscn").instantiate() as Enemy
	knight.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(knight)
	await get_tree().process_frame
	if knight.raids_buildings:
		_fail("US-011 T005: knight raids_buildings must be false")
		return
	var kn_hurt: Hurtbox = knight.get_node_or_null("Hurtbox") as Hurtbox
	if kn_hurt:
		factory.take_damage(kn_hurt)
	if factory.hitpoints != 12:
		_fail("US-011 T005: knight must not damage buildings")
		return

	var dummy := Node2D.new()
	dummy.name = "AttackHurtboxOwner"
	add_child(dummy)
	var pencil := Hurtbox.new()
	pencil.damage = 3
	dummy.add_child(pencil)
	factory.take_damage(pencil)
	if factory.hitpoints != 12:
		_fail("US-011 T005: Paper Pusher melee must not damage buildings")
		return

	var goblin: Enemy = load("res://monsters/goblin.tscn").instantiate() as Enemy
	add_child(goblin)
	await get_tree().process_frame
	if not goblin.raids_buildings:
		_fail("US-011 T005: goblin raids_buildings must be true")
		return
	var gb_hurt: Hurtbox = goblin.get_node("Hurtbox") as Hurtbox
	factory.take_damage(gb_hurt)
	if factory.hitpoints != 11:
		_fail("US-011 T005: goblin melee must still drop HP by 1, got %s" % factory.hitpoints)
		return

	print("US-011 T005 non-goblin lockout test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
