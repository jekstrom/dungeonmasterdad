extends Node

## US-017 T003: host Baja Blast wander, attack, blast, and die.
## user_stories/tasks/US-017/T003-host-boss-combat.md
## Blast is Baja spit, not Bemidji Blizzard. Die does not unlock.

const BOSS_SCENE := "res://monsters/baja_boss.tscn"
const ENTRANCE := Vector2i(2, 2)
const EXIT_CELL := Vector2i(16, 16)

func _ready() -> void:
	if not await _assert_boss_combat():
		return
	if not _assert_spawn_contract():
		return
	print("US-017 T003 boss combat test passed")
	get_tree().quit(0)


func _assert_boss_combat() -> bool:
	var packed: PackedScene = load(BOSS_SCENE) as PackedScene
	if packed == null:
		_fail("US-017 T003: failed to load baja_boss.tscn")
		return false
	var boss: Node = packed.instantiate()
	if boss == null:
		_fail("US-017 T003: failed to instantiate baja_boss.tscn")
		return false
	add_child(boss)
	await get_tree().process_frame
	await get_tree().process_frame
	if not multiplayer.is_server():
		_fail("US-017 T003: offline peer must be server so SM initializes")
		return false
	var sm: Node = boss.get_node_or_null("EnemyStateMachine")
	if sm == null:
		_fail("US-017 T003: EnemyStateMachine missing")
		return false
	var current: Node = sm.get("current_state")
	if current == null:
		_fail("US-017 T003: host SM current_state is null after init")
		return false
	var state_name := str(current.name)
	if state_name != "idle" and state_name != "wander":
		_fail("US-017 T003: expected idle or wander, got %s" % state_name)
		return false
	var player: AnimationPlayer = boss.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player == null:
		_fail("US-017 T003: AnimationPlayer missing")
		return false
	var attack: Node = sm.get_node_or_null("attack")
	if attack == null:
		_fail("US-017 T003: attack state node missing")
		return false
	sm.call("change_state", attack)
	await get_tree().process_frame
	var anim := str(player.current_animation)
	if not anim.begins_with("attack_"):
		_fail("US-017 T003: expected attack_* clip, got %s" % anim)
		return false
	if anim.find("blizzard") != -1 or anim.find("fireball") != -1:
		_fail("US-017 T003: attack must not play blizzard/fireball, got %s" % anim)
		return false
	var blast: Node = sm.get_node_or_null("blast")
	if blast == null:
		_fail("US-017 T003: blast state node missing")
		return false
	sm.call("change_state", blast)
	await get_tree().process_frame
	anim = str(player.current_animation)
	if not anim.begins_with("blast_"):
		_fail("US-017 T003: expected blast_* clip, got %s" % anim)
		return false
	if anim.find("blizzard") != -1 or anim.find("fireball") != -1:
		_fail("US-017 T003: blast is Baja spit, not blizzard/fireball, got %s" % anim)
		return false
	if int(boss.get("hp")) != 12:
		_fail("US-017 T003: host hp should still be 12 before die, got %s" % boss.get("hp"))
		return false
	boss.set("hp", 0)
	boss.call("die")
	await get_tree().process_frame
	if not bool(boss.get("_dying")):
		_fail("US-017 T003: die() must set _dying on the host")
		return false
	if sm.process_mode != Node.PROCESS_MODE_DISABLED:
		_fail("US-017 T003: SM must be disabled after die")
		return false
	anim = str(player.current_animation)
	if not anim.begins_with("die_"):
		_fail("US-017 T003: expected die_* clip after die(), got %s" % anim)
		return false
	sm.call("change_state", attack)
	await get_tree().process_frame
	anim = str(player.current_animation)
	if anim.begins_with("attack_"):
		_fail("US-017 T003: must not re-enter attack after _dying")
		return false
	var hurtbox: Node = boss.get_node_or_null("Hurtbox")
	if hurtbox == null:
		_fail("US-017 T003: Hurtbox missing")
		return false
	return true


func _assert_spawn_contract() -> bool:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager == null or not manager.has_method("generate_dungeon_contract"):
		return true
	var response: Dictionary = manager.generate_dungeon_contract({
		"requestId": "us017-boss-combat",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 16, "y": 16},
		"generationBounds": {"origin": {"x": 0, "y": 0}, "size": {"x": 24, "y": 24}},
		"roomCount": 4
	}, 1)
	if not response.get("ok", false):
		_fail("US-017 T003: generation failed %s" % response)
		return false
	var bosses: Array = []
	for spawn in response.get("data", {}).get("monsterSpawns", []):
		if str(spawn.get("monsterTypeId", "")) == "baja_boss":
			bosses.append(spawn)
	if bosses.size() != 1:
		_fail("US-017 T003: expected exactly one baja_boss, got %d" % bosses.size())
		return false
	var skip_response: Dictionary = manager.generate_dungeon_contract({
		"requestId": "us017-boss-combat-skip",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 16, "y": 16},
		"generationBounds": {"origin": {"x": 0, "y": 0}, "size": {"x": 24, "y": 24}},
		"roomCount": 4,
		"skipBoss": true
	}, 1)
	if not skip_response.get("ok", false):
		_fail("US-017 T003: skipBoss generation failed %s" % skip_response)
		return false
	var skip_bosses := 0
	for spawn in skip_response.get("data", {}).get("monsterSpawns", []):
		if str(spawn.get("monsterTypeId", "")) == "baja_boss":
			skip_bosses += 1
	if skip_bosses != 0:
		_fail("US-017 T003: skipBoss must yield zero baja_boss")
		return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
