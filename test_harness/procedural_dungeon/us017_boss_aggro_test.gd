extends Node

## US-017 T003 aggro: Baja Blast approaches and attacks the DM.
## user_stories/tasks/US-017/T003-host-boss-combat.md
## Blast is Baja spit, not Bemidji Blizzard. Do not unlock (T004).

const BOSS_SCENE := preload("res://monsters/baja_boss.tscn")
const DM_SCENE := preload("res://dm/dm.tscn")
const HOME := Vector2i(8, 8)
const DM_OFFSET_CELLS := 6
const CHASE_TICKS := 120
const MELEE_TICKS := 20
const TICK := 1.0 / 60.0


func _ready() -> void:
	DmUnlocks.reset_unlocks()
	if not await _assert_chase_and_melee():
		return
	print("US-017 T003 boss aggro test passed")
	get_tree().quit(0)


func _tick_boss(boss: Node, ticks: int) -> void:
	var sm: Node = boss.get_node_or_null("EnemyStateMachine")
	for _i in ticks:
		if sm:
			sm._process(TICK)
			sm._physics_process(TICK)
		if boss.has_method("_physics_process"):
			boss._physics_process(TICK)


func _assert_chase_and_melee() -> bool:
	if not multiplayer.is_server():
		_fail("US-017 T003: offline peer must be server so SM initializes")
		return false

	var boss: Node2D = BOSS_SCENE.instantiate() as Node2D
	if boss == null:
		_fail("US-017 T003: failed to instantiate baja_boss.tscn")
		return false
	boss.set("grant_blizzard_on_death", false)
	boss.global_position = DungeonGrid.to_world_center(HOME)
	add_child(boss)
	boss.collision_layer = 0
	boss.collision_mask = 0

	var dm: Node2D = DM_SCENE.instantiate() as Node2D
	if dm == null:
		_fail("US-017 T003: failed to instantiate dm.tscn")
		return false
	dm.name = "StubDM"
	dm.global_position = DungeonGrid.to_world_center(HOME + Vector2i(DM_OFFSET_CELLS, 0))
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
	await get_tree().physics_frame

	if boss.get("aggro_faction") != Enemy.AggroFaction.DM:
		_fail("US-017 T003: aggro_faction must be AggroFaction.DM")
		return false
	if not bool(boss.call("has_aggro_target")):
		_fail("US-017 T003: boss must aggro the DM stub several cells away")
		return false

	var start_pos: Vector2 = boss.global_position
	var start_dist: float = start_pos.distance_to(dm.global_position)
	var home_world: Vector2 = DungeonGrid.to_world_center(HOME)
	if start_dist < 400.0:
		_fail("US-017 T003: DM must start several cells away, dist=%s" % start_dist)
		return false

	_tick_boss(boss, CHASE_TICKS)
	await get_tree().process_frame

	var later_pos: Vector2 = boss.global_position
	var later_dist: float = later_pos.distance_to(dm.global_position)
	var boss_cell: Vector2i = DungeonGrid.from_world(later_pos)
	var home_cheby: int = DungeonGrid.chebyshev(boss_cell, HOME)
	if later_dist >= start_dist - 32.0:
		_fail("US-017 T003: boss must approach DM, dist %s -> %s pos %s -> %s" % [start_dist, later_dist, start_pos, later_pos])
		return false
	if home_cheby <= 2:
		_fail("US-017 T003: boss clamped at home chebyshev %s cell %s (start dist %s later %s)" % [home_cheby, boss_cell, start_dist, later_dist])
		return false
	if later_pos.distance_to(home_world) <= 256.0:
		_fail("US-017 T003: boss still on wander leash, dist_from_home %s" % later_pos.distance_to(home_world))
		return false

	boss.set("combat_cooldown", 0.0)
	dm.global_position = boss.global_position
	_tick_boss(boss, MELEE_TICKS)
	await get_tree().process_frame

	var anim := ""
	var state_name := ""
	var player: AnimationPlayer = boss.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player:
		anim = str(player.current_animation)
	var machine: Node = boss.get_node_or_null("EnemyStateMachine")
	if machine:
		var current: Node = machine.get("current_state")
		if current:
			state_name = str(current.name)
	if not anim.begins_with("attack_") and state_name != "attack":
		_fail("US-017 T003: melee overlap expected attack_* clip, got %s state=%s" % [anim, state_name])
		return false
	if anim.find("blizzard") != -1 or anim.find("fireball") != -1:
		_fail("US-017 T003: attack must not play blizzard/fireball, got %s" % anim)
		return false
	if bool(DmUnlocks.dm_unlocks.get("bemidji_blizzard", false)):
		_fail("US-017 T003: aggro path must not unlock bemidji_blizzard")
		return false
	if bool(boss.get("grant_blizzard_on_death")):
		_fail("US-017 T003: grant_blizzard_on_death must stay false")
		return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
