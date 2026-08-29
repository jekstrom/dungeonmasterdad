extends Node

var _dummy_damage: int = 0
var _building_damage: int = 0

func _ready() -> void:
	PlayerHud.turn_on()
	await get_tree().process_frame

	var icon: TextureRect = PlayerHud.get_node_or_null("%StapleIcon") as TextureRect
	var label: Label = PlayerHud.get_node_or_null("%StapleCount") as Label
	if icon == null or label == null:
		_fail("US-005 T001: PP HUD must have staple icon and count")
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

	var player: Player = load("res://player/player.tscn").instantiate() as Player
	player.name = "1"
	player.position = Vector2.ZERO
	add_child(player)
	await get_tree().process_frame
	await get_tree().process_frame

	if player.staple_magazine_max != 20 or player.staple_count != 20:
		_fail("US-005 T010: magazine must start at max 20, got %d/%d" % [player.staple_count, player.staple_magazine_max])
		return
	if label.text != "20/20":
		_fail("US-005 T010: HUD must show 20/20, got %s" % label.text)
		return
	if not player.combat_sheet_path().ends_with("player_staple_gun.png"):
		_fail("US-005 T008: ranged idle must use player_staple_gun.png, got %s" % player.combat_sheet_path())
		return
	if player.combat_sheet_path().ends_with("PlayerSprite02.png"):
		_fail("US-005 T008: must not stretch the sword sheet into a gun")
		return

	var before_spawn: int = _staple_count()
	player.request_fire_staple(Vector2.RIGHT)
	await get_tree().process_frame
	if player.staple_count != 19:
		_fail("US-005 T010: fire with ammo must consume 1, mag is %d" % player.staple_count)
		return
	if label.text != "19/20":
		_fail("US-005 T010: HUD must follow magazine, got %s" % label.text)
		return
	if _staple_count() != before_spawn + 1:
		_fail("US-005 T010: fire must spawn one staple projectile")
		return

	player.staple_count = 1
	player._replicate_staple_count()
	var last_before: int = _staple_count()
	player.request_fire_staple(Vector2.RIGHT)
	await get_tree().process_frame
	if player.staple_count != 0:
		_fail("US-005 T010: last staple must leave mag at 0, got %d" % player.staple_count)
		return
	if _staple_count() != last_before + 1:
		_fail("US-005 T010: last staple must spawn exactly one projectile")
		return

	player.empty_click_played = false
	var empty_before: int = _staple_count()
	player.request_fire_staple(Vector2.RIGHT)
	await get_tree().process_frame
	if player.staple_count != 0:
		_fail("US-005 T010: empty fire must leave mag at 0, got %d" % player.staple_count)
		return
	if _staple_count() != empty_before:
		_fail("US-005 T010: empty fire must not spawn a projectile")
		return
	if player.empty_click_played:
		_fail("US-005 T010: empty fire must fail silent (no jam/click audio)")
		return

	var range_bolt: Node = spawner.spawn_staple({
		"kind": "staple",
		"shooter_id": 1,
		"position": Vector2(-400, -400),
		"direction": Vector2.RIGHT,
		"damage": 1,
		"speed": 800.0,
		"max_range": 12.0,
	})
	if range_bolt == null:
		_fail("US-005 T010: spawn_staple must return a projectile")
		return
	for _i in 20:
		await get_tree().process_frame
		if not is_instance_valid(range_bolt):
			break
	if is_instance_valid(range_bolt):
		_fail("US-005 T010: projectile must die at max range")
		return

	var wall := StaticBody2D.new()
	wall.name = "Wall"
	wall.collision_layer = 16
	wall.collision_mask = 0
	var wall_shape := CollisionShape2D.new()
	var wall_rect := RectangleShape2D.new()
	wall_rect.size = Vector2(24, 48)
	wall_shape.shape = wall_rect
	wall.add_child(wall_shape)
	add_child(wall)
	wall.global_position = Vector2(80, 240)
	await get_tree().physics_frame
	var wall_bolt: Node = spawner.spawn_staple({
		"kind": "staple",
		"shooter_id": 1,
		"position": wall.global_position,
		"direction": Vector2.RIGHT,
		"damage": 1,
		"speed": 0.0,
		"max_range": 400.0,
	})
	for _j in 12:
		await get_tree().physics_frame
		await get_tree().process_frame
		if not is_instance_valid(wall_bolt):
			break
	if is_instance_valid(wall_bolt):
		_fail("US-005 T010: projectile must die on walls and not pass through")
		return

	_clear_staples()
	await get_tree().process_frame
	var dummy := _make_hit_dummy("DummyTarget", Vector2(80, 320))
	add_child(dummy)
	dummy.get_node("Hitbox").Damaged.connect(_on_dummy_damaged)
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
	for _k in 8:
		await get_tree().physics_frame
		await get_tree().process_frame
		if _dummy_damage >= 1:
			break
	for _free in 4:
		await get_tree().process_frame
		if not is_instance_valid(bolt):
			break
	for _free in 4:
		await get_tree().process_frame
		if not is_instance_valid(bolt):
			break
	if _dummy_damage != 1:
		_fail("US-005 T004: host hit must apply 1 damage once, got %d" % _dummy_damage)
		return
	if is_instance_valid(bolt):
		_fail("US-005 T004: staple must be consumed on first valid hit")
		return

	var zone := Node2D.new()
	zone.name = "RealityZone"
	zone.add_to_group("RealityZone")
	add_child(zone)
	var zone_dummy := _make_hit_dummy("ZoneDummy", Vector2(80, 80))
	zone.add_child(zone_dummy)
	var zone_damage: Array = [0]
	zone_dummy.get_node("Hitbox").Damaged.connect(func(hurt_box: Hurtbox) -> void:
		zone_damage[0] += hurt_box.damage
	)
	await get_tree().physics_frame
	var zone_bolt: Node = spawner.spawn_staple({
		"kind": "staple",
		"shooter_id": 1,
		"position": zone_dummy.global_position,
		"direction": Vector2.RIGHT,
		"damage": 1,
		"speed": 0.0,
		"max_range": 64.0,
	})
	for _z in 8:
		await get_tree().physics_frame
		await get_tree().process_frame
		if zone_damage[0] >= 1:
			break
	if zone_damage[0] != 1:
		_fail("US-005 T004: zone occupancy must not cancel staple damage, got %d" % zone_damage[0])
		return
	if is_instance_valid(zone_bolt):
		zone_bolt.queue_free()

	var building: Node = load("res://buildings/buildables/paper_factory.tscn").instantiate()
	building.name = "StapleBuilding"
	add_child(building)
	building.global_position = Vector2(80, 160)
	building.hitpoints = 10
	var b_hit := Hitbox.new()
	b_hit.name = "Hitbox"
	b_hit.collision_layer = 8
	b_hit.collision_mask = 0
	b_hit.monitoring = false
	var b_shape := CollisionShape2D.new()
	var b_circle := CircleShape2D.new()
	b_circle.radius = 20.0
	b_shape.shape = b_circle
	b_hit.add_child(b_shape)
	building.add_child(b_hit)
	b_hit.Damaged.connect(_on_building_damaged)
	await get_tree().physics_frame
	_building_damage = 0
	var hp_before: int = building.hitpoints
	var b_bolt: Node = spawner.spawn_staple({
		"kind": "staple",
		"shooter_id": 1,
		"position": building.global_position,
		"direction": Vector2.RIGHT,
		"damage": 1,
		"speed": 0.0,
		"max_range": 64.0,
	})
	for _b in 8:
		await get_tree().physics_frame
		await get_tree().process_frame
	if _building_damage != 0 or building.hitpoints != hp_before:
		_fail("US-005 T004: buildings must take no staple damage (hp %d damage %d)" % [building.hitpoints, _building_damage])
		return
	if b_bolt and is_instance_valid(b_bolt):
		b_bolt.queue_free()

	var melee_dummy := _make_hit_dummy("MeleeDummy", Vector2(0, 8))
	add_child(melee_dummy)
	var melee_damage: Array = [0]
	melee_dummy.get_node("Hitbox").Damaged.connect(func(hurt_box: Hurtbox) -> void:
		melee_damage[0] += hurt_box.damage
	)
	await get_tree().physics_frame
	player.staple_count = 7
	player._replicate_staple_count()
	player.update_animation("attack")
	if not player.combat_sheet_path().ends_with("player_pencil_melee.png"):
		_fail("US-005 T005/T008: melee must use player_pencil_melee.png, got %s" % player.combat_sheet_path())
		return
	var slash: Sprite2D = player.get_node_or_null("MeleeInkSlash") as Sprite2D
	if slash == null or slash.texture == null or not str(slash.texture.resource_path).ends_with("melee_ink_slash.png"):
		_fail("US-005 T005: melee ink slash VFX must use sprites/melee_ink_slash.png")
		return
	if slash.is_in_group("staple_projectiles"):
		_fail("US-005 T005: ink slash must not be a projectile")
		return
	player.start_melee_attack()
	for _m in 8:
		await get_tree().physics_frame
		await get_tree().process_frame
		if melee_damage[0] >= player.melee_damage:
			break
	if melee_damage[0] != player.melee_damage:
		_fail("US-005 T005: melee must apply melee_damage once, got %d" % melee_damage[0])
		return
	if player.staple_count != 7:
		_fail("US-005 T005: melee must not spend staples, mag is %d" % player.staple_count)
		return

	player.staple_count = 0
	player._replicate_staple_count()
	melee_damage[0] = 0
	player.start_melee_attack()
	for _m2 in 8:
		await get_tree().physics_frame
		await get_tree().process_frame
		if melee_damage[0] >= player.melee_damage:
			break
	if melee_damage[0] != player.melee_damage:
		_fail("US-005 T005: melee must work at magazine 0, got %d" % melee_damage[0])
		return
	if player.staple_count != 0:
		_fail("US-005 T005: melee at 0 mag must leave mag at 0")
		return

	player.update_animation("idle")
	if not player.combat_sheet_path().ends_with("player_staple_gun.png"):
		_fail("US-005 T008: switching off melee must restore staple-gun sheet, got %s" % player.combat_sheet_path())
		return

	player.staple_count = 11
	player._replicate_staple_count()
	var same_proj: int = _staple_count()
	player.start_melee_attack()
	player.request_fire_staple(Vector2.RIGHT)
	await get_tree().process_frame
	if player.staple_count != 11:
		_fail("US-005 T006: same-frame melee must win without spending, mag is %d" % player.staple_count)
		return
	if _staple_count() != same_proj:
		_fail("US-005 T006: same-frame melee must not spawn a staple")
		return

	player.staple_count = 9
	player._replicate_staple_count()
	player.empty_click_played = false
	if not await _assert_lockout(player, "death"):
		return
	if not await _assert_lockout(player, "respawn_wait"):
		return
	if not await _assert_lockout(player, "snake"):
		return
	player.current_building_data = load("res://buildings/buildables/PaperFactory.tres") as BuildingData
	if not await _assert_lockout(player, "building"):
		return
	player.current_building_data = null

	player.staple_count = 2
	player._replicate_staple_count()
	var over_before: int = _staple_count()
	for _o in 8:
		player.request_fire_staple(Vector2.RIGHT)
	await get_tree().process_frame
	await get_tree().process_frame
	if player.staple_count != 0:
		_fail("US-005 T009: extra fire RPCs must not drive server mag below 0, got %d" % player.staple_count)
		return
	if _staple_count() != over_before + 2:
		_fail("US-005 T009: only server-legal shots may exist, got %d extra" % (_staple_count() - over_before))
		return
	if not spawner.has_method("spawn_staple"):
		_fail("US-005 T009: projectile spawn must stay on MultiplayerSpawner")
		return

	print("US-005 T004-T010 combat loadout test passed")
	print("US-005 two-window play pass not run (QA owns it)")
	get_tree().quit(0)

func _assert_lockout(player: Player, kind: String) -> bool:
	var idle_state: Node = player.state_machine.get_node_or_null("idle")
	var block_state: Node = player.state_machine.get_node_or_null(kind)
	if kind != "building":
		if block_state == null:
			_fail("US-005 T007: missing state %s" % kind)
			return false
		player.state_machine.current_state = block_state
	var mag: int = player.staple_count
	var proj: int = _staple_count()
	player.empty_click_played = false
	player.request_fire_staple(Vector2.RIGHT)
	player.start_melee_attack()
	await get_tree().process_frame
	if player.staple_count != mag:
		_fail("US-005 T007: %s lockout must not change mag" % kind)
		return false
	if _staple_count() != proj:
		_fail("US-005 T007: %s lockout must not fire a staple" % kind)
		return false
	if player.empty_click_played:
		_fail("US-005 T007: %s lockout must not play empty-click" % kind)
		return false
	player.staple_count = 0
	player.empty_click_played = false
	player.request_fire_staple(Vector2.RIGHT)
	await get_tree().process_frame
	if player.empty_click_played:
		_fail("US-005 T007: %s lockout must not jam-click when empty" % kind)
		return false
	if player.staple_count != 0:
		_fail("US-005 T007: %s lockout must leave empty mag unchanged" % kind)
		return false
	player.staple_count = mag
	if kind != "building" and idle_state:
		player.state_machine.current_state = idle_state
	return true

func _make_hit_dummy(dummy_name: String, pos: Vector2) -> Node2D:
	var dummy := Node2D.new()
	dummy.name = dummy_name
	dummy.position = pos
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
	return dummy

func _clear_staples() -> void:
	for node in get_tree().get_nodes_in_group("staple_projectiles"):
		if is_instance_valid(node):
			node.queue_free()

func _staple_count() -> int:
	var n: int = 0
	for node in get_tree().get_nodes_in_group("staple_projectiles"):
		if is_instance_valid(node):
			n += 1
	return n

func _on_dummy_damaged(hurt_box: Hurtbox) -> void:
	_dummy_damage += hurt_box.damage

func _on_building_damaged(hurt_box: Hurtbox) -> void:
	_building_damage += hurt_box.damage

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
