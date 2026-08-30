extends Node

const TICK := 1.0 / 60.0

func _ready() -> void:
	var player: Player = load("res://player/player.tscn").instantiate() as Player
	player.name = "1"
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.position = Vector2.ZERO
	add_child(player)
	await get_tree().process_frame
	var bar: Node = player.get_node_or_null("HealthBar")
	if bar == null:
		_fail("player must spawn a HealthBar")
		return
	if not (bar as CanvasItem).visible:
		_fail("living player HealthBar must be visible")
		return
	if not is_equal_approx(player.health_ratio(), 1.0):
		_fail("full health ratio must be 1.0")
		return
	player.hitpoints = 3
	if not is_equal_approx(player.health_ratio(), 0.5):
		_fail("3/6 HP must be ratio 0.5, got %s" % player.health_ratio())
		return
	var fill: ColorRect = bar.get_node_or_null("Fill") as ColorRect
	var fill_mid: float = 0.0
	if fill:
		fill_mid = fill.size.x
	var hurt := Hurtbox.new()
	hurt.damage = 1
	add_child(hurt)
	player.take_damage(hurt)
	if player.hitpoints != 2:
		_fail("take_damage must subtract 1 HP, got %s" % player.hitpoints)
		return
	if fill and fill.size.x >= fill_mid - 0.01:
		_fail("health bar fill must shrink after damage")
		return
	player.hitpoints = 0
	if (bar as CanvasItem).visible:
		_fail("HealthBar must hide at 0 HP")
		return
	player.hitpoints = player.max_hp
	if not (bar as CanvasItem).visible:
		_fail("HealthBar must show again at full HP")
		return

	var goblin: Enemy = load("res://monsters/goblin.tscn").instantiate() as Enemy
	goblin.position = Vector2(8, 0)
	goblin.collision_layer = 0
	goblin.collision_mask = 0
	add_child(goblin)
	await get_tree().process_frame
	if goblin.acquire_aggro_target() != player:
		_fail("goblin must aggro the player")
		return
	var hp_before: int = player.hitpoints
	var sm: Node = goblin.get_node_or_null("EnemyStateMachine")
	for _i in range(90):
		if sm:
			sm._process(TICK)
			sm._physics_process(TICK)
		if player.hitpoints < hp_before:
			break
	if player.hitpoints >= hp_before:
		_fail("goblin melee must reduce player HP, still %s" % player.hitpoints)
		return
	if not is_equal_approx(player.health_ratio(), float(player.hitpoints) / float(player.max_hp)):
		_fail("bar ratio must match current HP")
		return

	print("player health bar test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
