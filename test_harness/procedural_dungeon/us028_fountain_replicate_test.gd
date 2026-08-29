extends Node

const FOUNTAIN_SCENE := preload("res://doodads/water_fountain.tscn")
const DM_SCENE := preload("res://dm/dm.tscn")
const HOME := Vector2i(8, 8)


func _ready() -> void:
	if not await _run():
		return
	print("US-028 T004 fountain replicate test passed")
	get_tree().quit(0)


func _run() -> bool:
	if not multiplayer.is_server():
		_fail("US-028 T004: offline peer must be server")
		return false
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager == null or not manager.has_method("pack_fountain_state"):
		_fail("US-028 T004: DungeonGenerationManager must pack fountain state")
		return false
	if not await _assert_slick_snapshot(manager):
		return false
	if not _assert_no_jet_or_wave():
		return false
	return true


func _assert_slick_snapshot(manager: Node) -> bool:
	var fountain: Node2D = FOUNTAIN_SCENE.instantiate() as Node2D
	fountain.set("period_sec", 999.0)
	fountain.set("charge_sec", 999.0)
	fountain.set("slick_duration_sec", 5.0)
	fountain.position = DungeonGrid.to_world_center(HOME)
	add_child(fountain)
	var room: Array[Vector2i] = []
	for y in range(-1, 2):
		for x in range(-1, 2):
			room.append(HOME + Vector2i(x, y))
	fountain.call("configure_room", HOME, room)
	await get_tree().process_frame

	var dm: Node2D = DM_SCENE.instantiate() as Node2D
	dm.global_position = fountain.global_position + Vector2(40, 0)
	add_child(dm)
	dm.collision_layer = 0
	dm.collision_mask = 0
	dm.set_physics_process(false)
	dm.set_process(false)
	var dm_sm: Node = dm.get_node_or_null("DmStateMachine")
	if dm_sm:
		dm_sm.process_mode = Node.PROCESS_MODE_DISABLED
	var cam: Node = dm.get_node_or_null("Camera2D")
	if cam is Camera2D:
		(cam as Camera2D).enabled = false
	dm.add_to_group("dm")
	DmManager.dm = dm
	dm.set("invulnerable", true)
	await get_tree().process_frame

	fountain.call("begin_charge")
	var charge_pack: Dictionary = manager.call("pack_fountain_state")
	if not bool(charge_pack.get("charging", false)):
		_fail("US-028 T004: snapshot must include charging")
		return false
	fountain.call("fire_splash")
	await get_tree().process_frame
	var host_pos: Vector2 = dm.global_position
	var snap: Dictionary = manager.call("pack_fountain_state")
	if float(snap.get("slick_remaining", 0.0)) <= 0.0:
		_fail("US-028 T004: snapshot must include live slick remaining")
		return false
	var slick_cells: Array = snap.get("slick_cells", snap.get("cells", []))
	if slick_cells.is_empty():
		_fail("US-028 T004: snapshot must include slick rect cells")
		return false
	if snap.has("knockback") or snap.has("particle_rng"):
		_fail("US-028 T004: do not replicate knockback vectors or particle RNG")
		return false

	dm.queue_free()
	fountain.queue_free()
	await get_tree().process_frame
	for node in get_tree().get_nodes_in_group("dew_slick"):
		node.queue_free()
	await get_tree().process_frame

	manager.call("apply_fountain_state", snap)
	await get_tree().process_frame
	var restored: Node = manager.call("_first_fountain")
	if restored == null:
		_fail("US-028 T004: late join must restore the fountain")
		return false
	if not bool(restored.call("has_dew_slick")):
		_fail("US-028 T004: late join must restore the live slick")
		return false
	var probe: Vector2 = DungeonGrid.to_world_center(HOME)
	var covered := false
	for node in get_tree().get_nodes_in_group("dew_slick"):
		if node.has_method("covers_world") and bool(node.call("covers_world", probe)):
			covered = true
			break
	if not covered:
		_fail("US-028 T004: restored slick must cover the host rect")
		return false
	var remaining: float = float(restored.call("slick_remaining"))
	if absf(remaining - float(snap.get("slick_remaining", 0.0))) > 0.25:
		_fail("US-028 T004: remaining time must match host, got %s vs %s" % [remaining, snap.get("slick_remaining")])
		return false

	var peer_dm: Node2D = DM_SCENE.instantiate() as Node2D
	peer_dm.global_position = host_pos
	add_child(peer_dm)
	await get_tree().process_frame
	manager.call("apply_fountain_state", snap)
	if peer_dm.global_position.distance_to(host_pos) > 1.0:
		_fail("US-028 T004: applying fountain state must not invent knockback")
		return false
	peer_dm.queue_free()
	return true


func _assert_no_jet_or_wave() -> bool:
	var src := FileAccess.get_file_as_string("res://_globals/dungeon_generation_manager.gd")
	if src.find("carbonated_jet") != -1:
		_fail("US-028 T004: do not replicate Jet here")
		return false
	if src.find("FreezeWave") != -1 or src.find("freeze_wave") != -1:
		_fail("US-028 T004: do not add a Freeze Wave boss clip")
		return false
	var spawner := FileAccess.get_file_as_string("res://scripts/multiplayer_spawner.gd")
	if spawner.find("water_fountain.tscn") != -1:
		_fail("US-028 T004: do not auto-spawn the fountain on MultiplayerSpawner")
		return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
