extends Node

## US-017 T005: Bemidji Blizzard plants a Fantasy pocket and slows PPs.
## user_stories/tasks/US-017/T005-cast-pocket-slow.md
## Pocket size: 3x3 cells (CELL_PX=128). Duration default 8s. Slow factor 0.5 on the spell rect.

const Catalog = preload("res://dm/dm_ability_catalog.gd")
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
	if not await _setup_map():
		return
	if not _assert_locked_cast():
		return
	if not _assert_short_mana():
		return
	if not await _assert_cast_pocket_slow_and_expire():
		return
	print("US-017 T005 blizzard cast test passed")
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
		return _fail("US-017 T005: failed to instantiate zones")
	return true


func _assert_locked_cast() -> bool:
	DmUnlocks.reset_unlocks()
	DmManager.clear_blizzard_effects()
	DmManager.set_mana(100)
	if bool(DmUnlocks.dm_unlocks.get("bemidji_blizzard", true)):
		return _fail("US-017 T005: bemidji_blizzard must start locked")
	if DmManager.current_mana != 100:
		return _fail("US-017 T005: failed to set mana 100, got %d" % DmManager.current_mana)
	var pockets_before: int = _fantasy.claim.live_pocket_count()
	var spell := _spell_at(_pocket_origin())
	if DmManager.launch_blizzard(spell):
		return _fail("US-017 T005: locked launch_blizzard must return false")
	if DmManager.current_mana != 100:
		return _fail("US-017 T005: locked cast must not spend mana, got %d" % DmManager.current_mana)
	if _fantasy.claim.live_pocket_count() != pockets_before:
		return _fail("US-017 T005: locked cast must not plant a Fantasy pocket")
	if DmManager.live_blizzard_count() != 0:
		return _fail("US-017 T005: locked cast must not register a slow rect")
	return true


func _assert_short_mana() -> bool:
	DmUnlocks.dm_unlocks[Catalog.BEMIDJI_BLIZZARD] = true
	DmManager.set_mana(20)
	var pockets_before: int = _fantasy.claim.live_pocket_count()
	if DmManager.launch_blizzard(_spell_at(_pocket_origin())):
		return _fail("US-017 T005: short mana launch_blizzard must return false")
	if DmManager.current_mana != 20:
		return _fail("US-017 T005: short mana must not spend, got %d" % DmManager.current_mana)
	if _fantasy.claim.live_pocket_count() != pockets_before:
		return _fail("US-017 T005: short mana must not plant a pocket")
	if DmManager.live_blizzard_count() != 0:
		return _fail("US-017 T005: short mana must not register a slow rect")
	return true


func _assert_cast_pocket_slow_and_expire() -> bool:
	DmUnlocks.dm_unlocks[Catalog.BEMIDJI_BLIZZARD] = true
	DmManager.set_mana(100)
	var origin: Vector2i = _pocket_origin()
	var pockets_before: int = _fantasy.claim.live_pocket_count()
	if not DmManager.launch_blizzard(_spell_at(origin)):
		return _fail("US-017 T005: unlocked launch_blizzard at 100 mana must succeed")
	if DmManager.current_mana != 70:
		return _fail("US-017 T005: blizzard must cost 30, mana is %d" % DmManager.current_mana)
	if _fantasy.claim.live_pocket_count() != pockets_before + 1:
		return _fail("US-017 T005: expected one new Fantasy pocket")
	if DmManager.live_blizzard_count() != 1:
		return _fail("US-017 T005: expected one live blizzard slow rect")

	var covered: Array[Vector2i] = []
	for y in range(origin.y, origin.y + POCKET_SIZE.y):
		for x in range(origin.x, origin.x + POCKET_SIZE.x):
			var cell := Vector2i(x, y)
			if not _interior.has_point(cell):
				continue
			covered.append(cell)
			if not _fantasy.is_claimed_cell(cell):
				return _fail("US-017 T005: pocket must cover interior cell %s" % cell)

	var pocket: Dictionary = _live_blizzard_pocket()
	if pocket.is_empty():
		return _fail("US-017 T005: missing live pocket dict")
	var duration: float = float(pocket.get("duration", 0.0))
	if absf(duration - DmManager.BLIZZARD_DURATION) > 0.01:
		return _fail("US-017 T005: pocket duration %s expected ~8s" % duration)
	var remaining: float = float(pocket.get("expires_at", 0.0)) - _fantasy.claim_now()
	if remaining < 7.0 or remaining > 8.5:
		return _fail("US-017 T005: remaining %s not ~8s" % remaining)

	# Same-tick expire_due at current now must not drop an 8s pocket.
	_fantasy.expire_due(_fantasy.claim_now())
	if _fantasy.claim.live_pocket_count() != pockets_before + 1:
		return _fail("US-017 T005: expire_due(now) must not expire a fresh 8s pocket")

	var inside_cell: Vector2i = covered[covered.size() / 2]
	var inside_world: Vector2 = DungeonGrid.to_world_center(inside_cell)
	var outside_cell: Vector2i = _outside_pocket_cell(origin)
	var outside_world: Vector2 = DungeonGrid.to_world_center(outside_cell)

	if not _assert_building_reject(inside_world, outside_world):
		return false

	var paper: Player = _make_paper_pusher()
	if paper == null:
		return _fail("US-017 T005: failed to instantiate Player")
	add_child(paper)
	paper.global_position = inside_world
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_equal_approx(paper.get_move_speed(), Player.BASE_MOVE_SPEED * 0.5):
		return _fail("US-017 T005: PP inside blizzard should move at 150, got %s" % paper.get_move_speed())
	# T011: do not assert push-out; PP must remain in the rect.
	if not _fantasy.is_claimed_world(paper.global_position):
		return _fail("US-017 T005: Paper Pusher must remain inside the live pocket (no push-out)")

	paper.global_position = outside_world
	await get_tree().process_frame
	if not is_equal_approx(paper.get_move_speed(), Player.BASE_MOVE_SPEED):
		return _fail("US-017 T005: PP outside live pocket should be baseline 300, got %s" % paper.get_move_speed())

	var expires_at: float = float(pocket.get("expires_at", 0.0))
	_fantasy.expire_due(expires_at + 0.01)
	if _fantasy.claim.live_pocket_count() != pockets_before:
		return _fail("US-017 T005: pocket must be gone after expire_due")
	if DmManager.live_blizzard_count() != 0:
		return _fail("US-017 T005: slow rect must drop in the same expire tick")
	paper.global_position = inside_world
	await get_tree().process_frame
	if not is_equal_approx(paper.get_move_speed(), Player.BASE_MOVE_SPEED):
		return _fail("US-017 T005: PP speed must return to 300 after expire, got %s" % paper.get_move_speed())
	return true


func _assert_building_reject(inside_world: Vector2, outside_world: Vector2) -> bool:
	if not BuildingManager.has_method("is_area_clear"):
		return _fail("US-017 T005: BuildingManager.is_area_clear missing")
	if BuildingManager.is_area_clear(inside_world, BUILDING_SIZE):
		return _fail("US-017 T005: building footprint in live blizzard pocket must reject")
	if not _reality.is_claimed_world(outside_world):
		print("US-017 T005: skip outside-pocket building accept; cell not Reality")
		return true
	if _fantasy.is_claimed_world(outside_world):
		print("US-017 T005: skip outside-pocket building accept; cell is Fantasy")
		return true
	if not BuildingManager.is_area_clear(outside_world, BUILDING_SIZE):
		return _fail("US-017 T005: building footprint outside the pocket must still accept")
	return true


func _make_paper_pusher() -> Player:
	var packed: PackedScene = load("res://player/player.tscn") as PackedScene
	if packed == null:
		return null
	var node: Node = packed.instantiate()
	if node is Player:
		return node as Player
	return null


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
	# Leave home.position free so building-accept has a known-good Reality cell.
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


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
