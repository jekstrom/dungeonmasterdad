extends Node

var _level: Node
var _reality: RealityZone
var _fantasy: FantasyZone
var _interior := Rect2i(0, 0, 16, 10)
var _dungeon := Rect2i(8, 2, 8, 6)


func _ready() -> void:
	if not await _run_suite():
		return
	print("US-053 Grounded test passed")
	get_tree().quit(0)


func _run_suite() -> bool:
	DmUnlocks.reset_unlocks()
	DmManager.clear_grounded_timers()
	if DmUnlocks.is_owned("grounded"):
		return _fail("US-053 AC1: grounded must start unowned")
	if not _assert_tooltip():
		return false
	if not await _setup_map():
		return false
	var inside: Vector2 = DungeonGrid.to_world_center(_dungeon.position + Vector2i(2, 2))
	var outside: Vector2 = DungeonGrid.to_world_center(Vector2i(2, 4))
	if not _fantasy.is_claimed_world(inside):
		return _fail("US-053: dungeon cell must be Fantasy-claimed")
	if _fantasy.is_claimed_world(outside):
		return _fail("US-053: west cell must not be Fantasy-claimed")

	var paper: Player = _make_paper_pusher()
	if paper == null:
		return _fail("US-053: failed to instantiate Player")
	paper.name = "2"
	add_child(paper)
	paper.global_position = inside
	paper.max_hp = 6
	paper.hitpoints = 6
	await get_tree().process_frame
	if DmManager.apply_grounded_tick(3.0) != 0:
		return _fail("US-053 AC1: unowned Fantasy time must not kill")
	if paper.hitpoints != 6:
		return _fail("US-053 AC1: unowned HP changed %d" % paper.hitpoints)
	if not _assert_countdown(paper, false):
		return false

	DmUnlocks.unlock("grounded")
	if not DmUnlocks.is_owned("grounded"):
		return _fail("US-053 FR-001: force-own grounded must stick")
	DmManager.clear_grounded_timers()
	if DmManager.apply_grounded_tick(2.9) != 0:
		return _fail("US-053 AC2: 2.9s in Fantasy must not kill")
	if paper.hitpoints != 6:
		return _fail("US-053 AC2: HP before 3s want 6 got %d" % paper.hitpoints)
	if DmManager.grounded_elapsed_for(2) < 2.89:
		return _fail("US-053 AC2: timer must accumulate in Fantasy")
	if not _assert_countdown(paper, true):
		return false
	if paper.grounded_remaining > 0.15:
		return _fail("US-053 AC2: countdown remaining want ~0.1 got %s" % paper.grounded_remaining)
	if DmManager.apply_grounded_tick(0.2) < 1:
		return _fail("US-053 AC2: 3s continuous Fantasy must kill")
	if paper.hitpoints > 0:
		return _fail("US-053 AC2: PP must die after 3s in Fantasy, hp %d" % paper.hitpoints)

	paper.hitpoints = 6
	paper.global_position = inside
	DmManager.clear_grounded_timers()
	if DmManager.apply_grounded_tick(2.0) != 0:
		return _fail("US-053: partial timer must not kill")
	paper.global_position = outside
	await get_tree().process_frame
	if DmManager.apply_grounded_tick(0.1) != 0:
		return _fail("US-053: leaving Fantasy must not kill")
	if DmManager.grounded_elapsed_for(2) != 0.0:
		return _fail("US-053: timer must reset when leaving Fantasy")
	if not _assert_countdown(paper, false):
		return false
	paper.global_position = inside
	await get_tree().process_frame
	if DmManager.apply_grounded_tick(2.9) != 0:
		return _fail("US-053: re-entry must require a full 3s")
	if paper.hitpoints != 6:
		return _fail("US-053: re-entry HP changed early")

	DmUnlocks.lock("grounded")
	if DmUnlocks.is_owned("grounded"):
		return _fail("US-053 AC3: lock must clear grounded")
	if DmManager.apply_grounded_tick(3.0) != 0:
		return _fail("US-053 AC3: lock must stop Fantasy kill")
	if paper.hitpoints != 6:
		return _fail("US-053 AC3: lock must leave HP at 6")
	paper.queue_free()
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
		return _fail("US-053: failed to instantiate zones")
	return true


func _assert_countdown(paper: Player, want_visible: bool) -> bool:
	var hud: Node2D = paper.get_node_or_null("GroundedCountdown") as Node2D
	if hud == null:
		return _fail("US-053: GroundedCountdown missing above Paper Pusher")
	hud._process(0.0)
	if hud.visible != want_visible:
		return _fail("US-053: countdown visible=%s want %s" % [hud.visible, want_visible])
	var skull: Sprite2D = hud.get_node_or_null("Skull") as Sprite2D
	if skull == null or skull.texture == null:
		return _fail("US-053: pulsing skull sprite missing")
	if want_visible and (skull.texture.resource_path.find("grounded_skull") == -1):
		return _fail("US-053: skull must use grounded_skull.png")
	var fill: ColorRect = hud.get_node_or_null("BarFill") as ColorRect
	if want_visible and (fill == null or fill.size.x <= 0.0):
		return _fail("US-053: countdown bar must show remaining fill")
	return true


func _assert_tooltip() -> bool:
	var tree_script: Script = load("res://gui/dm/skill_tree.gd") as Script
	if tree_script == null:
		return _fail("US-053 AC5: skill_tree.gd missing")
	for entry in tree_script.DAD_PASSIVES:
		if str(entry.get("id", "")) != "grounded":
			continue
		if str(entry.get("effect", "")) != "Paper Pushers can only survive in Fantasy for 3 seconds.":
			return _fail("US-053 AC5: tooltip must stay US-035 copy")
		return true
	return _fail("US-053 AC5: grounded missing from Dad passives")


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
