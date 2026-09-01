extends Node

## US-010 / US-005: place Office Max (and IRS) then spawn_staple must not abort.

const METAL := "res://pickups/metal.tres"
const OFFICE_MAX_ID := "res://buildings/buildables/OfficeMax.tres"
const IRS_ID := "res://buildings/buildables/Irs.tres"

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.max_inv_slots = 8
	var peer_id: int = multiplayer.get_unique_id()
	PlayerManager.register_player(peer_id, "Paper Pusher")

	var level := Node2D.new()
	level.set_script(load("res://_globals/level_manager.gd"))
	level.add_to_group("level_manager")
	add_child(level)
	await get_tree().process_frame
	var interior := Rect2i(0, 0, 16, 10)
	var dungeon := Rect2i(8, 2, 8, 6)
	level.tree_scatter_density = 0.0
	level.apply_map_interior(interior, dungeon)
	await get_tree().process_frame
	await get_tree().physics_frame

	var reality = load("res://zones/reality_zone.tscn").instantiate()
	add_child(reality)
	await get_tree().process_frame

	var root := Node2D.new()
	root.name = "Buildings"
	root.add_to_group("building_root")
	add_child(root)
	var building_spawner := MultiplayerSpawner.new()
	building_spawner.set_script(load("res://scripts/building_spawner.gd"))
	building_spawner.name = "BuildingSpawner"
	building_spawner.spawn_path = NodePath("..")
	root.add_child(building_spawner)
	await get_tree().process_frame

	var projectiles := Node2D.new()
	projectiles.name = "Projectiles"
	add_child(projectiles)
	var proj_spawner := MultiplayerSpawner.new()
	proj_spawner.set_script(load("res://scripts/projectile_spawner.gd"))
	proj_spawner.name = "ProjectileSpawner"
	proj_spawner.spawn_path = NodePath("..")
	proj_spawner.projectile_scene = load("res://spells/fireball/fireball_spell.tscn")
	projectiles.add_child(proj_spawner)
	await get_tree().process_frame

	var metal: ItemData = load(METAL) as ItemData

	# --- Place IRS then staple (control) ---
	PlayerManager.add_item_to_inventory(peer_id, metal, 10)
	var irs_data: BuildingData = BuildingDatabase.get_building(IRS_ID)
	if irs_data == null:
		_fail("IRS BuildingData missing")
		return
	var irs_pos := _first_clear(Vector2(irs_data.size))
	if irs_pos == Vector2.INF:
		_fail("no clear cell for IRS")
		return
	BuildingManager.request_placement(IRS_ID, irs_pos, irs_pos)
	await get_tree().process_frame
	await get_tree().physics_frame
	var before_irs := _staple_count()
	var spawned_irs: Node = proj_spawner.spawn_staple({
		"kind": "staple",
		"shooter_id": peer_id,
		"position": irs_pos + Vector2(200, 0),
		"direction": Vector2.RIGHT,
		"damage": 1,
		"speed": 520.0,
		"max_range": 360.0,
	})
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	if spawned_irs == null or not is_instance_valid(spawned_irs):
		_fail("IRS control: spawn_staple returned invalid")
		return
	if _staple_count() < before_irs + 1:
		_fail("IRS control: staple not under Projectiles")
		return
	print("US-010 place-IRS-then-staple passed")

	# Clear IRS so unique/footprint does not block Office Max
	for child in root.get_children():
		if child is MultiplayerSpawner:
			continue
		child.free()
	await get_tree().process_frame

	# --- Place Office Max then staple (crash repro) ---
	PlayerManager.add_item_to_inventory(peer_id, metal, 10)
	var om_data: BuildingData = BuildingDatabase.get_building(OFFICE_MAX_ID)
	if om_data == null:
		_fail("OfficeMax BuildingData missing")
		return
	var om_pos := _first_clear(Vector2(om_data.size))
	if om_pos == Vector2.INF:
		_fail("no clear cell for Office Max")
		return
	BuildingManager.request_placement(OFFICE_MAX_ID, om_pos, om_pos)
	await get_tree().process_frame
	await get_tree().physics_frame
	var om: Node = null
	for child in root.get_children():
		if child.is_in_group("office_max"):
			om = child
			break
	if om == null:
		_fail("Office Max not placed")
		return
	if bool(om.get("is_ghost")):
		_fail("Office Max still ghost after place")
		return
	# Collision / hitbox / health bar must exist without null deref next frames
	if om.get_node_or_null("CollisionShape2D") == null:
		_fail("Office Max missing CollisionShape2D")
		return
	if om.get_node_or_null("Hitbox") == null:
		_fail("Office Max missing Hitbox after place")
		return
	if om.get_node_or_null("HealthBar") == null:
		_fail("Office Max missing HealthBar after place")
		return
	# HealthBar must be child of building, not building_root (MultiplayerSpawner abort risk)
	var hb: Node = om.get_node("HealthBar")
	if hb.get_parent() != om:
		_fail("HealthBar parent must be Office Max, got %s" % hb.get_parent())
		return
	if hb.get_parent() == root:
		_fail("HealthBar must not be direct child of Buildings root")
		return

	var before_om := _staple_count()
	var spawned_om: Node = proj_spawner.spawn_staple({
		"kind": "staple",
		"shooter_id": peer_id,
		"position": om_pos + Vector2(220, 0),
		"direction": Vector2.RIGHT,
		"damage": 1,
		"speed": 520.0,
		"max_range": 360.0,
	})
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	if spawned_om == null or not is_instance_valid(spawned_om):
		_fail("Office Max: spawn_staple returned invalid after place")
		return
	if _staple_count() < before_om + 1:
		_fail("Office Max: staple not under Projectiles after place")
		return

	# Also exercise player fire path with Office Max present
	var player: Player = load("res://player/player.tscn").instantiate() as Player
	player.name = str(peer_id)
	player.position = om_pos + Vector2(0, 180)
	add_child(player)
	await get_tree().process_frame
	player.staple_count = 5
	player.current_building_data = null
	player.ghost_building = null
	var lmb := InputEventMouseButton.new()
	lmb.button_index = MOUSE_BUTTON_LEFT
	lmb.pressed = true
	if not player.wants_fire_staple(lmb):
		_fail("open-world LMB must still wants_fire_staple when not placing")
		return
	# While placing, primary_click must NOT fire
	var fake_data: BuildingData = om_data
	player.current_building_data = fake_data
	if player.wants_fire_staple(lmb):
		_fail("primary_click must not wants_fire_staple while current_building_data set")
		return
	player.current_building_data = null
	var before_player := _staple_count()
	player.request_fire_staple(Vector2.RIGHT)
	await get_tree().process_frame
	await get_tree().physics_frame
	if player.staple_count != 4:
		_fail("player fire with Office Max present must consume 1, got %d" % player.staple_count)
		return
	if _staple_count() < before_player + 1:
		_fail("player fire with Office Max present must spawn staple")
		return

	print("US-010 place-OfficeMax-then-staple passed")
	get_tree().quit(0)

func _staple_count() -> int:
	var n := 0
	for node in get_tree().get_nodes_in_group("staple_projectiles"):
		if is_instance_valid(node):
			n += 1
	return n

func _first_clear(size: Vector2) -> Vector2:
	var zone: Node = get_tree().get_first_node_in_group("RealityZone")
	if zone == null or not ("home_rect" in zone):
		return Vector2.INF
	var home: Rect2i = zone.home_rect
	for y in range(home.position.y, home.end.y):
		for x in range(home.position.x, home.end.x):
			var pos: Vector2 = DungeonGrid.to_world_center(Vector2i(x, y))
			if BuildingManager.is_area_clear(pos, size):
				return pos
	return Vector2.INF

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
