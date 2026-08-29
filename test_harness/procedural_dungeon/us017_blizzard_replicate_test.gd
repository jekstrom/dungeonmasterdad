extends Node

## US-017 T008: host-authoritative blizzard unlock, pocket, slow, and factory timers.
## user_stories/tasks/US-017/T008-replicate-late-join.md
## Late join payload is unlock bit, live pocket rect + remaining, overlay blizzard,
## slow rects / who is slowed, and factory remaining scaled time.
## Does not replicate particle RNG (US-026) or a PP shove (T011 walk).

const Catalog = preload("res://dm/dm_ability_catalog.gd")
const SmokeFactoryScene = preload("res://buildings/buildables/smoke_factory.tscn")
const POCKET_SIZE := Vector2i(3, 3)

var _level: Node
var _reality: RealityZone
var _fantasy: FantasyZone
var _peer_fantasy: FantasyZone
var _interior := Rect2i(0, 0, 16, 10)
var _dungeon := Rect2i(8, 2, 8, 6)


func _ready() -> void:
	DmManager.clear_blizzard_effects()
	DmUnlocks.reset_unlocks()
	DmManager.fantasy_level = 0
	PlayerManager.reality_level = 0
	if not _assert_unlock_replicate():
		return
	if not await _setup_map():
		return
	if not await _assert_live_snapshot_and_expire():
		return
	print("US-017 T008 blizzard replicate test passed")
	get_tree().quit(0)


func _assert_unlock_replicate() -> bool:
	DmUnlocks.reset_unlocks()
	if bool(DmUnlocks.dm_unlocks.get(Catalog.BEMIDJI_BLIZZARD, true)):
		return _fail("US-017 T008: bemidji_blizzard must start locked")
	DmUnlocks.dm_unlocks[Catalog.BEMIDJI_BLIZZARD] = true
	var payload: Dictionary = DmUnlocks.snapshot()
	if not bool(payload.get(Catalog.BEMIDJI_BLIZZARD, false)):
		return _fail("US-017 T008: snapshot must include bemidji_blizzard unlock bit")
	DmUnlocks.dm_unlocks[Catalog.BEMIDJI_BLIZZARD] = false
	DmUnlocks.apply_replicated_unlocks(payload)
	if not bool(DmUnlocks.dm_unlocks.get(Catalog.BEMIDJI_BLIZZARD, false)):
		return _fail("US-017 T008: client must receive host bemidji_blizzard unlock")
	DmUnlocks.dm_unlocks[Catalog.BEMIDJI_BLIZZARD] = true
	var host_locked: Dictionary = {
		"fireball": false,
		"shadow_zone": false,
		"knightling": false,
		"bemidji_blizzard": false,
	}
	DmUnlocks.apply_replicated_unlocks(host_locked)
	if bool(DmUnlocks.dm_unlocks.get(Catalog.BEMIDJI_BLIZZARD, true)):
		return _fail("US-017 T008: host snapshot must overwrite a client-local unlock")
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
	_fantasy.name = "HostFantasy"
	add_child(_fantasy)
	_peer_fantasy = load("res://zones/fantasy_zone.tscn").instantiate()
	_peer_fantasy.name = "PeerFantasy"
	add_child(_peer_fantasy)
	await get_tree().process_frame
	await get_tree().physics_frame
	if _fantasy == null or _reality == null or _peer_fantasy == null:
		return _fail("US-017 T008: failed to instantiate zones")
	return true


func _assert_live_snapshot_and_expire() -> bool:
	DmUnlocks.dm_unlocks[Catalog.BEMIDJI_BLIZZARD] = true
	DmManager.set_mana(100)
	var origin: Vector2i = _pocket_origin()
	var inside_cell: Vector2i = origin + Vector2i(1, 1)
	var inside_world: Vector2 = DungeonGrid.to_world_center(inside_cell)
	var outside_cell: Vector2i = _outside_pocket_cell(origin)
	var outside_world: Vector2 = DungeonGrid.to_world_center(outside_cell)

	var inside: Node = _make_factory("InsideSmoke", inside_world)
	var outside: Node = _make_factory("OutsideSmoke", outside_world)
	if inside == null or outside == null:
		return _fail("US-017 T008: failed to instantiate factories")
	await get_tree().process_frame
	var inside_baseline: float = float(inside.get("interval"))
	var outside_baseline: float = float(outside.get("interval"))
	inside.set("timer", inside_baseline * 0.9)
	var remaining_before: float = inside_baseline - float(inside.get("timer"))

	var paper := Node2D.new()
	paper.name = "LateJoinPaper"
	paper.add_to_group("players")
	add_child(paper)
	paper.global_position = inside_world
	var paper_start: Vector2 = paper.global_position

	if not DmManager.launch_blizzard(_spell_at(origin)):
		return _fail("US-017 T008: launch_blizzard must succeed")
	inside.call("sync_blizzard_interval")
	outside.call("sync_blizzard_interval")
	if DmManager.live_blizzard_count() != 1:
		return _fail("US-017 T008: expected one live blizzard slow rect")

	var snap: Dictionary = DmManager.late_join_blizzard_snapshot()
	if snap.has("rng") or snap.has("particles") or snap.has("seed"):
		return _fail("US-017 T008: must not replicate particle RNG")
	if snap.has("players"):
		return _fail("US-017 T008: must not pack Paper Pusher displacement")
	if not bool(snap.get("unlocks", {}).get(Catalog.BEMIDJI_BLIZZARD, false)):
		return _fail("US-017 T008: late-join payload missing bemidji_blizzard unlock")

	var claim: Dictionary = snap.get("claim", {})
	var packed_pockets: Array = claim.get("pockets", [])
	if packed_pockets.is_empty():
		return _fail("US-017 T008: snapshot missing live pocket")
	var packed_pocket: Dictionary = packed_pockets[0]
	if str(packed_pocket.get("overlay", "")) != "blizzard":
		return _fail("US-017 T008: pocket overlay must be blizzard, got %s" % packed_pocket.get("overlay", ""))
	if float(packed_pocket.get("remaining", 0.0)) <= 0.0:
		return _fail("US-017 T008: live pocket remaining duration must be > 0")
	if int(packed_pocket.get("w", 0)) <= 0 or int(packed_pocket.get("h", 0)) <= 0:
		return _fail("US-017 T008: snapshot missing live pocket rect")

	var slows: Array = snap.get("slows", [])
	if slows.is_empty():
		return _fail("US-017 T008: snapshot missing slow rect")
	var slow: Dictionary = slows[0]
	if int(slow.get("w", 0)) <= 0 or int(slow.get("h", 0)) <= 0:
		return _fail("US-017 T008: slow rect missing size")
	if absf(float(slow.get("slow_factor", 0.0)) - DmManager.BLIZZARD_SLOW_FACTOR) > 0.01:
		return _fail("US-017 T008: slow factor should be 0.5, got %s" % slow.get("slow_factor"))
	var slowed: Array = snap.get("slowed", [])
	if slowed.is_empty():
		return _fail("US-017 T008: snapshot must list who is slowed")

	var factories: Array = snap.get("factories", [])
	var inside_pack: Dictionary = _factory_pack(factories, "InsideSmoke")
	var outside_pack: Dictionary = _factory_pack(factories, "OutsideSmoke")
	if inside_pack.is_empty() or outside_pack.is_empty():
		return _fail("US-017 T008: snapshot missing factory timers")
	var factor: float = DmManager.BLIZZARD_FACTORY_INTERVAL_FACTOR
	if absf(float(inside_pack.get("interval", 0.0)) - inside_baseline * factor) > 0.001:
		return _fail("US-017 T008: inside factory snapshot interval should be 2x, got %s" % inside_pack.get("interval"))
	if absf(float(inside_pack.get("remaining", 0.0)) - remaining_before * factor) > 0.001:
		return _fail("US-017 T008: inside factory remaining should scale 2x, got %s" % inside_pack.get("remaining"))
	if absf(float(outside_pack.get("interval", 0.0)) - outside_baseline) > 0.001:
		return _fail("US-017 T008: outside factory snapshot must stay baseline, got %s" % outside_pack.get("interval"))
	print("US-017 T008 late-join payload unlocks=%s pocket=%s slows=%s slowed=%s factories=%s" % [
		snap.get("unlocks", {}), packed_pocket, slows, slowed, factories
	])

	var fresh: Dictionary = snap.duplicate(true)
	DmUnlocks.reset_unlocks()
	DmManager.clear_blizzard_effects()
	if bool(DmUnlocks.dm_unlocks.get(Catalog.BEMIDJI_BLIZZARD, true)):
		return _fail("US-017 T008: reset must lock bemidji_blizzard before apply")
	if DmManager.live_blizzard_count() != 0:
		return _fail("US-017 T008: cleared client must have no slow rects before apply")
	DmManager.apply_late_join_blizzard_snapshot(fresh)
	if not bool(DmUnlocks.dm_unlocks.get(Catalog.BEMIDJI_BLIZZARD, false)):
		return _fail("US-017 T008: apply replicated payload must set client bemidji_blizzard")
	if DmManager.live_blizzard_count() != 1:
		return _fail("US-017 T008: apply must restore live slow rect")
	if not is_equal_approx(DmManager.blizzard_slow_factor_at(inside_world), DmManager.BLIZZARD_SLOW_FACTOR):
		return _fail("US-017 T008: client blizzard_slow_factor_at inside should be 0.5, got %s" % DmManager.blizzard_slow_factor_at(inside_world))
	if not is_equal_approx(DmManager.blizzard_slow_factor_at(outside_world), 1.0):
		return _fail("US-017 T008: client blizzard_slow_factor_at outside should be 1.0")

	inside.set("interval", inside_baseline)
	inside.set("timer", 0.0)
	inside.set("_applied_blizzard_factor", 1.0)
	DmManager.apply_factory_timers(fresh.get("factories", []))
	if absf(float(inside.get("interval")) - inside_baseline * factor) > 0.001:
		return _fail("US-017 T008: apply factory snapshot must restore 2x interval")

	_peer_fantasy.apply_claim_sync_payload(fresh.get("claim", {}))
	await get_tree().process_frame
	if not _peer_fantasy.is_claimed_cell(inside_cell):
		return _fail("US-017 T008: peer must claim live blizzard pocket cell")
	if _ice_sprite_count(_peer_fantasy) <= 0:
		return _fail("US-017 T008: late join must see blizzard ice overlay")
	if paper.global_position != paper_start and not paper.global_position.is_equal_approx(paper_start):
		return _fail("US-017 T008: snapshot apply must not shove the Paper Pusher")

	var pocket: Dictionary = _live_blizzard_pocket()
	if pocket.is_empty():
		return _fail("US-017 T008: missing live pocket dict")
	var expires_at: float = float(pocket.get("expires_at", 0.0))
	_fantasy.expire_due(expires_at + 0.01)
	if DmManager.live_blizzard_count() != 0:
		return _fail("US-017 T008: slow rect must drop after expire")
	var expired: Dictionary = DmManager.late_join_blizzard_snapshot()
	if not expired.get("slows", []).is_empty():
		return _fail("US-017 T008: expire snapshot must have no slow rects")
	for item in expired.get("claim", {}).get("pockets", []):
		if typeof(item) == TYPE_DICTIONARY and str(item.get("overlay", "")) == "blizzard":
			return _fail("US-017 T008: expire snapshot must have no live blizzard pocket")
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


func _factory_pack(factories: Array, factory_name: String) -> Dictionary:
	for item in factories:
		if typeof(item) == TYPE_DICTIONARY and str(item.get("name", "")) == factory_name:
			return item
	return {}


func _ice_sprite_count(zone: Node) -> int:
	var overlay: Node = zone.get_node_or_null("PocketOverlay")
	if overlay == null:
		return 0
	var n: int = 0
	for child in overlay.get_children():
		if not (child is Sprite2D):
			continue
		var sprite: Sprite2D = child
		if sprite.texture == null:
			continue
		if str(sprite.texture.resource_path).find("blizzard_overlay.png") != -1:
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
