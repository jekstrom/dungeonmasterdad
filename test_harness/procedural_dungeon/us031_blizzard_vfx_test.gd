extends Node

## US-031 T008: ground ice overlay plus local falling snow/icicles on the live rect.
## user_stories/tasks/US-031/T008-blizzard-vfx-art.md

const Catalog = preload("res://dm/dm_ability_catalog.gd")
const POCKET_SIZE := Vector2i(3, 3)
const ICE_PATH := "res://sprites/blizzard_overlay.png"
const SNOW_PATH := "res://spells/blizzard/snowflake.png"
const ICICLE_PATH := "res://spells/blizzard/icicle.png"

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
	if not _assert_art_files():
		return
	if not await _setup_map():
		return
	if not await _assert_live_ice_and_fall_then_expire():
		return
	print("US-031 T008 blizzard vfx test passed")
	get_tree().quit(0)


func _assert_art_files() -> bool:
	if not ResourceLoader.exists(ICE_PATH):
		return _fail("US-031 T008: missing sprites/blizzard_overlay.png")
	if not ResourceLoader.exists(SNOW_PATH):
		return _fail("US-031 T008: missing spells/blizzard/snowflake.png")
	if not ResourceLoader.exists(ICICLE_PATH):
		return _fail("US-031 T008: missing spells/blizzard/icicle.png")
	if SNOW_PATH.find("fantasy_sparkle") != -1 or SNOW_PATH.find("drift_puff") != -1:
		return _fail("US-031 T008: snowflake must not reuse US-026 sparkles")
	if ICICLE_PATH.find("sparks.png") != -1:
		return _fail("US-031 T008: icicle must not reuse sparks.png")
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
		return _fail("US-031 T008: failed to instantiate zones")
	return true


func _assert_live_ice_and_fall_then_expire() -> bool:
	DmUnlocks.unlock("bemidji_blizzard")
	DmManager.set_mana(100)
	var origin: Vector2i = _pocket_origin()
	if not DmManager.launch_blizzard(_spell_at(origin)):
		return _fail("US-031 T008: launch_blizzard must succeed")
	await get_tree().process_frame
	var ice: int = _ice_sprite_count()
	var covered: int = _covered_cell_count(origin)
	if ice <= 0:
		return _fail("US-031 T008: live pocket must show blizzard_overlay.png ice")
	if ice != covered:
		return _fail("US-031 T008: ice sprites %d expected %d pocket cells" % [ice, covered])
	if _fantasy.live_blizzard_fall_count() != 1:
		return _fail("US-031 T008: expected one fall VFX node, got %d" % _fantasy.live_blizzard_fall_count())
	var vfx: Node = _live_fall_vfx()
	if vfx == null:
		return _fail("US-031 T008: missing blizzard_fall_vfx node")
	if str(vfx.call("snowflake_path")).find("snowflake.png") == -1:
		return _fail("US-031 T008: fall VFX must use snowflake.png")
	if str(vfx.call("icicle_path")).find("icicle.png") == -1:
		return _fail("US-031 T008: fall VFX must use icicle.png")
	if str(vfx.call("snowflake_path")).find("fantasy_sparkle") != -1:
		return _fail("US-031 T008: must not use fantasy_sparkle.png")
	var world: Rect2 = vfx.call("world_rect")
	var expect: Rect2 = Zone.cell_world_rect(Rect2i(origin, POCKET_SIZE))
	if not world.has_area():
		return _fail("US-031 T008: fall VFX world rect must match the pocket")
	if not world.position.is_equal_approx(expect.position):
		return _fail("US-031 T008: fall VFX origin %s must match ice overlay %s" % [world.position, expect.position])
	if absf(world.size.x - expect.size.x) > 1.0 or absf(world.size.y - expect.size.y) > 1.0:
		return _fail("US-031 T008: fall AABB size %s expected %s" % [world.size, expect.size])
	var snow: CPUParticles2D = vfx.get_node_or_null("Snow") as CPUParticles2D
	var icicles: CPUParticles2D = vfx.get_node_or_null("Icicles") as CPUParticles2D
	if snow == null or not snow.emitting:
		return _fail("US-031 T008: snow emitter must emit while live")
	if icicles == null or not icicles.emitting:
		return _fail("US-031 T008: icicle emitter must emit while live")
	var snap: Dictionary = DmManager.late_join_blizzard_snapshot()
	var pocket: Dictionary = _live_blizzard_pocket()
	var expires_at: float = float(pocket.get("expires_at", 0.0))
	_fantasy.expire_due(expires_at + 0.01)
	if _ice_sprite_count() != 0:
		return _fail("US-031 T008: ice overlay must clear on expire")
	if _fantasy.live_blizzard_fall_count() != 0:
		return _fail("US-031 T008: fall VFX must stop on expire")
	if get_tree().get_nodes_in_group("blizzard_fall_vfx").size() != 0:
		return _fail("US-031 T008: blizzard_fall_vfx group must be empty after expire")
	DmManager.apply_late_join_blizzard_snapshot(snap)
	await get_tree().process_frame
	if _ice_sprite_count() <= 0:
		return _fail("US-031 T008: late join must start ice overlay from replicated rect")
	if _fantasy.live_blizzard_fall_count() != 1:
		return _fail("US-031 T008: late join must start local fall VFX from replicated rect")
	return true


func _live_fall_vfx() -> Node:
	for node in get_tree().get_nodes_in_group("blizzard_fall_vfx"):
		if is_instance_valid(node):
			return node
	return null


func _ice_sprite_count() -> int:
	var overlay: Node = _fantasy.get_node_or_null("PocketOverlay")
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


func _covered_cell_count(origin: Vector2i) -> int:
	var n: int = 0
	for y in range(origin.y, origin.y + POCKET_SIZE.y):
		for x in range(origin.x, origin.x + POCKET_SIZE.x):
			if _interior.has_point(Vector2i(x, y)):
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


func _live_blizzard_pocket() -> Dictionary:
	if _fantasy.claim.pockets.is_empty():
		return {}
	return _fantasy.claim.pockets[_fantasy.claim.pockets.size() - 1]


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
