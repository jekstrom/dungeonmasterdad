extends Node

const FOUNTAIN_SCENE := preload("res://doodads/water_fountain.tscn")
const DM_SCENE := preload("res://dm/dm.tscn")
const HOME := Vector2i(8, 8)
const TICK := 1.0 / 60.0


func _ready() -> void:
	if not await _run():
		return
	print("US-028 T003 dew slick test passed")
	get_tree().quit(0)


func _run() -> bool:
	if not multiplayer.is_server():
		_fail("US-028 T003: offline peer must be server")
		return false
	if FileAccess.get_file_as_string("res://doodads/dew_slick.tscn").find("blizzard_overlay") != -1:
		_fail("US-028 T003: dew slick must not use blizzard_overlay.png")
		return false
	if FileAccess.get_file_as_string("res://doodads/dew_slick.gd").find("blizzard") != -1:
		_fail("US-028 T003: slick is friction, not blizzard slow")
		return false
	var slick_src := FileAccess.get_file_as_string("res://doodads/dew_slick.gd")
	if slick_src.find("TEAL") == -1:
		_fail("US-028 T003: low-friction area must be colored teal")
		return false
	var fountain: Node2D = FOUNTAIN_SCENE.instantiate() as Node2D
	fountain.set("period_sec", 999.0)
	fountain.set("charge_sec", 999.0)
	fountain.set("slick_duration_sec", 0.35)
	fountain.position = DungeonGrid.to_world_center(HOME)
	add_child(fountain)
	var room: Array[Vector2i] = []
	for y in range(-1, 2):
		for x in range(-1, 2):
			room.append(HOME + Vector2i(x, y))
	fountain.call("configure_room", HOME, room)
	await get_tree().process_frame

	var dm: CharacterBody2D = DM_SCENE.instantiate() as CharacterBody2D
	dm.name = "StubDM"
	dm.global_position = fountain.global_position + Vector2(32, 0)
	add_child(dm)
	dm.collision_layer = 0
	dm.collision_mask = 0
	var dm_sm: Node = dm.get_node_or_null("DmStateMachine")
	if dm_sm:
		dm_sm.process_mode = Node.PROCESS_MODE_DISABLED
	var cam: Node = dm.get_node_or_null("Camera2D")
	if cam is Camera2D:
		(cam as Camera2D).enabled = false
	dm.add_to_group("dm")
	DmManager.dm = dm
	dm.set("invulnerable", true)
	dm.set("_dead", false)
	await get_tree().process_frame

	if bool(fountain.call("has_dew_slick")):
		_fail("US-028 T003: slick must not exist before the splash")
		return false
	fountain.call("fire_splash")
	await get_tree().process_frame
	dm.global_position = fountain.global_position + Vector2(32, 0)
	if not bool(fountain.call("has_dew_slick")):
		_fail("US-028 T003: splash must spawn a dew slick")
		return false
	var remaining: float = float(fountain.call("slick_remaining"))
	if remaining < 0.2 or remaining > 0.4:
		_fail("US-028 T003: slick duration should match config, got %s" % remaining)
		return false
	var slicks: Array = get_tree().get_nodes_in_group("dew_slick")
	if slicks.is_empty():
		_fail("US-028 T003: dew_slick group empty")
		return false
	var slick: Node = slicks[0]
	if not bool(slick.call("covers_world", dm.global_position)):
		_fail("US-028 T003: DM standing in the room must be on the slick")
		return false

	dm.velocity = Vector2(300, 0)
	dm.set("direction", Vector2.ZERO)
	var speed_before: float = dm.velocity.length()
	dm._physics_process(TICK)
	if dm.velocity.length() < 8.0 or dm.velocity.length() >= speed_before + 0.01:
		_fail("US-028 T003: on slick with no input, velocity must keep sliding, got %s" % dm.velocity)
		return false

	var first_remaining: float = float(fountain.call("slick_remaining"))
	fountain.call("fire_splash")
	await get_tree().process_frame
	var refreshed: float = float(fountain.call("slick_remaining"))
	if refreshed < first_remaining:
		_fail("US-028 T003: a later splash must refresh duration, not shrink it")
		return false
	if get_tree().get_nodes_in_group("dew_slick").size() != 1:
		_fail("US-028 T003: refresh must not stack extra slicks")
		return false

	slick.set("remaining_sec", 0.01)
	if slick.has_method("_process"):
		slick.call("_process", 0.05)
	await get_tree().process_frame
	if bool(fountain.call("has_dew_slick")):
		_fail("US-028 T003: expired slick must restore traction")
		return false
	dm.velocity = Vector2(300, 0)
	dm.set("direction", Vector2.ZERO)
	dm._physics_process(TICK)
	if dm.velocity.length() > 0.01:
		_fail("US-028 T003: off slick, no input must snap to baseline stop, got %s" % dm.velocity)
		return false

	dm.queue_free()
	fountain.queue_free()
	await get_tree().process_frame
	print("US-028 T003: slick spawned, slid, refreshed, expired")
	return true


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
