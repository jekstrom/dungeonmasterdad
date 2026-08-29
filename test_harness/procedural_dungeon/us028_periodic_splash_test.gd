extends Node

const FOUNTAIN_SCENE := preload("res://doodads/water_fountain.tscn")
const DM_SCENE := preload("res://dm/dm.tscn")
const JET_SCENE := "res://monsters/carbonated_jet.tscn"
const HOME := Vector2i(8, 8)


func _ready() -> void:
	if not await _run():
		return
	print("US-028 T002 periodic splash test passed")
	get_tree().quit(0)


func _run() -> bool:
	if not multiplayer.is_server():
		_fail("US-028 T002: offline peer must be server")
		return false
	if not _assert_scenes_distinct():
		return false
	if not await _assert_charge_then_splash_knockback():
		return false
	if not _assert_no_boss_wave():
		return false
	return true


func _assert_scenes_distinct() -> bool:
	var fountain_src := FileAccess.get_file_as_string("res://doodads/water_fountain.gd")
	var tscn := FileAccess.get_file_as_string("res://doodads/water_fountain.tscn")
	if fountain_src.find("carbonated_jet") != -1 or tscn.find("carbonated_jet") != -1:
		_fail("US-028 T002: fountain splash must not use carbonated_jet")
		return false
	if fountain_src.find("FreezeWave") != -1 or fountain_src.find("freeze_wave") != -1:
		_fail("US-028 T002: fountain must not be a Freeze Wave boss state")
		return false
	if not ResourceLoader.exists(JET_SCENE):
		_fail("US-028 T002: jet scene should still exist as a distinct system")
		return false
	return true


func _assert_charge_then_splash_knockback() -> bool:
	var fountain: Node2D = FOUNTAIN_SCENE.instantiate() as Node2D
	if fountain == null:
		_fail("US-028 T002: failed to instantiate water_fountain.tscn")
		return false
	fountain.period_sec = 999.0
	fountain.charge_sec = 999.0
	fountain.position = DungeonGrid.to_world_center(HOME)
	add_child(fountain)
	var room: Array[Vector2i] = []
	for y in range(-1, 2):
		for x in range(-1, 2):
			room.append(HOME + Vector2i(x, y))
	fountain.configure_room(HOME, room)
	await get_tree().process_frame

	var dm: Node2D = DM_SCENE.instantiate() as Node2D
	dm.name = "StubDM"
	dm.global_position = fountain.global_position + Vector2(48, 0)
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
	dm.set("invulnerable", false)
	dm.set("_dead", false)
	dm.set("hitpoints", 100)
	dm.set("max_hp", 100)
	DmManager.fantasy_level = 0
	await get_tree().process_frame

	if bool(fountain.is_charging()) or bool(fountain.is_showing_splash()):
		_fail("US-028 T002: fountain must be idle before the period elapses")
		return false
	var glow: CanvasItem = fountain.get_node_or_null("ChargeGlow") as CanvasItem
	var wash: CanvasItem = fountain.get_node_or_null("SplashWash") as CanvasItem
	if glow and glow.visible:
		_fail("US-028 T002: charge glow must be hidden while idle")
		return false
	if wash and wash.visible:
		_fail("US-028 T002: splash must not exist before the charge")
		return false

	fountain.begin_charge()
	await get_tree().process_frame
	if not bool(fountain.is_charging()):
		_fail("US-028 T002: charge must be visible before any splash exists")
		return false
	if bool(fountain.is_showing_splash()):
		_fail("US-028 T002: splash must not exist during the charge")
		return false
	if glow and not glow.visible:
		_fail("US-028 T002: ChargeGlow must show during the charge")
		return false
	if wash and wash.visible:
		_fail("US-028 T002: SplashWash must stay hidden during the charge")
		return false

	var start_pos: Vector2 = dm.global_position
	var hp_before: int = int(dm.get("hitpoints"))
	fountain.fire_splash()
	await get_tree().process_frame
	if bool(fountain.is_charging()):
		_fail("US-028 T002: charge must end when the splash fires")
		return false
	if not bool(fountain.is_showing_splash()):
		_fail("US-028 T002: splash VFX must show when the splash fires")
		return false
	if wash and not wash.visible:
		_fail("US-028 T002: SplashWash must be visible on splash")
		return false
	if int(dm.get("hitpoints")) >= hp_before:
		_fail("US-028 T002: splash must hit the DM, hp %s -> %s" % [hp_before, dm.get("hitpoints")])
		return false
	if dm.global_position.distance_to(start_pos) < 8.0:
		_fail("US-028 T002: splash must knock the DM back, still at %s" % dm.global_position)
		return false
	var away: Vector2 = dm.global_position - fountain.global_position
	if away.dot(Vector2.RIGHT) <= 0.0:
		_fail("US-028 T002: knockback must push away from the fountain")
		return false

	dm.queue_free()
	fountain.queue_free()
	await get_tree().process_frame
	return true


func _assert_no_boss_wave() -> bool:
	var boss_src := FileAccess.get_file_as_string("res://monsters/baja_boss.gd")
	if boss_src.find("FreezeWave") != -1 or boss_src.find("freeze_wave") != -1:
		_fail("US-028 T002: do not add a Freeze Wave state to baja_boss")
		return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
