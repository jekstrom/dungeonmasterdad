extends Node

## US-028 T001–T005 independent harness.
## user_stories/tasks/US-028/T005-verification-harness.md
## Play pass (QA owns two-window): fountain reads as a room hazard; charge, splash,
## knockback, slide on dew; peer matches; expire restores traction; boss does not fire this.

const FOUNTAIN_SCENE := preload("res://doodads/water_fountain.tscn")
const DM_SCENE := preload("res://dm/dm.tscn")
const JET_SCENE := "res://monsters/carbonated_jet.tscn"
const HOME := Vector2i(8, 8)
const TICK := 1.0 / 60.0
const ENTRANCE := Vector2i(2, 2)
const EXIT_CELL := Vector2i(16, 16)


func _ready() -> void:
	if not await _run():
		return
	print("US-028 T005 independent test passed")
	print("US-028 two-window play pass not run (QA owns it): fountain charge, splash, knockback, dew slick; peer matches remaining rect; expire restores traction; boss does not fire this.")
	get_tree().quit(0)


func _run() -> bool:
	if not multiplayer.is_server():
		_fail("US-028 T005: offline peer must be server")
		return false
	if not _assert_isolation():
		return false
	if not _assert_spawn_contract():
		return false
	if not await _assert_open_room_charge_splash_slick():
		return false
	if not await _assert_replicate_snapshot():
		return false
	return true


func _assert_isolation() -> bool:
	var fountain_src := FileAccess.get_file_as_string("res://doodads/water_fountain.gd")
	var fountain_tscn := FileAccess.get_file_as_string("res://doodads/water_fountain.tscn")
	var slick_src := FileAccess.get_file_as_string("res://doodads/dew_slick.gd")
	var slick_tscn := FileAccess.get_file_as_string("res://doodads/dew_slick.tscn")
	var boss_src := FileAccess.get_file_as_string("res://monsters/baja_boss.gd")
	if fountain_src.find("carbonated_jet") != -1 or fountain_tscn.find("carbonated_jet") != -1:
		_fail("US-028 T005: fountain must not use carbonated_jet")
		return false
	if not ResourceLoader.exists(JET_SCENE):
		_fail("US-028 T005: jet scene must remain a distinct system")
		return false
	if slick_tscn.find("blizzard_overlay") != -1 or slick_src.find("blizzard") != -1:
		_fail("US-028 T005: dew slick must not be a blizzard pocket")
		return false
	if boss_src.find("FreezeWave") != -1 or boss_src.find("freeze_wave") != -1:
		_fail("US-028 T005: baja_boss must not have a Freeze Wave state")
		return false
	var spawner := FileAccess.get_file_as_string("res://scripts/multiplayer_spawner.gd")
	if spawner.find("water_fountain.tscn") != -1:
		_fail("US-028 T005: do not auto-spawn fountain on MultiplayerSpawner")
		return false
	return true


func _assert_spawn_contract() -> bool:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager == null or not manager.has_method("generate_dungeon_contract"):
		_fail("US-028 T005: DungeonGenerationManager missing")
		return false
	var payload := {
		"requestId": "us028-independent",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 16, "y": 16},
		"generationBounds": {"origin": {"x": 0, "y": 0}, "size": {"x": 24, "y": 24}},
		"roomCount": 4
	}
	var response: Dictionary = manager.generate_dungeon_contract(payload, 1)
	if not response.get("ok", false):
		_fail("US-028 T005: generation failed %s" % response)
		return false
	var data: Dictionary = response.get("data", {})
	var raw: Variant = data.get("fountain", {})
	if not (raw is Dictionary) or (raw as Dictionary).is_empty():
		_fail("US-028 T005: expected exactly one fountain")
		return false
	var cell: Vector2i = DungeonGrid.cell_from(raw)
	var entrance: Vector2i = DungeonGrid.cell_from(data.get("entrance", ENTRANCE))
	var exit_cell: Vector2i = DungeonGrid.cell_from(data.get("exit", EXIT_CELL))
	if cell == entrance or cell == exit_cell:
		_fail("US-028 T005: fountain on entrance/exit %s" % cell)
		return false
	var walkable: Dictionary = {}
	for region in data.get("roomRegions", []):
		for point in region.get("cells", []):
			walkable[DungeonGrid.cell_from(point)] = true
	for region in data.get("hallwayRegions", []):
		for point in region.get("cells", []):
			walkable[DungeonGrid.cell_from(point)] = true
	if not walkable.has(cell):
		_fail("US-028 T005: fountain cell %s is not walkable" % cell)
		return false
	var skip_response: Dictionary = manager.generate_dungeon_contract({
		"requestId": "us028-independent-skip",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 16, "y": 16},
		"generationBounds": {"origin": {"x": 0, "y": 0}, "size": {"x": 24, "y": 24}},
		"roomCount": 4,
		"skipFountain": true
	}, 1)
	if not skip_response.get("ok", false):
		_fail("US-028 T005: skipFountain generation failed")
		return false
	var skip_fountain: Dictionary = skip_response.get("data", {}).get("fountain", {})
	if not skip_fountain.is_empty():
		_fail("US-028 T005: skipFountain must yield zero fountains")
		return false
	return true


func _assert_open_room_charge_splash_slick() -> bool:
	var fountain: Node2D = FOUNTAIN_SCENE.instantiate() as Node2D
	fountain.set("period_sec", 999.0)
	fountain.set("charge_sec", 999.0)
	fountain.set("slick_duration_sec", 0.4)
	fountain.position = DungeonGrid.to_world_center(HOME)
	add_child(fountain)
	var room: Array[Vector2i] = []
	for y in range(-1, 2):
		for x in range(-1, 2):
			room.append(HOME + Vector2i(x, y))
	fountain.call("configure_room", HOME, room)
	await get_tree().process_frame
	if get_tree().get_nodes_in_group("wall").size() != 0:
		_fail("US-028 T005: open-room check must not spawn walls")
		return false

	var dm: CharacterBody2D = _make_stub_dm(fountain.global_position + Vector2(40, 0))
	dm.set("invulnerable", false)
	dm.set("hitpoints", 100)
	dm.set("max_hp", 100)
	DmManager.fantasy_level = 0
	await get_tree().process_frame

	if bool(fountain.call("is_charging")) or bool(fountain.call("is_showing_splash")):
		_fail("US-028 T005: idle fountain must not be charging or splashing")
		return false
	fountain.call("begin_charge")
	await get_tree().process_frame
	if not bool(fountain.call("is_charging")):
		_fail("US-028 T005: charge must show before splash")
		return false
	if bool(fountain.call("is_showing_splash")):
		_fail("US-028 T005: splash must not exist during charge")
		return false

	var start_pos: Vector2 = dm.global_position
	var hp_before: int = int(dm.get("hitpoints"))
	fountain.call("fire_splash")
	await get_tree().process_frame
	if int(dm.get("hitpoints")) >= hp_before:
		_fail("US-028 T005: splash must hit the DM")
		return false
	if dm.global_position.distance_to(start_pos) < 8.0:
		_fail("US-028 T005: splash must knock the DM back")
		return false
	if not bool(fountain.call("has_dew_slick")):
		_fail("US-028 T005: open room with no wall must still get a dew slick")
		return false

	dm.global_position = fountain.global_position + Vector2(32, 0)
	dm.velocity = Vector2(280, 0)
	dm.set("direction", Vector2.ZERO)
	var speed_before: float = dm.velocity.length()
	dm._physics_process(TICK)
	if dm.velocity.length() < 8.0 or dm.velocity.length() >= speed_before + 0.01:
		_fail("US-028 T005: on slick, no input must keep sliding")
		return false

	var slick: Node = get_tree().get_nodes_in_group("dew_slick")[0]
	slick.set("remaining_sec", 0.01)
	slick.call("_process", 0.05)
	await get_tree().process_frame
	if bool(fountain.call("has_dew_slick")):
		_fail("US-028 T005: expired slick must restore traction")
		return false
	dm.velocity = Vector2(280, 0)
	dm.set("direction", Vector2.ZERO)
	dm._physics_process(TICK)
	if dm.velocity.length() > 0.01:
		_fail("US-028 T005: off slick, no input must stop")
		return false

	dm.queue_free()
	fountain.queue_free()
	await get_tree().process_frame
	return true


func _assert_replicate_snapshot() -> bool:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	var fountain: Node2D = FOUNTAIN_SCENE.instantiate() as Node2D
	fountain.set("period_sec", 999.0)
	fountain.set("charge_sec", 999.0)
	fountain.set("slick_duration_sec", 4.0)
	fountain.position = DungeonGrid.to_world_center(HOME)
	add_child(fountain)
	var room: Array[Vector2i] = [HOME]
	fountain.call("configure_room", HOME, room)
	await get_tree().process_frame
	fountain.call("fire_splash")
	await get_tree().process_frame
	var snap: Dictionary = manager.call("pack_fountain_state")
	if float(snap.get("slick_remaining", 0.0)) <= 0.0:
		_fail("US-028 T005: snapshot must include slick remaining")
		return false
	if (snap.get("slick_cells", snap.get("cells", [])) as Array).is_empty():
		_fail("US-028 T005: snapshot must include slick cells")
		return false
	fountain.queue_free()
	for node in get_tree().get_nodes_in_group("dew_slick"):
		node.queue_free()
	await get_tree().process_frame
	manager.call("apply_fountain_state", snap)
	await get_tree().process_frame
	var restored: Node = manager.call("_first_fountain")
	if restored == null or not bool(restored.call("has_dew_slick")):
		_fail("US-028 T005: apply snapshot must restore fountain + slick")
		return false
	return true


func _make_stub_dm(world_pos: Vector2) -> CharacterBody2D:
	var dm: CharacterBody2D = DM_SCENE.instantiate() as CharacterBody2D
	dm.name = "StubDM"
	dm.global_position = world_pos
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
	dm.set("_dead", false)
	return dm


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
