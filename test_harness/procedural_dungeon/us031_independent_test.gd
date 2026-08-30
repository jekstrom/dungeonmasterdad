extends Node

## US-031 T007 independent test: unlock without boss, cast, ice, fall VFX, slow, factory, expire.
## user_stories/tasks/US-031/T007-verification-harness.md
##
## Two-window play pass (host + client; not executed headless):
## Host as DM with blizzard unlocked. Cast on Reality home: ice on the ground,
## snow/icicles falling in the rect, PP walks through slowed, buildings won't place,
## factories tick slower. Second window matches pocket, ground ice, slow, factory
## timing (flake timing need not match). Expire clears ice, fall VFX, and speeds.

const Catalog = preload("res://dm/dm_ability_catalog.gd")
const SmokeFactoryScene := preload("res://buildings/buildables/smoke_factory.tscn")
const PlayerScene := preload("res://player/player.tscn")
const GoblinScene := preload("res://monsters/goblin.tscn")
const BUILDING_SIZE := Vector2(128, 128)
const POCKET_SIZE := Vector2i(3, 3)

var _level: Node
var _reality: RealityZone
var _fantasy: FantasyZone
var _interior := Rect2i(0, 0, 16, 10)
var _dungeon := Rect2i(8, 2, 8, 6)


func _ready() -> void:
	DmManager.clear_blizzard_effects()
	DmUnlocks.reset_unlocks()
	DmManager.fantasy_level = 0
	PlayerManager.reality_level = 0
	PlayerManager.smoke_amt = 0
	if not await _setup_map():
		return
	if not _assert_locked_and_short_mana():
		return
	if not await _assert_cast_slow_factory_vfx_expire():
		return
	print("US-031 T007 independent test passed")
	get_tree().quit(0)


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
		return _fail("US-031 T007: failed to instantiate zones")
	return true


func _assert_locked_and_short_mana() -> bool:
	DmUnlocks.reset_unlocks()
	DmManager.set_mana(100)
	if DmManager.launch_blizzard(_spell_at(_pocket_origin())):
		return _fail("US-031 T007: locked launch must fail")
	if DmManager.current_mana != 100 or DmManager.live_blizzard_count() != 0:
		return _fail("US-031 T007: locked must not spend or plant")
	DmUnlocks.unlock("bemidji_blizzard")
	DmManager.set_mana(10)
	if DmManager.launch_blizzard(_spell_at(_pocket_origin())):
		return _fail("US-031 T007: mana 10 launch must fail")
	if DmManager.current_mana != 10 or DmManager.live_blizzard_count() != 0:
		return _fail("US-031 T007: short mana must not spend or plant")
	return true


func _assert_cast_slow_factory_vfx_expire() -> bool:
	DmUnlocks.unlock("bemidji_blizzard")
	DmManager.set_mana(100)
	DmManager.fantasy_level = 0
	var origin: Vector2i = _pocket_origin()
	var inside_cell: Vector2i = origin + Vector2i(1, 1)
	var inside_world: Vector2 = DungeonGrid.to_world_center(inside_cell)
	var outside_cell: Vector2i = _outside_pocket_cell(origin)
	var outside_world: Vector2 = DungeonGrid.to_world_center(outside_cell)
	var pockets_before: int = _fantasy.claim.live_pocket_count()

	var inside_factory: Node = _make_factory("Us031InsideSmoke", inside_world)
	var outside_factory: Node = _make_factory("Us031OutsideSmoke", outside_world)
	if inside_factory == null or outside_factory == null:
		return _fail("US-031 T007: failed to instantiate factories")
	await get_tree().process_frame
	var inside_baseline: float = float(inside_factory.get("interval"))
	var outside_baseline: float = float(outside_factory.get("interval"))
	inside_factory.set("timer", inside_baseline * 0.9)
	var remaining_before: float = inside_baseline - float(inside_factory.get("timer"))
	outside_factory.set("timer", outside_baseline * 0.25)

	if not DmManager.launch_blizzard(_spell_at(origin)):
		return _fail("US-031 T007: unlocked launch at 100 mana must succeed")
	if DmManager.current_mana != 70:
		return _fail("US-031 T007: blizzard must cost 30, mana is %d" % DmManager.current_mana)
	if DmManager.fantasy_level != 0:
		return _fail("US-031 T007: try_cast must not add Fantasy Level")
	if _fantasy.claim.live_pocket_count() != pockets_before + 1:
		return _fail("US-031 T007: expected one new Fantasy pocket")
	if DmManager.live_blizzard_count() != 1:
		return _fail("US-031 T007: expected one live blizzard")
	var pocket: Dictionary = _live_blizzard_pocket()
	if str(pocket.get("overlay", "")) != "blizzard":
		return _fail("US-031 T007: overlay key must be blizzard")
	var duration: float = float(pocket.get("duration", 0.0))
	if absf(duration - 8.0) > 0.01:
		return _fail("US-031 T007: duration must be ~8s, got %s" % duration)
	if _ice_sprite_count() <= 0:
		return _fail("US-031 T007: live pocket must show ice overlay")
	if _fantasy.live_blizzard_fall_count() != 1:
		return _fail("US-031 T007: live pocket must spawn fall VFX")

	inside_factory.call("sync_blizzard_interval")
	outside_factory.call("sync_blizzard_interval")
	if not is_equal_approx(float(inside_factory.get("interval")), inside_baseline * 2.0):
		return _fail("US-031 T007: origin-in factory interval should be 2x")
	var remaining_after: float = float(inside_factory.get("interval")) - float(inside_factory.get("timer"))
	if absf(remaining_after - remaining_before * 2.0) > 0.001:
		return _fail("US-031 T007: 90%% complete remaining must double")
	if is_equal_approx(float(inside_factory.get("timer")), 0.0):
		return _fail("US-031 T007: 90%% complete must not reset to 0")
	if not is_instance_valid(inside_factory):
		return _fail("US-031 T007: occupancy must not destroy the factory")
	if not is_equal_approx(float(outside_factory.get("interval")), outside_baseline):
		return _fail("US-031 T007: outside factory must stay baseline")
	if BuildingManager.is_area_clear(inside_world, BUILDING_SIZE):
		return _fail("US-031 T007: building footprint in pocket must reject")

	var paper: Player = PlayerScene.instantiate() as Player
	add_child(paper)
	paper.global_position = inside_world
	await get_tree().process_frame
	await get_tree().physics_frame
	if not is_equal_approx(paper.get_move_speed(), Player.BASE_MOVE_SPEED * 0.5):
		return _fail("US-031 T007: PP inside should move at 150, got %s" % paper.get_move_speed())
	if not _fantasy.is_claimed_world(paper.global_position):
		return _fail("US-031 T007: PP must remain inside the pocket")
	paper.global_position = outside_world
	await get_tree().process_frame
	if not is_equal_approx(paper.get_move_speed(), Player.BASE_MOVE_SPEED):
		return _fail("US-031 T007: PP outside should be 300, got %s" % paper.get_move_speed())

	var goblin: Node = GoblinScene.instantiate()
	add_child(goblin)
	if goblin is Node2D:
		(goblin as Node2D).global_position = inside_world
	await get_tree().process_frame
	var aggro: Node = goblin.get_node_or_null("EnemyStateMachine/aggro")
	if aggro == null:
		return _fail("US-031 T007: goblin aggro state missing")
	if not is_equal_approx(float(aggro.get("run_speed")), 220.0):
		return _fail("US-031 T007: goblin run_speed must stay 220, got %s" % aggro.get("run_speed"))

	var snap: Dictionary = DmManager.late_join_blizzard_snapshot()
	if not bool(snap.get("unlocks", {}).get(Catalog.BEMIDJI_BLIZZARD, false)):
		return _fail("US-031 T007: late-join snapshot missing bemidji_blizzard unlock")
	if snap.get("claim", {}).get("pockets", []).is_empty():
		return _fail("US-031 T007: late-join snapshot missing live pocket")
	if snap.get("slows", []).is_empty():
		return _fail("US-031 T007: late-join snapshot missing slows")

	paper.global_position = inside_world
	await get_tree().process_frame
	var expires_at: float = float(pocket.get("expires_at", 0.0))
	_fantasy.expire_due(expires_at + 0.01)
	if _fantasy.claim.live_pocket_count() != pockets_before:
		return _fail("US-031 T007: pocket must be gone after expire")
	if DmManager.live_blizzard_count() != 0:
		return _fail("US-031 T007: slow rect must drop same tick")
	if not is_equal_approx(float(inside_factory.get("interval")), inside_baseline):
		return _fail("US-031 T007: factory interval must return to baseline")
	if not is_equal_approx(paper.get_move_speed(), Player.BASE_MOVE_SPEED):
		return _fail("US-031 T007: PP speed must return to baseline")
	if _ice_sprite_count() != 0:
		return _fail("US-031 T007: ice overlay must clear on expire")
	if _fantasy.live_blizzard_fall_count() != 0:
		return _fail("US-031 T007: fall VFX must clear on expire")
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


func _ice_sprite_count() -> int:
	var overlay: Node = _fantasy.get_node_or_null("PocketOverlay")
	if overlay == null:
		return 0
	var n: int = 0
	for child in overlay.get_children():
		if not (child is Sprite2D):
			continue
		var sprite: Sprite2D = child
		if sprite.texture and str(sprite.texture.resource_path).find("blizzard_overlay.png") != -1:
			n += 1
	return n


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


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
