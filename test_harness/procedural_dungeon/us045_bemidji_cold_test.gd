extends Node

const Catalog = preload("res://dm/dm_ability_catalog.gd")
const POCKET_SIZE := Vector2i(3, 3)

var _level: Node
var _reality: RealityZone
var _fantasy: FantasyZone
var _interior := Rect2i(0, 0, 16, 10)
var _dungeon := Rect2i(8, 2, 8, 6)


func _ready() -> void:
	if not await _run_suite():
		return
	print("US-045 Bemidji Cold test passed")
	get_tree().quit(0)


func _run_suite() -> bool:
	DmManager.clear_blizzard_effects()
	DmUnlocks.reset_unlocks()
	DmManager.fantasy_level = 0
	if DmUnlocks.is_owned("bemidji_cold"):
		return _fail("US-045 AC1: bemidji_cold must start unowned")
	if not is_equal_approx(DmManager.blizzard_duration(), DmManager.BLIZZARD_DURATION):
		return _fail("US-045 AC1: unowned blizzard_duration must be baseline %s got %s" % [DmManager.BLIZZARD_DURATION, DmManager.blizzard_duration()])
	if not await _setup_map():
		return false
	if not _assert_baseline_cast_duration():
		return false
	if not _assert_owned_cast_duration():
		return false
	if not _assert_clear_ownership_returns_baseline():
		return false
	return true


func _setup_map() -> bool:
	_level = Node2D.new()
	_level.set_script(load("res://_globals/level_manager.gd"))
	_level.add_to_group("level_manager")
	add_child(_level)
	await get_tree().process_frame
	_level.apply_map_interior(_interior, _dungeon)
	await get_tree().process_frame
	_reality = load("res://zones/reality_zone.tscn").instantiate()
	_reality.add_to_group("RealityZone")
	add_child(_reality)
	_fantasy = load("res://zones/fantasy_zone.tscn").instantiate()
	add_child(_fantasy)
	await get_tree().process_frame
	await get_tree().physics_frame
	if _fantasy == null or _reality == null:
		return _fail("US-045: failed to instantiate zones")
	return true


func _assert_baseline_cast_duration() -> bool:
	DmUnlocks.reset_unlocks()
	DmUnlocks.dm_unlocks[Catalog.BEMIDJI_BLIZZARD] = true
	DmManager.clear_blizzard_effects()
	DmManager.set_mana(100)
	if not DmManager.launch_blizzard(_spell_at(_pocket_origin())):
		return _fail("US-045 AC1: baseline launch_blizzard must succeed")
	var pocket: Dictionary = _live_blizzard_pocket()
	if pocket.is_empty():
		return _fail("US-045 AC1: missing live blizzard pocket")
	var duration: float = float(pocket.get("duration", 0.0))
	if absf(duration - DmManager.BLIZZARD_DURATION) > 0.01:
		return _fail("US-045 AC1: unowned pocket duration %s want %s" % [duration, DmManager.BLIZZARD_DURATION])
	return true


func _assert_owned_cast_duration() -> bool:
	DmUnlocks.unlock("bemidji_cold")
	if not DmUnlocks.is_owned("bemidji_cold"):
		return _fail("US-045 FR-001: force-own bemidji_cold must stick")
	var want: float = DmManager.BLIZZARD_DURATION * DmManager.BLIZZARD_COLD_DURATION_SCALE
	if not is_equal_approx(DmManager.blizzard_duration(), want):
		return _fail("US-045 AC2: owned blizzard_duration want %s got %s" % [want, DmManager.blizzard_duration()])
	DmManager.clear_blizzard_effects()
	if _fantasy:
		_fantasy.expire_due(_fantasy.claim_now() + 9999.0)
	DmManager.set_mana(100)
	if not DmManager.launch_blizzard(_spell_at(_pocket_origin() + Vector2i(3, 0))):
		return _fail("US-045 AC2: owned launch_blizzard must succeed")
	var pocket: Dictionary = _live_blizzard_pocket()
	if pocket.is_empty():
		return _fail("US-045 AC2: missing owned blizzard pocket")
	var duration: float = float(pocket.get("duration", 0.0))
	if absf(duration - want) > 0.01:
		return _fail("US-045 AC2: owned pocket duration %s want %s" % [duration, want])
	var remaining: float = float(pocket.get("expires_at", 0.0)) - _fantasy.claim_now()
	if remaining < 11.0 or remaining > 12.5:
		return _fail("US-045 AC2: owned remaining %s not ~12s" % remaining)
	_fantasy.expire_due(_fantasy.claim_now())
	if _fantasy.claim.live_pocket_count() < 1:
		return _fail("US-045 AC2: expire_due(now) must not drop a fresh 12s pocket")
	return true


func _assert_clear_ownership_returns_baseline() -> bool:
	DmUnlocks.lock("bemidji_cold")
	if DmUnlocks.is_owned("bemidji_cold"):
		return _fail("US-045 AC3: lock must clear bemidji_cold")
	if not is_equal_approx(DmManager.blizzard_duration(), DmManager.BLIZZARD_DURATION):
		return _fail("US-045 AC3: cleared ownership must restore baseline duration")
	DmManager.clear_blizzard_effects()
	if _fantasy:
		_fantasy.expire_due(_fantasy.claim_now() + 9999.0)
	DmManager.set_mana(100)
	if not DmManager.launch_blizzard(_spell_at(_pocket_origin() + Vector2i(0, 3))):
		return _fail("US-045 AC3: post-lock launch_blizzard must succeed")
	var pocket: Dictionary = _live_blizzard_pocket()
	var duration: float = float(pocket.get("duration", 0.0))
	if absf(duration - DmManager.BLIZZARD_DURATION) > 0.01:
		return _fail("US-045 AC3: post-lock pocket duration %s want %s" % [duration, DmManager.BLIZZARD_DURATION])
	return true


func _spell_at(origin: Vector2i) -> Dictionary:
	return {
		"target": DungeonGrid.to_world_center(origin + Vector2i(1, 1)),
		"origin": origin,
		"size": POCKET_SIZE,
		"duration": 99.0,
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


func _live_blizzard_pocket() -> Dictionary:
	if _fantasy == null or _fantasy.claim.pockets.is_empty():
		return {}
	return _fantasy.claim.pockets[_fantasy.claim.pockets.size() - 1]


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
