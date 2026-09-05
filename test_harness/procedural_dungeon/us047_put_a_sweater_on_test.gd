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
	print("US-047 Put a Sweater On test passed")
	get_tree().quit(0)


func _run_suite() -> bool:
	DmManager.clear_blizzard_effects()
	DmUnlocks.reset_unlocks()
	DmManager.fantasy_level = 0
	if DmUnlocks.is_owned("put_a_sweater_on"):
		return _fail("US-047 AC1: put_a_sweater_on must start unowned")
	if not await _setup_map():
		return false
	if not await _assert_blizzard_damage_owned_only():
		return false
	if not _assert_f9_grants_sp():
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
		return _fail("US-047: failed to instantiate zones")
	return true


func _assert_blizzard_damage_owned_only() -> bool:
	DmUnlocks.reset_unlocks()
	DmUnlocks.dm_unlocks[Catalog.BEMIDJI_BLIZZARD] = true
	DmManager.clear_blizzard_effects()
	DmManager.set_mana(100)
	var origin: Vector2i = _pocket_origin()
	if not DmManager.launch_blizzard(_spell_at(origin)):
		return _fail("US-047: launch_blizzard must succeed")
	var inside: Vector2 = DungeonGrid.to_world_center(origin + Vector2i(1, 1))
	var outside: Vector2 = DungeonGrid.to_world_center(origin + Vector2i(8, 0))
	var paper: Player = _make_paper_pusher()
	if paper == null:
		return _fail("US-047: failed to instantiate Player")
	add_child(paper)
	paper.global_position = inside
	await get_tree().process_frame
	var hp_before: int = paper.hitpoints
	if DmManager.apply_blizzard_sweater_damage() != 0:
		return _fail("US-047 AC1: unowned blizzard must not damage")
	if paper.hitpoints != hp_before:
		return _fail("US-047 AC1: unowned HP changed %d -> %d" % [hp_before, paper.hitpoints])

	DmUnlocks.unlock("put_a_sweater_on")
	if not DmUnlocks.is_owned("put_a_sweater_on"):
		return _fail("US-047 FR-001: force-own put_a_sweater_on must stick")
	if DmManager.apply_blizzard_sweater_damage() < 1:
		return _fail("US-047 AC2: owned blizzard must damage PP inside")
	if paper.hitpoints != hp_before - DmManager.BLIZZARD_SWEATER_DAMAGE:
		return _fail("US-047 AC2: inside HP want %d got %d" % [hp_before - 1, paper.hitpoints])

	var hp_inside: int = paper.hitpoints
	paper.global_position = outside
	await get_tree().process_frame
	if DmManager.apply_blizzard_sweater_damage() != 0:
		return _fail("US-047 AC2: owned blizzard must not damage PP outside")
	if paper.hitpoints != hp_inside:
		return _fail("US-047 AC2: outside HP changed")

	DmUnlocks.lock("put_a_sweater_on")
	paper.global_position = inside
	await get_tree().process_frame
	if DmManager.apply_blizzard_sweater_damage() != 0:
		return _fail("US-047 AC3: lock must stop blizzard damage")
	paper.queue_free()
	return true


func _assert_f9_grants_sp() -> bool:
	if not InputMap.has_action("debug_skill_cheat"):
		return _fail("US-047: debug_skill_cheat action missing")
	var has_f9 := false
	for ev in InputMap.action_get_events("debug_skill_cheat"):
		if not (ev is InputEventKey):
			continue
		var key: InputEventKey = ev
		if key.keycode == KEY_F9 or key.physical_keycode == KEY_F9:
			has_f9 = true
			break
	if not has_f9:
		return _fail("US-047: debug_skill_cheat must bind F9")
	var before: int = DmManager.skill_points
	DmManager.debug_open_skills_and_grant_sp(100)
	if DmManager.skill_points != before + 100:
		return _fail("US-047: F9 grant must add 100 SP, got %d" % DmManager.skill_points)
	if DmHud and DmHud.has_method("open_skill_tree_hud"):
		if DmHud.skill_tree and not DmHud.skill_tree.visible:
			return _fail("US-047: debug open must show the skill tree")
	return true


func _spell_at(origin: Vector2i) -> Dictionary:
	return {
		"target": DungeonGrid.to_world_center(origin + Vector2i(1, 1)),
		"origin": origin,
		"size": POCKET_SIZE,
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


func _make_paper_pusher() -> Player:
	var packed: PackedScene = load("res://player/player.tscn") as PackedScene
	if packed == null:
		return null
	var node: Node = packed.instantiate()
	if node is Player:
		return node as Player
	return null


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
