extends Node

var _dummy_damage: int = 0

func _ready() -> void:
	PlayerHud.turn_on()
	await get_tree().process_frame

	var icon: TextureRect = PlayerHud.get_node_or_null("%StapleIcon") as TextureRect
	var label: Label = PlayerHud.get_node_or_null("%StapleCount") as Label
	if icon == null or label == null:
		_fail("US-005 T001: PP HUD must have staple icon and count")
		return
	if icon.texture == null or not str(icon.texture.resource_path).ends_with("staple_hud_icon.png"):
		_fail("US-005 T001: HUD must use sprites/staple_hud_icon.png")
		return
	if PlayerHud.get_node_or_null("%ManaLabel") != null:
		_fail("US-005 T001: Paper Pusher HUD must not show DM mana")
		return

	var projectiles := Node2D.new()
	projectiles.name = "Projectiles"
	add_child(projectiles)
	var spawner := MultiplayerSpawner.new()
	spawner.set_script(load("res://scripts/projectile_spawner.gd"))
	spawner.name = "ProjectileSpawner"
	spawner.spawn_path = NodePath("..")
	spawner.projectile_scene = load("res://spells/fireball/fireball_spell.tscn")
	projectiles.add_child(spawner)
	await get_tree().process_frame
	if not spawner.has_method("spawn_staple"):
		_fail("US-005 T002: projectile_spawner must expose spawn_staple")
		return

	var fireball: Node = spawner._custom_spawn({
		"shooter_id": 1,
		"position": Vector2.ZERO,
		"target": Vector2(64, 0),
		"radius_bonus": 0,
		"base_damage_bonus": 0,
		"speed_bonus": 0,
	})
	if fireball == null or not (fireball is FireballSpell):
		_fail("US-005 T002: fireball spawn path must still instantiate FireballSpell")
		return
	fireball.free()

	var player: Player = load("res://player/player.tscn").instantiate() as Player
	player.name = "1"
	player.position = Vector2.ZERO
	add_child(player)
	await get_tree().process_frame
	await get_tree().process_frame

	if player.staple_magazine_max != 20 or player.staple_count != 20:
		_fail("US-005 T001: magazine must start at max 20, got %d/%d" % [player.staple_count, player.staple_magazine_max])
		return
	if label.text != "20/20":
		_fail("US-005 T001: HUD must show 20/20, got %s" % label.text)
		return

	var before_spawn: int = _staple_count()
	player.request_fire_staple(Vector2.RIGHT)
	await get_tree().process_frame
	if player.staple_count != 19:
		_fail("US-005 T002: host fire must consume 1 staple, mag is %d" % player.staple_count)
		return
	if label.text != "19/20":
		_fail("US-005 T001: HUD must follow magazine, got %s" % label.text)
		return
	if _staple_count() != before_spawn + 1:
		_fail("US-005 T002: host fire must spawn one staple projectile")
		return

	# Live LMB path (Player._input), not request_fire_staple().
	player.staple_count = 20
	player._replicate_staple_count()
	var lmb := InputEventMouseButton.new()
	lmb.button_index = MOUSE_BUTTON_LEFT
	lmb.pressed = true
	lmb.position = Vector2(64, 64)
	if not player.wants_fire_staple(lmb):
		_fail("US-005 T002: LMB must match fire/primary_click")
		return
	var bar: Control = PlayerHud.get_node_or_null("MarginContainer") as Control
	if bar != null and bar.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("US-005 T002: factory HUD bar must IGNORE mouse so world LMB is not swallowed")
		return
	var before_lmb: int = _staple_count()
	player._input(lmb)
	await get_tree().physics_frame
	await get_tree().process_frame
	if player.staple_count != 19:
		_fail("US-005 T002: live LMB path must consume 1 staple, mag is %d" % player.staple_count)
		return
	if _staple_count() != before_lmb + 1:
		_fail("US-005 T002: live LMB path must spawn a staple projectile")
		return

	var mag_before_melee: int = player.staple_count
	player.start_melee_attack()
	if player.staple_count != mag_before_melee:
		_fail("US-005: melee must not spend staples")
		return
	player._melee_swing_active = true
	var mag_during_swing: int = player.staple_count
	var spawned_during: int = _staple_count()
	player._host_fire_staple(Vector2.RIGHT)
	if player.staple_count != mag_during_swing or _staple_count() != spawned_during:
		_fail("US-005: staple fire must not go through during an active melee pulse")
		return
	await player.get_tree().create_timer(0.2).timeout
	if player._melee_swing_active:
		_fail("US-005: melee pulse must clear _melee_swing_active so LMB can fire after harvest")
		return
	var mag_after_swing: int = player.staple_count
	var spawned_after: int = _staple_count()
	player._host_fire_staple(Vector2.RIGHT)
	if player.staple_count != mag_after_swing - 1 or _staple_count() != spawned_after + 1:
		_fail("US-005: LMB staple fire must work after melee/harvest swing ends")
		return
	await get_tree().physics_frame
	await get_tree().process_frame

	player.staple_count = 0
	player.empty_click_played = false
	var empty_before: int = _staple_count()
	player.request_fire_staple(Vector2.RIGHT)
	await get_tree().process_frame
	if player.staple_count != 0:
		_fail("US-005 T003: empty fire must leave mag at 0, got %d" % player.staple_count)
		return
	if _staple_count() != empty_before:
		_fail("US-005 T003: empty fire must not spawn a projectile")
		return
	if player.empty_click_played:
		_fail("US-005 T003: empty fire must fail silent (no jam/click audio)")
		return

	var dummy := Node2D.new()
	dummy.name = "DummyTarget"
	add_child(dummy)
	dummy.global_position = Vector2(80, 0)
	var hitbox := Hitbox.new()
	hitbox.name = "Hitbox"
	hitbox.collision_layer = 8
	hitbox.collision_mask = 0
	hitbox.monitoring = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 20.0
	shape.shape = circle
	hitbox.add_child(shape)
	dummy.add_child(hitbox)
	hitbox.Damaged.connect(_on_dummy_damaged)
	await get_tree().physics_frame

	_dummy_damage = 0
	var bolt: Node = spawner.spawn_staple({
		"kind": "staple",
		"shooter_id": 1,
		"position": dummy.global_position,
		"direction": Vector2.RIGHT,
		"damage": 1,
		"speed": 0.0,
		"max_range": 64.0,
	})
	if bolt == null:
		_fail("US-005 T002: spawn_staple must return a projectile")
		return
	for _i in 8:
		await get_tree().physics_frame
		await get_tree().process_frame
		if _dummy_damage >= 1 and not is_instance_valid(bolt):
			break
	if _dummy_damage != 1:
		_fail("US-005 T002: staple overlapping a Hitbox must apply 1 damage once, got %d" % _dummy_damage)
		return
	if is_instance_valid(bolt):
		_fail("US-005 T002: staple must be consumed on first valid hit")
		return

	print("US-005 T001-T003 staple fire test passed")
	print("US-005 two-window play pass not run (QA owns it)")
	get_tree().quit(0)

func _staple_count() -> int:
	var n: int = 0
	for node in get_tree().get_nodes_in_group("staple_projectiles"):
		if is_instance_valid(node):
			n += 1
	return n

func _on_dummy_damaged(hurt_box: Hurtbox) -> void:
	_dummy_damage += hurt_box.damage

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
