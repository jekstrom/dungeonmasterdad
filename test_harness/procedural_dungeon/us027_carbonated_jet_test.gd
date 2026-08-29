extends Node

## US-027 T001/T002/T003/T004 Carbonated Jet harness.
## user_stories/tasks/US-027/T001-jet-telegraph.md
## user_stories/tasks/US-027/T002-piercing-stream.md
## user_stories/tasks/US-027/T003-replicate-jet.md
## user_stories/tasks/US-027/T004-verification-harness.md
## Play pass (QA owns two-window): readable arm-point tell, neon stream, DM can be hit,
## peer matches, distinct from blast spit. This harness does not claim the play pass ran.

const BOSS_SCENE := preload("res://monsters/baja_boss.tscn")
const JET_SCENE := preload("res://monsters/carbonated_jet.tscn")
const DM_SCENE := preload("res://dm/dm.tscn")
const JET_STATE_SCRIPT := preload("res://monsters/baja_boss_jet.gd")
const JET_PROJ_SCRIPT := preload("res://monsters/carbonated_jet.gd")
const TICK := 1.0 / 60.0
const HOME := Vector2i(8, 8)


func _ready() -> void:
	DmUnlocks.reset_unlocks()
	if not await _run():
		return
	print("US-027 T001/T002/T003/T004 carbonated jet test passed")
	print("US-027 two-window play pass not run (QA owns it): readable arm-point tell, neon stream, DM can be hit, peer matches, distinct from blast spit.")
	get_tree().quit(0)


func _run() -> bool:
	if not multiplayer.is_server():
		_fail("US-027: offline peer must be server so SM initializes")
		return false
	_setup_spawner()
	await get_tree().process_frame
	if not _assert_scenes_distinct():
		return false
	if not await _assert_telegraph_then_stream_and_hit():
		return false
	if not await _assert_death_cancels_tell():
		return false
	if not await _assert_blast_removed():
		return false
	if not _assert_isolation():
		return false
	if not _assert_replicate_contract():
		return false
	return true


func _setup_spawner() -> void:
	var projectiles := Node2D.new()
	projectiles.name = "Projectiles"
	add_child(projectiles)
	var spawner := MultiplayerSpawner.new()
	spawner.set_script(load("res://scripts/projectile_spawner.gd"))
	spawner.name = "ProjectileSpawner"
	spawner.spawn_path = NodePath("..")
	spawner.set("projectile_scene", load("res://spells/fireball/fireball_spell.tscn"))
	projectiles.add_child(spawner)


func _make_boss() -> Node2D:
	var boss: Node2D = BOSS_SCENE.instantiate() as Node2D
	boss.set("grant_blizzard_on_death", false)
	boss.global_position = DungeonGrid.to_world_center(HOME)
	add_child(boss)
	boss.collision_layer = 0
	boss.collision_mask = 0
	return boss


func _make_stub_dm(world_pos: Vector2) -> Node2D:
	var dm: Node2D = DM_SCENE.instantiate() as Node2D
	dm.name = "StubDM"
	dm.global_position = world_pos
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
	return dm


func _jet_count() -> int:
	var n: int = 0
	var tree := get_tree()
	if tree == null:
		return 0
	for node in tree.get_nodes_in_group("carbonated_jets"):
		if is_instance_valid(node):
			n += 1
	return n


func _disable_sm(boss: Node) -> Node:
	var sm: Node = boss.get_node_or_null("EnemyStateMachine")
	if sm:
		sm.process_mode = Node.PROCESS_MODE_DISABLED
	return sm


func _tell_visible(boss: Node) -> bool:
	if bool(boss.get("jet_telling")):
		return true
	if boss.has_method("is_showing_jet_tell") and bool(boss.call("is_showing_jet_tell")):
		return true
	var player: AnimationPlayer = boss.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player and str(player.current_animation).begins_with("jet_tell_"):
		return true
	return false


func _assert_scenes_distinct() -> bool:
	var sample: Node = JET_SCENE.instantiate()
	if sample == null:
		_fail("US-027: carbonated_jet.tscn failed to instantiate")
		return false
	var jet_script: Script = sample.get_script()
	var jet_path := ""
	if jet_script:
		jet_path = str(jet_script.resource_path)
	sample.free()
	if jet_path.ends_with("baja_boss_blast.gd"):
		_fail("US-027: jet projectile must not use baja_boss_blast.gd")
		return false
	if jet_path.find("freeze") != -1 or jet_path.find("blizzard") != -1:
		_fail("US-027: jet projectile must not be Freeze Wave")
		return false
	if not jet_path.ends_with("carbonated_jet.gd"):
		_fail("US-027: jet projectile script should be carbonated_jet.gd, got %s" % jet_path)
		return false
	return true


func _assert_jet_art(stream: Node) -> bool:
	var head: Sprite2D = stream.get_node_or_null("Head") as Sprite2D
	var body: Sprite2D = stream.get_node_or_null("Body") as Sprite2D
	if head == null or body == null:
		_fail("US-027 T002: carbonated_jet needs Head/Body Sprite2D from baja_jet.png")
		return false
	var head_tex := ""
	if head.texture:
		head_tex = str(head.texture.resource_path)
	var body_tex := ""
	if body.texture:
		body_tex = str(body.texture.resource_path)
	if not head_tex.ends_with("baja_jet.png"):
		_fail("US-027 T002: Head must use sprites/baja_jet.png, got %s" % head_tex)
		return false
	if not body_tex.ends_with("baja_jet.png"):
		_fail("US-027 T002: Body must use sprites/baja_jet.png, got %s" % body_tex)
		return false
	if int(head.frame) != 0:
		_fail("US-027 T002: Head must be cell 0 (tip), frame=%s" % head.frame)
		return false
	var body_ok := int(body.frame) == 1
	if body.has_meta("jet_cell") and int(body.get_meta("jet_cell")) == 1:
		body_ok = true
	if body.region_enabled:
		var rx: float = body.region_rect.position.x
		if rx >= 128.0 - 12.0 and rx < 256.0:
			body_ok = true
	if not body_ok:
		_fail("US-027 T002: Body must be cell 1 (12px wrap), frame=%s region=%s" % [body.frame, body.region_rect])
		return false
	if stream.get_node_or_null("Neon") != null:
		_fail("US-027 T002: do not use a ColorRect/Polygon2D placeholder for the syrup")
		return false
	return true


func _assert_telegraph_then_stream_and_hit() -> bool:
	var boss: Node2D = _make_boss()
	var dm_pos: Vector2 = boss.global_position + Vector2(400, 0)
	var dm: Node2D = _make_stub_dm(dm_pos)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	if bool(boss.get("grant_blizzard_on_death")):
		_fail("US-027: grant_blizzard_on_death must be false")
		return false
	var sm: Node = _disable_sm(boss)
	if sm == null:
		_fail("US-027: EnemyStateMachine missing")
		return false
	var jet_state: Node = sm.get_node_or_null("jet")
	if jet_state == null:
		_fail("US-027: jet state node missing under EnemyStateMachine")
		return false
	var jet_script: Script = jet_state.get_script()
	if jet_script == null or str(jet_script.resource_path).ends_with("baja_boss_blast.gd"):
		_fail("US-027: jet state must not point at baja_boss_blast.gd")
		return false
	if not str(jet_script.resource_path).ends_with("baja_boss_jet.gd"):
		_fail("US-027: jet state script should be baja_boss_jet.gd")
		return false
	var before: int = _jet_count()
	sm.call("change_state", jet_state)
	await get_tree().process_frame
	if boss.get_node_or_null("JetTell") != null:
		_fail("US-027 T001: jet telegraph must not spawn a Line2D laser")
		return false
	if not _tell_visible(boss):
		_fail("US-027 T001: jet_tell_* charge must play before any stream exists")
		return false
	var player: AnimationPlayer = boss.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player == null:
		_fail("US-027 T001: AnimationPlayer missing")
		return false
	var anim := str(player.current_animation)
	if not anim.begins_with("jet_tell_"):
		_fail("US-027 T001: expected jet_tell_* charging tell, got %s" % anim)
		return false
	if _jet_count() != before:
		_fail("US-027 T001: stream must not exist on the tell frame")
		return false
	await get_tree().create_timer(0.2).timeout
	if _jet_count() != before:
		_fail("US-027 T001: stream must not exist ~0.2s into the tell")
		return false
	if not _tell_visible(boss):
		_fail("US-027 T001: jet_tell_* must stay playing during the charge")
		return false
	var tell_sec: float = float(jet_state.get("telegraph_sec"))
	if tell_sec < 0.9 or tell_sec > 1.1:
		_fail("US-027 T001: telegraph_sec should be 1s charge, got %s" % tell_sec)
		return false
	var recover_sec: float = float(jet_state.get("recover_sec"))
	if recover_sec < 0.9 or recover_sec > 1.1:
		_fail("US-027 T001: recover_sec should be 1s idle, got %s" % recover_sec)
		return false
	if (boss as CharacterBody2D).velocity != Vector2.ZERO:
		_fail("US-027 T001: boss must stay planted during jet charge")
		return false
	if jet_state.has_method("process"):
		jet_state.call("process", tell_sec)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	if _jet_count() <= before:
		_fail("US-027 T002: stream must exist after the telegraph completes")
		return false
	anim = str(player.current_animation)
	if not anim.begins_with("idle_"):
		_fail("US-027 T002: after the beam fires, boss must play idle_*, got %s" % anim)
		return false
	if sm.get("current_state") != jet_state:
		_fail("US-027 T001: boss must stay in jet through idle recover")
		return false
	if (boss as CharacterBody2D).velocity != Vector2.ZERO:
		_fail("US-027 T001: boss must stay planted during jet recover")
		return false
	if jet_state.has_method("process"):
		jet_state.call("process", recover_sec * 0.5)
	await get_tree().process_frame
	if sm.get("current_state") != jet_state:
		_fail("US-027 T001: recover must last the full 1s idle, not leave jet early")
		return false
	var stream: Node2D = null
	for node in get_tree().get_nodes_in_group("carbonated_jets"):
		if is_instance_valid(node) and node is Node2D:
			stream = node as Node2D
			break
	if stream == null:
		_fail("US-027 T002: carbonated_jets group empty after fire")
		return false
	if int(stream.get("damage")) != 20:
		_fail("US-027 T002: jet damage must be 20, got %s" % stream.get("damage"))
		return false
	var spd: float = float(stream.get("speed"))
	if spd < 600.0:
		_fail("US-027 T002: stream speed must be high-velocity (>=600), got %s" % spd)
		return false
	var stream_dir: Vector2 = stream.get("direction")
	if stream_dir.length() < 0.001:
		_fail("US-027 T002: stream direction missing")
		return false
	stream_dir = stream_dir.normalized()
	var expected: Vector2 = Vector2.RIGHT
	var locked: Variant = jet_state.get("_aim")
	if locked is Vector2 and (locked as Vector2).length() > 0.001:
		expected = (locked as Vector2).normalized()
	if stream_dir.dot(expected) < 0.9:
		_fail("US-027 T002: stream direction must follow the tell, got %s expected %s" % [stream_dir, expected])
		return false
	if not _assert_jet_art(stream):
		return false
	var stream_script: Script = stream.get_script()
	if stream_script == null or str(stream_script.resource_path).ends_with("baja_boss_blast.gd"):
		_fail("US-027 T002: live stream must not be baja_boss_blast.gd")
		return false
	DmManager.fantasy_level = 10
	var fantasy_before: int = int(DmManager.fantasy_level)
	var dummy_pos: Vector2 = dm.global_position
	var hit: bool = false
	var past: bool = false
	for _i in 90:
		await get_tree().physics_frame
		if stream.has_method("_physics_process"):
			stream.call("_physics_process", TICK)
		if not is_instance_valid(stream):
			_fail("US-027 T002: piercing stream must stay alive after overlapping the dummy")
			return false
		if int(DmManager.fantasy_level) < fantasy_before:
			hit = true
		if hit and stream.global_position.distance_to(dummy_pos) > 24.0:
			var away: Vector2 = stream.global_position - dummy_pos
			if away.length() > 0.001 and stream_dir.dot(away.normalized()) > 0.0:
				past = true
				break
	if not hit:
		var hitbox: Node = dm.get_node_or_null("Hitbox")
		if hitbox and stream.has_method("_area_entered"):
			stream.call("_area_entered", hitbox)
		await get_tree().process_frame
		if int(DmManager.fantasy_level) < fantasy_before:
			hit = true
	if not hit:
		_fail("US-027 T002: host must apply_fantasy_hit when the stream overlaps the DM")
		return false
	if not is_instance_valid(stream):
		_fail("US-027 T002: piercing stream must not consume on the first target")
		return false
	if not past:
		for _j in 20:
			await get_tree().physics_frame
			if stream.has_method("_physics_process"):
				stream.call("_physics_process", TICK)
			if not is_instance_valid(stream):
				_fail("US-027 T002: piercing stream vanished before passing the dummy")
				return false
			var away2: Vector2 = stream.global_position - dummy_pos
			if away2.length() > 16.0 and stream_dir.dot(away2.normalized()) > 0.0:
				past = true
				break
	if not past:
		_fail("US-027 T002: piercing stream must keep moving past the dummy after the hit")
		return false
	dm.queue_free()
	boss.queue_free()
	if is_instance_valid(stream):
		stream.queue_free()
	await get_tree().process_frame
	return true


func _assert_death_cancels_tell() -> bool:
	var boss: Node2D = _make_boss()
	var dm: Node2D = _make_stub_dm(boss.global_position + Vector2(400, 0))
	await get_tree().process_frame
	await get_tree().physics_frame
	var sm: Node = _disable_sm(boss)
	var jet_state: Node = sm.get_node_or_null("jet") if sm else null
	if jet_state == null:
		_fail("US-027 T001: jet state missing for death-during-tell")
		return false
	sm.call("change_state", jet_state)
	await get_tree().process_frame
	if not _tell_visible(boss):
		_fail("US-027 T001: jet_tell_* should be playing before death cancel")
		return false
	var before: int = _jet_count()
	boss.set("grant_blizzard_on_death", false)
	boss.call("die")
	await get_tree().process_frame
	var tell_sec: float = float(jet_state.get("telegraph_sec"))
	if jet_state.has_method("process"):
		jet_state.call("process", tell_sec + 0.1)
	await get_tree().create_timer(0.2).timeout
	if _jet_count() != before:
		_fail("US-027 T001: dying during the tell must not fire a carbonated_jet")
		return false
	if bool(DmUnlocks.dm_unlocks.get("bemidji_blizzard", false)):
		_fail("US-027: death-during-tell must not unlock bemidji_blizzard")
		return false
	dm.queue_free()
	boss.queue_free()
	await get_tree().process_frame
	return true


func _assert_blast_removed() -> bool:
	var boss: Node2D = _make_boss()
	await get_tree().process_frame
	var sm: Node = _disable_sm(boss)
	if sm == null:
		_fail("US-027: SM missing")
		return false
	if sm.get_node_or_null("blast") != null:
		_fail("US-027: blast state must be removed; jet is the special attack")
		return false
	var player: AnimationPlayer = boss.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player:
		for clip in ["blast_down", "blast_up", "blast_side"]:
			if player.has_animation(clip):
				_fail("US-027: leftover %s clip; use jet_* instead" % clip)
				return false
	if boss.has_method("apply_blast_hit"):
		_fail("US-027: apply_blast_hit must be gone with the spit")
		return false
	boss.queue_free()
	await get_tree().process_frame
	return true


func _assert_isolation() -> bool:
	if bool(DmUnlocks.dm_unlocks.get("bemidji_blizzard", false)):
		_fail("US-027: must not unlock bemidji_blizzard")
		return false
	if bool(DmUnlocks.dm_unlocks.get("fireball", false)):
		_fail("US-027: must not unlock fireball")
		return false
	if DmManager.has_method("live_blizzard_count") and int(DmManager.call("live_blizzard_count")) != 0:
		_fail("US-027: must not plant a Fantasy / blizzard pocket")
		return false
	return true


func _assert_replicate_contract() -> bool:
	var src := FileAccess.get_file_as_string("res://monsters/carbonated_jet.gd")
	if src.find("multiplayer.is_server()") == -1:
		_fail("US-027 T003: stream hits must be host-guarded")
		return false
	var boss_src := FileAccess.get_file_as_string("res://monsters/baja_boss.gd")
	if boss_src.find("Line2D") != -1 or boss_src.find("JetTell") != -1:
		_fail("US-027 T001: jet telegraph must not draw a Line2D laser")
		return false
	if boss_src.find("fire_carbonated_jet") == -1 or boss_src.find("multiplayer.is_server()") == -1:
		_fail("US-027 T003: jet fire must be host-guarded")
		return false
	var boss_sample: Node = BOSS_SCENE.instantiate()
	var boss_sync: MultiplayerSynchronizer = boss_sample.get_node_or_null("MultiplayerSynchronizer") as MultiplayerSynchronizer
	if boss_sync == null or boss_sync.replication_config == null:
		_fail("US-027 T003: baja_boss needs MultiplayerSynchronizer so peers see jet_tell_*")
		boss_sample.free()
		return false
	var boss_cfg: SceneReplicationConfig = boss_sync.replication_config
	if not boss_cfg.has_property(NodePath("AnimationPlayer:current_animation")):
		_fail("US-027 T003: replicate AnimationPlayer:current_animation for the jet pose")
		boss_sample.free()
		return false
	boss_sample.free()
	var sample: Node = JET_SCENE.instantiate()
	var sync: MultiplayerSynchronizer = sample.get_node_or_null("MultiplayerSynchronizer") as MultiplayerSynchronizer
	if sync == null or sync.replication_config == null:
		_fail("US-027 T003: carbonated_jet needs MultiplayerSynchronizer for position+rotation")
		sample.free()
		return false
	var cfg: SceneReplicationConfig = sync.replication_config
	if not cfg.has_property(NodePath(".:position")) or not cfg.has_property(NodePath(".:rotation")):
		_fail("US-027 T003: replicate position and rotation only")
		sample.free()
		return false
	if cfg.has_property(NodePath("Sprite2D:frame")) or cfg.has_property(NodePath("Sprite2D:texture")):
		_fail("US-027 T003: do not replicate Sprite2D:frame/texture (US-005 flicker)")
		sample.free()
		return false
	sample.free()
	var spawner_src := FileAccess.get_file_as_string("res://scripts/projectile_spawner.gd")
	if spawner_src.find("carbonated_jet") == -1 or spawner_src.find("spawn_carbonated_jet") == -1:
		_fail("US-027 T002: projectile_spawner must spawn carbonated_jet without breaking staple/fireball")
		return false
	if spawner_src.find("staple") == -1:
		_fail("US-027: staple _custom_spawn branch must remain")
		return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
