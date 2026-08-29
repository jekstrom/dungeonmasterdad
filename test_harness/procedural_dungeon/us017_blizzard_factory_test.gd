extends Node

## US-017 T006: blizzard doubles factory interval in the pocket.
## user_stories/tasks/US-017/T006-factory-interval.md

const Catalog = preload("res://dm/dm_ability_catalog.gd")
const SmokeFactoryScene = preload("res://buildings/buildables/smoke_factory.tscn")
const PaperFactoryScene = preload("res://buildings/buildables/paper_factory.tscn")
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
	if not await _assert_factory_interval_blizzard():
		return
	print("US-017 T006 blizzard factory test passed")
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
		return _fail("US-017 T006: failed to instantiate zones")
	return true


func _assert_factory_interval_blizzard() -> bool:
	DmUnlocks.dm_unlocks[Catalog.BEMIDJI_BLIZZARD] = true
	DmManager.set_mana(100)
	var origin: Vector2i = _pocket_origin()
	var inside_cell: Vector2i = origin + Vector2i(1, 1)
	var inside_world: Vector2 = DungeonGrid.to_world_center(inside_cell)
	var outside_cell: Vector2i = _outside_pocket_cell(origin)
	var outside_world: Vector2 = DungeonGrid.to_world_center(outside_cell)

	var inside: Node = _make_factory(SmokeFactoryScene, inside_world)
	var paper_inside: Node = _make_factory(PaperFactoryScene, inside_world)
	var outside: Node = _make_factory(SmokeFactoryScene, outside_world)
	if inside == null or paper_inside == null or outside == null:
		return _fail("US-017 T006: failed to instantiate factories")
	await get_tree().process_frame

	var inside_baseline: float = float(inside.get("interval"))
	var paper_baseline: float = float(paper_inside.get("interval"))
	var outside_baseline: float = float(outside.get("interval"))
	if inside_baseline <= 0.0 or paper_baseline <= 0.0 or outside_baseline <= 0.0:
		return _fail("US-017 T006: factory baseline interval must be > 0")

	# 90% complete, then blizzard: remaining doubles, progress not reset to 0.
	inside.set("timer", inside_baseline * 0.9)
	var remaining_before: float = inside_baseline - float(inside.get("timer"))
	outside.set("timer", outside_baseline * 0.25)
	var outside_timer_before: float = float(outside.get("timer"))

	if not DmManager.launch_blizzard(_spell_at(origin)):
		return _fail("US-017 T006: launch_blizzard must succeed")
	if DmManager.live_blizzard_count() != 1:
		return _fail("US-017 T006: expected one live blizzard slow rect")

	inside.call("sync_blizzard_interval")
	paper_inside.call("sync_blizzard_interval")
	outside.call("sync_blizzard_interval")

	var factor: float = DmManager.BLIZZARD_FACTORY_INTERVAL_FACTOR
	if not is_equal_approx(factor, 2.0):
		return _fail("US-017 T006: blizzard factory factor must be configurable 2.0, got %s" % factor)

	if not is_equal_approx(float(inside.get("interval")), inside_baseline * factor):
		return _fail("US-017 T006: inside smoke interval should be 2x, got %s want %s" % [inside.get("interval"), inside_baseline * factor])
	if not is_equal_approx(float(paper_inside.get("interval")), paper_baseline * factor):
		return _fail("US-017 T006: inside paper interval should be 2x, got %s want %s" % [paper_inside.get("interval"), paper_baseline * factor])

	var remaining_after: float = float(inside.get("interval")) - float(inside.get("timer"))
	if absf(remaining_after - remaining_before * factor) > 0.001:
		return _fail("US-017 T006: remaining should scale 2x (10%% -> 20%%), before=%s after=%s" % [remaining_before, remaining_after])
	if is_equal_approx(float(inside.get("timer")), 0.0):
		return _fail("US-017 T006: 90%% complete must not reset progress to 0")
	if not is_instance_valid(inside) or not is_instance_valid(paper_inside):
		return _fail("US-017 T006: occupancy must not destroy the factory")

	if not is_equal_approx(float(outside.get("interval")), outside_baseline):
		return _fail("US-017 T006: factory outside pocket must keep baseline interval, got %s" % outside.get("interval"))
	if not is_equal_approx(float(outside.get("timer")), outside_timer_before):
		return _fail("US-017 T006: factory outside pocket must not scale remaining, timer=%s" % outside.get("timer"))

	# Subsequent interval is 2x: one baseline of time must not complete production.
	var smoke_before: int = PlayerManager.smoke_amt
	inside.set("timer", 0.0)
	inside.call("_process", inside_baseline + 0.01)
	if PlayerManager.smoke_amt != smoke_before:
		return _fail("US-017 T006: 1x duration must not complete a 2x interval")
	if float(inside.get("timer")) >= float(inside.get("interval")):
		return _fail("US-017 T006: timer should still be inside the 2x interval")
	inside.call("_process", inside_baseline)
	if PlayerManager.smoke_amt != smoke_before + 1:
		return _fail("US-017 T006: ~2x duration should complete one smoke, got %s" % PlayerManager.smoke_amt)

	# Expire: baseline in the same tick as pocket removal (no extra process).
	var pocket: Dictionary = _live_blizzard_pocket()
	if pocket.is_empty():
		return _fail("US-017 T006: missing live pocket dict")
	inside.set("timer", float(inside.get("interval")) * 0.9)
	var remaining_at_2x: float = float(inside.get("interval")) - float(inside.get("timer"))
	var expires_at: float = float(pocket.get("expires_at", 0.0))
	_fantasy.expire_due(expires_at + 0.01)
	if _fantasy.claim.live_pocket_count() != 0 and DmManager.live_blizzard_count() != 0:
		# pocket count may include unrelated pockets; blizzard rect must be gone
		pass
	if DmManager.live_blizzard_count() != 0:
		return _fail("US-017 T006: slow rect must drop in the same expire tick")
	if not is_equal_approx(float(inside.get("interval")), inside_baseline):
		return _fail("US-017 T006: interval must return to baseline same tick, got %s" % inside.get("interval"))
	var remaining_at_1x: float = float(inside.get("interval")) - float(inside.get("timer"))
	if absf(remaining_at_1x - remaining_at_2x / factor) > 0.001:
		return _fail("US-017 T006: uncover remaining must /2 so we do not jump complete, got %s want %s" % [remaining_at_1x, remaining_at_2x / factor])
	if float(inside.get("timer")) >= float(inside.get("interval")) and remaining_at_2x > 0.001:
		return _fail("US-017 T006: uncover must not jump the factory complete")
	if not is_equal_approx(float(outside.get("interval")), outside_baseline):
		return _fail("US-017 T006: outside factory must stay baseline after expire")
	if not is_instance_valid(inside):
		return _fail("US-017 T006: factory must survive pocket expire")
	return true


func _make_factory(packed: PackedScene, world: Vector2) -> Node:
	var node: Node = packed.instantiate()
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


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
