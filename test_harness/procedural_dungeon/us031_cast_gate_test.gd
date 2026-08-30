extends Node

## US-031 T001/T007: locked, short mana, empty clip spend nothing; legal spends 30 after pocket.
## user_stories/tasks/US-031/T001-cast-gate.md

const Catalog = preload("res://dm/dm_ability_catalog.gd")
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
	if not await _setup_map():
		return
	if not _assert_locked_cast():
		return
	if not _assert_short_mana():
		return
	if not _assert_empty_clip_no_spend():
		return
	if not _assert_legal_cast_and_second_short():
		return
	print("US-031 T001 cast gate test passed")
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
		return _fail("US-031 T001: failed to instantiate zones")
	return true


func _assert_locked_cast() -> bool:
	DmUnlocks.reset_unlocks()
	DmManager.clear_blizzard_effects()
	DmManager.set_mana(100)
	DmManager.fantasy_level = 0
	if bool(DmUnlocks.dm_unlocks.get("bemidji_blizzard", true)):
		return _fail("US-031 T001: bemidji_blizzard must start locked")
	if DmManager.launch_blizzard(_spell_at(_pocket_origin())):
		return _fail("US-031 T001: locked launch_blizzard must return false")
	if DmManager.current_mana != 100:
		return _fail("US-031 T001: locked cast must not spend, got %d" % DmManager.current_mana)
	if DmManager.live_blizzard_count() != 0:
		return _fail("US-031 T001: locked cast must not register a slow rect")
	if _fantasy.claim.live_pocket_count() != 0:
		return _fail("US-031 T001: locked cast must not plant a pocket")
	if DmManager.fantasy_level != 0:
		return _fail("US-031 T001: locked cast must not change Fantasy Level")
	return true


func _assert_short_mana() -> bool:
	DmUnlocks.dm_unlocks[Catalog.BEMIDJI_BLIZZARD] = true
	DmManager.set_mana(10)
	var pockets_before: int = _fantasy.claim.live_pocket_count()
	if DmManager.launch_blizzard(_spell_at(_pocket_origin())):
		return _fail("US-031 T001: mana 10 launch_blizzard must return false")
	if DmManager.current_mana != 10:
		return _fail("US-031 T001: short mana must not spend, got %d" % DmManager.current_mana)
	if _fantasy.claim.live_pocket_count() != pockets_before:
		return _fail("US-031 T001: short mana must not plant a pocket")
	if DmManager.live_blizzard_count() != 0:
		return _fail("US-031 T001: short mana must not register a slow rect")
	return true


func _assert_empty_clip_no_spend() -> bool:
	DmUnlocks.dm_unlocks[Catalog.BEMIDJI_BLIZZARD] = true
	DmManager.set_mana(100)
	DmManager.fantasy_level = 0
	var off := Vector2i(-40, -40)
	var clipped: Rect2i = _fantasy.clip_pocket_rect(Rect2i(off, POCKET_SIZE))
	if clipped.size.x > 0 and clipped.size.y > 0:
		return _fail("US-031 T001: off-map rect must clip empty, got %s" % clipped)
	var pockets_before: int = _fantasy.claim.live_pocket_count()
	if DmManager.launch_blizzard(_spell_at(off)):
		return _fail("US-031 T001: empty clip launch_blizzard must return false")
	if DmManager.current_mana != 100:
		return _fail("US-031 T001: empty clip must not spend, got %d" % DmManager.current_mana)
	if _fantasy.claim.live_pocket_count() != pockets_before:
		return _fail("US-031 T001: empty clip must not plant a pocket")
	if DmManager.live_blizzard_count() != 0:
		return _fail("US-031 T001: empty clip must not register a slow rect")
	if DmManager.fantasy_level != 0:
		return _fail("US-031 T001: empty clip must not change Fantasy Level")
	return true


func _assert_legal_cast_and_second_short() -> bool:
	DmUnlocks.unlock("bemidji_blizzard")
	DmManager.clear_blizzard_effects()
	DmManager.set_mana(50)
	DmManager.fantasy_level = 0
	var origin: Vector2i = _pocket_origin()
	if not DmManager.launch_blizzard(_spell_at(origin)):
		return _fail("US-031 T001: unlocked launch at 50 mana must succeed")
	if DmManager.current_mana != 20:
		return _fail("US-031 T001: blizzard must cost 30, mana is %d" % DmManager.current_mana)
	if DmManager.live_blizzard_count() != 1:
		return _fail("US-031 T001: expected one live blizzard")
	if DmManager.fantasy_level != 0:
		return _fail("US-031 T001: try_cast must not add Fantasy Level, got %d" % DmManager.fantasy_level)
	var pocket: Dictionary = _live_blizzard_pocket()
	if pocket.is_empty():
		return _fail("US-031 T001: missing live pocket")
	if str(pocket.get("overlay", "")) != "blizzard":
		return _fail("US-031 T001: pocket overlay must be blizzard")
	var rect: Rect2i = pocket["rect"]
	if rect.size.x != POCKET_SIZE.x or rect.size.y != POCKET_SIZE.y:
		return _fail("US-031 T001: expected 3x3 pocket, got %s" % rect.size)
	if not DmManager.launch_blizzard(_spell_at(origin + Vector2i(3, 0))):
		pass
	else:
		return _fail("US-031 T001: second confirm at 20 mana must fail")
	if DmManager.current_mana != 20:
		return _fail("US-031 T001: failed second cast must not spend, got %d" % DmManager.current_mana)
	if DmManager.live_blizzard_count() != 1:
		return _fail("US-031 T001: failed second cast must not add a pocket")
	return true


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


func _live_blizzard_pocket() -> Dictionary:
	if _fantasy.claim.pockets.is_empty():
		return {}
	return _fantasy.claim.pockets[_fantasy.claim.pockets.size() - 1]


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
