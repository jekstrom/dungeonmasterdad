extends Node

## US-017 T009: independent blizzard verification harness.
## user_stories/tasks/US-017/T009-verification-harness.md
## Headless independent test: spawn, death unlock, locked/short mana, 3x3 8s pocket,
## PP walk T011 (no push-out) at 50% in-rect / baseline outside, building reject,
## skeleton allowed, factory 2x origin-in with 90% not reset, expire same-tick,
## late-join snapshot unlock+pocket. Optional aggro closer. No US-019/020/018.

const Catalog = preload("res://dm/dm_ability_catalog.gd")
const BajaBossScript = preload("res://monsters/baja_boss.gd")
const BOSS_PACKED := preload("res://monsters/baja_boss.tscn")
const DM_PACKED := preload("res://dm/dm.tscn")
const SmokeFactoryScene := preload("res://buildings/buildables/smoke_factory.tscn")
const SkeletonScene := preload("res://monsters/skeleton/skeleton.tscn")
const PlayerScene := preload("res://player/player.tscn")
const BOSS_SCENE := "res://monsters/baja_boss.tscn"
const BAJA_CAN := "res://pickups/bajablast/bajablast.tres"
const ENTRANCE := Vector2i(2, 2)
const EXIT_CELL := Vector2i(16, 16)
const BUILDING_SIZE := Vector2(128, 128)
const POCKET_SIZE := Vector2i(3, 3)

var _level: Node
var _reality: RealityZone
var _fantasy: FantasyZone
var _interior := Rect2i(0, 0, 16, 10)
var _dungeon := Rect2i(8, 2, 8, 6)
var _drops: Array = []


func _ready() -> void:
	DmManager.clear_blizzard_effects()
	DmUnlocks.reset_unlocks()
	DmManager.fantasy_level = 0
	PlayerManager.reality_level = 0
	PlayerManager.smoke_amt = 0
	if not SignalBus.on_item_drop.is_connected(_on_item_drop):
		SignalBus.on_item_drop.connect(_on_item_drop)
	if not _assert_one_boss_at_exit_vs_skip():
		return
	if not await _assert_death_unlocks_blizzard_and_can():
		return
	if not await _assert_optional_aggro_closer():
		return
	if not await _setup_map():
		return
	if not _assert_locked_or_short_mana_no_pocket():
		return
	if not await _assert_cast_pocket_pp_building_skeleton_factory_expire_late_join():
		return
	print("US-017 T009 independent test passed")
	get_tree().quit(0)


func _assert_one_boss_at_exit_vs_skip() -> bool:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager == null or not manager.has_method("generate_dungeon_contract"):
		return _fail("US-017 T009: DungeonGenerationManager missing")
	var response: Dictionary = manager.generate_dungeon_contract({
		"requestId": "us017-t009-boss",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 16, "y": 16},
		"generationBounds": {"origin": {"x": 0, "y": 0}, "size": {"x": 24, "y": 24}},
		"roomCount": 4
	}, 1)
	if not response.get("ok", false):
		return _fail("US-017 T009: generation failed %s" % response)
	var data: Dictionary = response.get("data", {})
	var bosses: Array = _baja_bosses(data.get("monsterSpawns", []))
	if bosses.size() != 1:
		return _fail("US-017 T009: expected exactly one baja_boss, got %d" % bosses.size())
	var spawn: Dictionary = bosses[0]
	if str(spawn.get("monsterScenePath", "")) != BOSS_SCENE:
		return _fail("US-017 T009: boss scene %s" % spawn.get("monsterScenePath", ""))
	var cell: Vector2i = DungeonGrid.cell_from(spawn.get("position", {}))
	var entrance: Vector2i = DungeonGrid.cell_from(data.get("entrance", ENTRANCE))
	var exit_cell: Vector2i = DungeonGrid.cell_from(data.get("exit", EXIT_CELL))
	if cell == entrance:
		return _fail("US-017 T009: boss must not spawn on entrance %s" % cell)
	var start_cells: Dictionary = _role_cells(data, "start")
	if start_cells.has(cell):
		return _fail("US-017 T009: boss must not spawn in the start room %s" % cell)
	var exit_cells: Dictionary = _role_cells(data, "exit")
	var near_exit: bool = DungeonGrid.chebyshev(cell, exit_cell) <= 4
	if not exit_cells.has(cell) and not near_exit:
		return _fail("US-017 T009: boss %s is not at the dungeon exit %s" % [cell, exit_cell])

	var skip_response: Dictionary = manager.generate_dungeon_contract({
		"requestId": "us017-t009-skip",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 16, "y": 16},
		"generationBounds": {"origin": {"x": 0, "y": 0}, "size": {"x": 24, "y": 24}},
		"roomCount": 4,
		"skipBoss": true
	}, 1)
	if not skip_response.get("ok", false):
		return _fail("US-017 T009: skipBoss generation failed %s" % skip_response)
	if _baja_bosses(skip_response.get("data", {}).get("monsterSpawns", [])).size() != 0:
		return _fail("US-017 T009: skipBoss must yield zero baja_boss")
	return true


func _assert_death_unlocks_blizzard_and_can() -> bool:
	DmUnlocks.reset_unlocks()
	if bool(DmUnlocks.dm_unlocks.get(Catalog.BEMIDJI_BLIZZARD, true)):
		return _fail("US-017 T009: bemidji_blizzard must start locked")
	var boss: Node = BOSS_PACKED.instantiate()
	if boss == null:
		return _fail("US-017 T009: failed to instantiate baja_boss.tscn")
	add_child(boss)
	await get_tree().process_frame
	if not (boss is BajaBossScript):
		return _fail("US-017 T009: instantiated node is not BajaBoss")
	if not multiplayer.is_server():
		return _fail("US-017 T009: die() must run as server")
	_drops.clear()
	var drop_pos: Vector2 = (boss as Node2D).global_position
	boss.call("die")
	await get_tree().process_frame
	if not bool(DmUnlocks.dm_unlocks.get(Catalog.BEMIDJI_BLIZZARD, false)):
		return _fail("US-017 T009: boss death must unlock bemidji_blizzard")
	if not _has_baja_drop(drop_pos):
		return _fail("US-017 T009: boss death must grant bajablast can, drops=%s" % _drops)
	boss.queue_free()
	await get_tree().process_frame
	return true


func _assert_optional_aggro_closer() -> bool:
	if not multiplayer.is_server():
		return _fail("US-017 T009: offline peer must be server for aggro closer")
	var boss: Node2D = BOSS_PACKED.instantiate() as Node2D
	if boss == null:
		return _fail("US-017 T009: failed to instantiate baja_boss for aggro")
	boss.set("grant_blizzard_on_death", false)
	boss.global_position = DungeonGrid.to_world_center(Vector2i(8, 8))
	add_child(boss)
	boss.collision_layer = 0
	boss.collision_mask = 0
	var dm: Node2D = DM_PACKED.instantiate() as Node2D
	if dm == null:
		return _fail("US-017 T009: failed to instantiate dm.tscn for aggro")
	dm.name = "T009StubDM"
	dm.global_position = DungeonGrid.to_world_center(Vector2i(14, 8))
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
	DmManager.dm = dm
	await get_tree().process_frame
	await get_tree().physics_frame
	if not bool(boss.call("has_aggro_target")):
		return _fail("US-017 T009: optional aggro closer: boss must aggro the DM")
	if bool(DmUnlocks.dm_unlocks.get(Catalog.BEMIDJI_BLIZZARD, false)) and not bool(boss.get("grant_blizzard_on_death")):
		pass
	DmManager.dm = null
	boss.queue_free()
	dm.queue_free()
	await get_tree().process_frame
	return true


func _setup_map() -> bool:
	_level = Node2D.new()
	_level.set_script(load("res://_globals/level_manager.gd"))
	_level.add_to_group("level_manager")
	add_child(_level)
	await get_tree().process_frame
	_level.apply_map_interior(_interior, _dungeon)
	await get_tree().process_frame
	_level.rebuild_outside_fill()
	await get_tree().process_frame
	_reality = load("res://zones/reality_zone.tscn").instantiate()
	_reality.add_to_group("RealityZone")
	add_child(_reality)
	_fantasy = load("res://zones/fantasy_zone.tscn").instantiate()
	add_child(_fantasy)
	await get_tree().process_frame
	await get_tree().physics_frame
	if _fantasy == null or _reality == null:
		return _fail("US-017 T009: failed to instantiate zones")
	return true


func _assert_locked_or_short_mana_no_pocket() -> bool:
	DmUnlocks.reset_unlocks()
	DmManager.clear_blizzard_effects()
	DmManager.set_mana(100)
	if bool(DmUnlocks.dm_unlocks.get(Catalog.BEMIDJI_BLIZZARD, true)):
		return _fail("US-017 T009: bemidji_blizzard must start locked")
	var pockets_before: int = _fantasy.claim.live_pocket_count()
	if DmManager.launch_blizzard(_spell_at(_pocket_origin())):
		return _fail("US-017 T009: locked launch_blizzard must return false")
	if DmManager.current_mana != 100:
		return _fail("US-017 T009: locked cast must not spend mana, got %d" % DmManager.current_mana)
	if _fantasy.claim.live_pocket_count() != pockets_before:
		return _fail("US-017 T009: locked cast must not plant a Fantasy pocket")
	if DmManager.live_blizzard_count() != 0:
		return _fail("US-017 T009: locked cast must not register a slow rect")

	DmUnlocks.dm_unlocks[Catalog.BEMIDJI_BLIZZARD] = true
	DmManager.set_mana(20)
	pockets_before = _fantasy.claim.live_pocket_count()
	if DmManager.launch_blizzard(_spell_at(_pocket_origin())):
		return _fail("US-017 T009: short mana launch_blizzard must return false")
	if DmManager.current_mana != 20:
		return _fail("US-017 T009: short mana must not spend, got %d" % DmManager.current_mana)
	if _fantasy.claim.live_pocket_count() != pockets_before:
		return _fail("US-017 T009: short mana must not plant a pocket")
	if DmManager.live_blizzard_count() != 0:
		return _fail("US-017 T009: short mana must not register a slow rect")
	return true


func _assert_cast_pocket_pp_building_skeleton_factory_expire_late_join() -> bool:
	DmUnlocks.dm_unlocks[Catalog.BEMIDJI_BLIZZARD] = true
	DmManager.set_mana(100)
	var origin: Vector2i = _pocket_origin()
	var inside_cell: Vector2i = origin + Vector2i(1, 1)
	var inside_world: Vector2 = DungeonGrid.to_world_center(inside_cell)
	var outside_cell: Vector2i = _outside_pocket_cell(origin)
	var outside_world: Vector2 = DungeonGrid.to_world_center(outside_cell)
	var pockets_before: int = _fantasy.claim.live_pocket_count()

	var inside_factory: Node = _make_factory("T009InsideSmoke", inside_world)
	var outside_factory: Node = _make_factory("T009OutsideSmoke", outside_world)
	if inside_factory == null or outside_factory == null:
		return _fail("US-017 T009: failed to instantiate factories")
	await get_tree().process_frame
	var inside_baseline: float = float(inside_factory.get("interval"))
	var outside_baseline: float = float(outside_factory.get("interval"))
	if inside_baseline <= 0.0 or outside_baseline <= 0.0:
		return _fail("US-017 T009: factory baseline interval must be > 0")
	inside_factory.set("timer", inside_baseline * 0.9)
	var remaining_before: float = inside_baseline - float(inside_factory.get("timer"))
	outside_factory.set("timer", outside_baseline * 0.25)
	var outside_timer_before: float = float(outside_factory.get("timer"))

	if not DmManager.launch_blizzard(_spell_at(origin)):
		return _fail("US-017 T009: unlocked launch_blizzard at 100 mana must succeed")
	if DmManager.current_mana != 70:
		return _fail("US-017 T009: blizzard must cost 30 mana, mana is %d" % DmManager.current_mana)
	if _fantasy.claim.live_pocket_count() != pockets_before + 1:
		return _fail("US-017 T009: expected one new Fantasy pocket")
	if DmManager.live_blizzard_count() != 1:
		return _fail("US-017 T009: expected one live blizzard slow rect")

	var covered: Array[Vector2i] = []
	for y in range(origin.y, origin.y + POCKET_SIZE.y):
		for x in range(origin.x, origin.x + POCKET_SIZE.x):
			var cell := Vector2i(x, y)
			if not _interior.has_point(cell):
				continue
			covered.append(cell)
			if not _fantasy.is_claimed_cell(cell):
				return _fail("US-017 T009: 3x3 pocket must cover interior cell %s" % cell)
	if covered.size() != POCKET_SIZE.x * POCKET_SIZE.y:
		return _fail("US-017 T009: pocket must be axis-aligned 3x3, covered %d" % covered.size())

	var pocket: Dictionary = _live_blizzard_pocket()
	if pocket.is_empty():
		return _fail("US-017 T009: missing live pocket dict")
	var duration: float = float(pocket.get("duration", 0.0))
	if absf(duration - DmManager.BLIZZARD_DURATION) > 0.01:
		return _fail("US-017 T009: pocket duration %s expected ~8s" % duration)
	if absf(DmManager.BLIZZARD_DURATION - 8.0) > 0.01:
		return _fail("US-017 T009: BLIZZARD_DURATION must be ~8s, got %s" % DmManager.BLIZZARD_DURATION)
	var remaining: float = float(pocket.get("expires_at", 0.0)) - _fantasy.claim_now()
	if remaining < 7.0 or remaining > 8.5:
		return _fail("US-017 T009: remaining %s not ~8s" % remaining)
	if pocket.has("radius") or pocket.has("circle"):
		return _fail("US-017 T009: pocket must be a rectangle, not a circle")

	inside_factory.call("sync_blizzard_interval")
	outside_factory.call("sync_blizzard_interval")
	var factor: float = DmManager.BLIZZARD_FACTORY_INTERVAL_FACTOR
	if not is_equal_approx(factor, 2.0):
		return _fail("US-017 T009: blizzard factory factor must be 2.0, got %s" % factor)
	if not is_equal_approx(float(inside_factory.get("interval")), inside_baseline * factor):
		return _fail("US-017 T009: origin-in factory interval should be 2x, got %s" % inside_factory.get("interval"))
	var remaining_after: float = float(inside_factory.get("interval")) - float(inside_factory.get("timer"))
	if absf(remaining_after - remaining_before * factor) > 0.001:
		return _fail("US-017 T009: remaining should scale 2x, before=%s after=%s" % [remaining_before, remaining_after])
	if is_equal_approx(float(inside_factory.get("timer")), 0.0):
		return _fail("US-017 T009: 90%% complete must not reset progress to 0")
	if not is_instance_valid(inside_factory):
		return _fail("US-017 T009: occupancy must not destroy the existing factory")
	if not is_equal_approx(float(outside_factory.get("interval")), outside_baseline):
		return _fail("US-017 T009: factory outside pocket must keep baseline interval")
	if not is_equal_approx(float(outside_factory.get("timer")), outside_timer_before):
		return _fail("US-017 T009: factory outside pocket must stay unchanged")

	if not BuildingManager.has_method("is_area_clear"):
		return _fail("US-017 T009: BuildingManager.is_area_clear missing")
	if BuildingManager.is_area_clear(inside_world, BUILDING_SIZE):
		return _fail("US-017 T009: building footprint in live blizzard pocket must reject")

	if RealityClaim.should_despawn_skeleton(get_tree(), inside_world):
		return _fail("US-017 T009: skeleton must be allowed in blizzard pocket without Reality claim")
	if RealityClaim.should_reject_skeleton_spawn(get_tree(), RealityClaim.SKELETON_SCENE_PATH, inside_world):
		return _fail("US-017 T009: skeleton spawn in pocket must not reject")
	var skel: Skeleton = SkeletonScene.instantiate()
	add_child(skel)
	skel.global_position = inside_world
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_instance_valid(skel) or skel._dying:
		return _fail("US-017 T009: skeleton in blizzard pocket must live")

	var paper: Player = PlayerScene.instantiate() as Player
	if paper == null:
		return _fail("US-017 T009: failed to instantiate Player")
	add_child(paper)
	paper.global_position = inside_world
	var paper_start: Vector2 = paper.global_position
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_equal_approx(paper.get_move_speed(), Player.BASE_MOVE_SPEED * 0.5):
		return _fail("US-017 T009: PP inside blizzard should move at 50%%, got %s" % paper.get_move_speed())
	if not paper.global_position.is_equal_approx(paper_start) and not _fantasy.is_claimed_world(paper.global_position):
		return _fail("US-017 T009: Paper Pusher must not be pushed out of the live pocket (T011)")
	if not _fantasy.is_claimed_world(paper.global_position):
		return _fail("US-017 T009: Paper Pusher must remain inside the live pocket (T011)")

	paper.global_position = outside_world
	await get_tree().process_frame
	if not is_equal_approx(paper.get_move_speed(), Player.BASE_MOVE_SPEED):
		return _fail("US-017 T009: PP outside live pocket should be baseline, got %s" % paper.get_move_speed())

	var snap: Dictionary = DmManager.late_join_blizzard_snapshot()
	if not bool(snap.get("unlocks", {}).get(Catalog.BEMIDJI_BLIZZARD, false)):
		return _fail("US-017 T009: late-join snapshot missing bemidji_blizzard unlock")
	var packed_pockets: Array = snap.get("claim", {}).get("pockets", [])
	if packed_pockets.is_empty():
		return _fail("US-017 T009: late-join snapshot missing live pocket")
	var packed_pocket: Dictionary = packed_pockets[0]
	if float(packed_pocket.get("remaining", 0.0)) <= 0.0:
		return _fail("US-017 T009: late-join live pocket remaining must be > 0")
	if int(packed_pocket.get("w", 0)) <= 0 or int(packed_pocket.get("h", 0)) <= 0:
		return _fail("US-017 T009: late-join snapshot missing pocket rect")

	paper.global_position = inside_world
	await get_tree().process_frame
	var expires_at: float = float(pocket.get("expires_at", 0.0))
	_fantasy.expire_due(expires_at + 0.01)
	if _fantasy.claim.live_pocket_count() != pockets_before:
		return _fail("US-017 T009: pocket must be gone after expire_due")
	if DmManager.live_blizzard_count() != 0:
		return _fail("US-017 T009: slow rect must drop in the same expire tick")
	if not is_equal_approx(float(inside_factory.get("interval")), inside_baseline):
		return _fail("US-017 T009: factory interval must return to baseline same tick, got %s" % inside_factory.get("interval"))
	if not is_equal_approx(paper.get_move_speed(), Player.BASE_MOVE_SPEED):
		return _fail("US-017 T009: PP speed must return to baseline same tick, got %s" % paper.get_move_speed())
	if not is_instance_valid(inside_factory):
		return _fail("US-017 T009: factory must survive pocket expire")
	return true


func _make_factory(factory_name: String, world: Vector2) -> Node:
	var node: Node = SmokeFactoryScene.instantiate()
	node.name = factory_name
	add_child(node)
	if node is Node2D:
		(node as Node2D).global_position = world
	node.set("is_ghost", false)
	node.set_process(false)
	return node


func _spell_at(origin: Vector2i) -> Dictionary:
	return {
		"target": DungeonGrid.to_world_center(origin + Vector2i(1, 1)),
		"origin": origin,
		"size": POCKET_SIZE,
		"duration": DmManager.BLIZZARD_DURATION,
		"slow_factor": DmManager.BLIZZARD_SLOW_FACTOR,
	}


func _pocket_origin() -> Vector2i:
	var home: Rect2i = _reality.home_rect
	var origin: Vector2i = Vector2i(home.position.x, home.position.y + 4)
	if origin.y + POCKET_SIZE.y > home.end.y:
		origin.y = home.position.y
	if origin.x < _interior.position.x:
		origin.x = _interior.position.x
	if origin.y < _interior.position.y:
		origin.y = _interior.position.y
	if origin.x + POCKET_SIZE.x > _interior.end.x:
		origin.x = _interior.end.x - POCKET_SIZE.x
	if origin.y + POCKET_SIZE.y > _interior.end.y:
		origin.y = _interior.end.y - POCKET_SIZE.y
	if _fantasy.is_claimed_cell(origin):
		origin = Vector2i(_interior.position.x, _interior.position.y + 4)
	return origin


func _outside_pocket_cell(origin: Vector2i) -> Vector2i:
	var pocket := Rect2i(origin, POCKET_SIZE)
	var home_cell: Vector2i = _reality.home_rect.position
	if not pocket.has_point(home_cell) and not _fantasy.is_claimed_cell(home_cell):
		return home_cell
	for y in range(_reality.home_rect.position.y, _reality.home_rect.end.y):
		for x in range(_reality.home_rect.position.x, _reality.home_rect.end.x):
			var cell := Vector2i(x, y)
			if pocket.has_point(cell):
				continue
			if _fantasy.is_claimed_cell(cell):
				continue
			if not _interior.has_point(cell):
				continue
			return cell
	return Vector2i(_interior.position.x, _interior.end.y - 1)


func _live_blizzard_pocket() -> Dictionary:
	if _fantasy.claim.pockets.is_empty():
		return {}
	return _fantasy.claim.pockets[_fantasy.claim.pockets.size() - 1]


func _baja_bosses(spawns: Array) -> Array:
	var bosses: Array = []
	for spawn in spawns:
		if str(spawn.get("monsterTypeId", "")) == "baja_boss":
			bosses.append(spawn)
	return bosses


func _role_cells(data: Dictionary, role: String) -> Dictionary:
	var cells: Dictionary = {}
	for region in data.get("roomRegions", []):
		if str(region.get("role", "")) != role:
			continue
		for point in region.get("cells", []):
			cells[DungeonGrid.cell_from(point)] = true
	return cells


func _has_baja_drop(expected_pos: Vector2) -> bool:
	for drop in _drops:
		var item_type: String = str(drop.get("item_type", ""))
		if item_type != BAJA_CAN and item_type.find("bajablast") == -1:
			continue
		var pos: Variant = drop.get("position", Vector2.INF)
		if pos is Vector2:
			return true
	var pickups: Array = []
	_collect_pickups(self, pickups)
	for pickup in pickups:
		var data: Variant = pickup.get("item_data")
		if data is ItemData:
			var tex: Texture2D = (data as ItemData).texture
			if tex != null and str(tex.resource_path).find("bajablast") != -1:
				return true
			if str((data as ItemData).resource_path).find("bajablast") != -1:
				return true
	return false


func _collect_pickups(node: Node, out: Array) -> void:
	if node is ItemPickup:
		out.append(node)
	for child in node.get_children():
		_collect_pickups(child, out)


func _on_item_drop(item_data: Dictionary) -> void:
	_drops.append(item_data)


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
