class_name BajaBoss extends Enemy

## US-017 T001/T002/T003/T004: Baja Blast boss at dungeon exit.
## Host HP, wander, attack, blast, and die. See user_stories/tasks/US-017/T003-host-boss-combat.md
## Host death unlocks bemidji_blizzard and drops the can. See user_stories/tasks/US-017/T004-death-unlock-can.md
## Cast pocket + slow is T005 — do not plant a pocket here.
## Sheet: monsters/baja_boss.png 384x640, 128x128 cells, hframes=3 vframes=5 (SHA 1ff8b3b).
## Col 0 South, col 1 North, col 2 East. Flip E for West via Enemy.SetDirection.
## Row 0 idle, 1 wander, 2 attack, 3 blast, 4 die. Frame index = row*3 + col.
## Do not use pickups/bajablast/bajablast.png. Do not stretch a goblin.
## Blast is a Baja-flavored spit, NOT Bemidji Blizzard (no fireball, no Fantasy pocket).
## US-027 Carbonated Jet is a NEW state (baja_boss_jet.gd). KEEP US-017 blast spit.
## NOT Freeze Wave, NOT Sugar Rush, NOT US-018 fireball, NOT Bemidji Blizzard pocket.

const FALLBACK_CLIP := "idle_down"
const WANDER_CHEBYSHEV := 2
const BLAST_CHEBYSHEV := 2
const BLAST_RANGE_PX := 256.0
const JET_RANGE_PX := 640.0
const JET_MAX_RANGE := 768.0
const JET_SPAWN_OFFSET := 48.0
const JET_TELL_WIDTH := 12.0
const JET_NEON := Color(0.1, 1.0, 0.75, 0.9)
const AGGRO_RANGE_PX := 1024.0
const COMBAT_COOLDOWN := 0.8
const JET_COOLDOWN := 3.0
const DIE_CLIP_SEC := 0.6
const PUFF_SEC := 0.65
const BAJA_CAN_ITEM := "res://pickups/bajablast/bajablast.tres"

var home_cell: Vector2i = Vector2i.ZERO
var combat_cooldown: float = 0.0
var jet_cooldown: float = JET_COOLDOWN  # opening CD so chase/melee/blast still happen first
var jet_telling: bool = false
var _home_cell_captured: bool = false
var _blizzard_rewards_granted: bool = false
var _jet_cancelled: bool = false
var _jet_tell: Line2D = null
@export var grant_blizzard_on_death: bool = true

func _init() -> void:
	max_hp = 12
	hp = 12
	aggro_faction = AggroFaction.DM


func _ready() -> void:
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2.ONE
		sprite.region_enabled = false
	_ensure_jet_state_node()
	super._ready()
	_capture_home_cell()
	_ensure_jet_tell()



func _ensure_jet_state_node() -> void:
	# Runtime-wire the jet state so a Godot editor with baja_boss.tscn open cannot
	# drop the node on save. SM.initialize() runs in Enemy._ready (super._ready).
	# user_stories/tasks/US-027/T001-jet-telegraph.md
	var sm := get_node_or_null("EnemyStateMachine")
	if sm == null:
		return
	var jet: Node = sm.get_node_or_null("jet")
	if jet == null:
		jet = Node.new()
		jet.name = "jet"
		var jet_script: Script = load("res://monsters/baja_boss_jet.gd") as Script
		if jet_script:
			jet.set_script(jet_script)
		sm.add_child(jet)
	var idle_n: Node = sm.get_node_or_null("idle")
	var wander_n: Node = sm.get_node_or_null("wander")
	var aggro_n: Node = sm.get_node_or_null("aggro")
	if jet.get("idle_state") == null and idle_n:
		jet.set("idle_state", idle_n)
	if jet.get("wander_state") == null and wander_n:
		jet.set("wander_state", wander_n)
	if jet.get("chase_state") == null and aggro_n:
		jet.set("chase_state", aggro_n)
	if aggro_n and aggro_n.get("jet_state") == null:
		aggro_n.set("jet_state", jet)


func _capture_home_cell() -> void:
	# Wander stays in the exit room: Chebyshev <= 2 of spawn cell.
	# user_stories/tasks/US-017/T003-host-boss-combat.md
	if _home_cell_captured:
		return
	home_cell = DungeonGrid.from_world(global_position)
	_home_cell_captured = true


func screen_spot_range() -> float:
	# Boss spots the DM several cells out (beyond jet 512px / Chebyshev 2).
	# user_stories/tasks/US-017/T003-host-boss-combat.md
	return maxf(super.screen_spot_range(), AGGRO_RANGE_PX)


func _physics_process(delta: float) -> void:
	combat_cooldown = maxf(0.0, combat_cooldown - delta)
	jet_cooldown = maxf(0.0, jet_cooldown - delta)
	super._physics_process(delta)
	if _dying:
		return
	if not multiplayer.is_server():
		return
	_clamp_wander_to_home()


func _clamp_wander_to_home() -> void:
	# Clamp only in idle/wander with no aggro target. Combat chase must leave home.
	# user_stories/tasks/US-017/T003-host-boss-combat.md
	if _dying:
		return
	if has_aggro_target():
		return
	_capture_home_cell()
	var cell: Vector2i = DungeonGrid.from_world(global_position)
	if DungeonGrid.chebyshev(cell, home_cell) <= WANDER_CHEBYSHEV:
		return
	var dx := clampi(cell.x - home_cell.x, -WANDER_CHEBYSHEV, WANDER_CHEBYSHEV)
	var dy := clampi(cell.y - home_cell.y, -WANDER_CHEBYSHEV, WANDER_CHEBYSHEV)
	global_position = DungeonGrid.to_world_center(home_cell + Vector2i(dx, dy))
	velocity = Vector2.ZERO


func ready_for_combat() -> bool:
	return (not _dying) and combat_cooldown <= 0.0


func in_blast_range_of(node: Node2D) -> bool:
	# US-027 Carbonated Jet range helper used by aggro. Distance <= 512px.
	# Out of this, chase. Melee still wins in melee range.
	# user_stories/tasks/US-017/T003-host-boss-combat.md
	if node == null or not is_instance_valid(node):
		return false
	var self_cell: Vector2i = DungeonGrid.from_world(global_position)
	var other_cell: Vector2i = DungeonGrid.from_world(node.global_position)
	if DungeonGrid.chebyshev(self_cell, other_cell) <= BLAST_CHEBYSHEV:
		return true
	return global_position.distance_to(node.global_position) <= BLAST_RANGE_PX


func in_blast_range_of_target(target: Node2D = null) -> bool:
	if target == null:
		target = aggro_target
	return in_blast_range_of(target)


func mark_combat_cooldown() -> void:
	combat_cooldown = COMBAT_COOLDOWN


func ready_for_jet() -> bool:
	return (not _dying) and (not _jet_cancelled) and jet_cooldown <= 0.0


func in_jet_range_of(node: Node2D) -> bool:
	# Carbonated Jet lane: farther than blast spit, ~512-640px.
	# user_stories/tasks/US-027/T001-jet-telegraph.md
	if node == null or not is_instance_valid(node):
		return false
	return global_position.distance_to(node.global_position) <= JET_RANGE_PX


func mark_jet_cooldown() -> void:
	jet_cooldown = JET_COOLDOWN


func _ensure_jet_tell() -> void:
	# Code-drawn floor tell so baja_boss.tscn stays small. Neon Baja teal, not ice.
	if _jet_tell != null and is_instance_valid(_jet_tell):
		return
	var existing := get_node_or_null("JetTell")
	if existing is Line2D:
		_jet_tell = existing as Line2D
		return
	_jet_tell = Line2D.new()
	_jet_tell.name = "JetTell"
	_jet_tell.width = JET_TELL_WIDTH
	_jet_tell.default_color = JET_NEON
	_jet_tell.z_index = 4
	_jet_tell.show_behind_parent = false
	_jet_tell.visible = false
	_jet_tell.joint_mode = Line2D.LINE_JOINT_ROUND
	_jet_tell.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_jet_tell.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(_jet_tell)


@rpc("authority", "call_local", "reliable")
func show_jet_tell(dir: Vector2) -> void:
	# Server-authored telegraph so peers see the same lane.
	# user_stories/tasks/US-027/T003-replicate-jet.md
	_ensure_jet_tell()
	if dir.length() < 0.001:
		dir = Vector2.RIGHT
	else:
		dir = dir.normalized()
	_jet_tell.clear_points()
	_jet_tell.add_point(Vector2.ZERO)
	_jet_tell.add_point(dir * JET_MAX_RANGE)
	_jet_tell.visible = true
	jet_telling = true


@rpc("authority", "call_local", "reliable")
func hide_jet_tell() -> void:
	jet_telling = false
	if _jet_tell and is_instance_valid(_jet_tell):
		_jet_tell.visible = false


func is_showing_jet_tell() -> bool:
	if jet_telling:
		return true
	_ensure_jet_tell()
	return _jet_tell != null and is_instance_valid(_jet_tell) and _jet_tell.visible


func _cancel_pending_jet() -> void:
	_jet_cancelled = true
	jet_telling = false
	if _jet_tell and is_instance_valid(_jet_tell):
		_jet_tell.visible = false


func fire_carbonated_jet(dir: Vector2) -> Node:
	# Host-only spawn of the piercing neon stream. Not blast spit.
	# user_stories/tasks/US-027/T002-piercing-stream.md
	if not multiplayer.is_server():
		return null
	if _dying or _jet_cancelled:
		return null
	hide_jet_tell.rpc()
	if dir.length() < 0.001:
		dir = Vector2.RIGHT
	else:
		dir = dir.normalized()
	var spawn_pos: Vector2 = global_position + dir * JET_SPAWN_OFFSET
	var data := {
		"kind": "carbonated_jet",
		"position": spawn_pos,
		"direction": dir,
		"damage": 1,
		"shooter_path": get_path(),
	}
	var tree := get_tree()
	if tree:
		for node in tree.get_nodes_in_group("projectile_spawner"):
			if node and node.has_method("spawn_carbonated_jet"):
				var spawned: Node = node.call("spawn_carbonated_jet", data)
				if spawned:
					if spawned.get("shooter") == null:
						spawned.set("shooter", self)
					if spawned is Node2D:
						(spawned as Node2D).global_position = spawn_pos
					return spawned
	# Fallback: instantiate locally so headless tests without playground still get a jet.
	var packed: PackedScene = load("res://monsters/carbonated_jet.tscn") as PackedScene
	if packed == null:
		return null
	var jet: Node = packed.instantiate()
	jet.set("direction", dir)
	jet.set("damage", 1)
	jet.set("speed", 900.0)
	jet.set("max_range", 768.0)
	jet.set("shooter_id", get_instance_id())
	jet.set("shooter", self)
	jet.set("shooter_path", get_path())
	var parent: Node = get_parent()
	if parent == null:
		parent = self
	parent.add_child(jet)
	if jet is Node2D:
		(jet as Node2D).global_position = spawn_pos
	return jet


func pulse_melee_hurtbox() -> void:
	# Goblin/skeleton pattern: monitoring false then true. Host SM only.
	# user_stories/tasks/US-017/T003-host-boss-combat.md
	_set_hurtbox_size(false)
	_set_hurtbox_monitoring(false)
	_set_hurtbox_monitoring(true)


func pulse_blast_hurtbox() -> void:
	# Larger pulse for Baja spit. Not blizzard, not US-018 fireball.
	_set_hurtbox_size(true)
	_set_hurtbox_monitoring(false)
	_set_hurtbox_monitoring(true)


func disable_hurtbox() -> void:
	_set_hurtbox_monitoring(false)
	_set_hurtbox_size(false)


func apply_blast_hit() -> void:
	# Short-range Baja spit: 1 damage if Chebyshev <= 2 or distance <= 256px.
	# user_stories/tasks/US-017/T003-host-boss-combat.md
	# US-027: KEEP this spit. Jet is a separate projectile.
	if not multiplayer.is_server() or _dying:
		return
	acquire_aggro_target()
	var target: Node2D = aggro_target
	if not in_blast_range_of(target):
		return
	if target.has_method("apply_fantasy_hit"):
		target.call("apply_fantasy_hit", 1)
	pulse_blast_hurtbox()




func _set_hurtbox_monitoring(enabled: bool) -> void:
	var hurtbox := get_node_or_null("Hurtbox")
	if hurtbox is Area2D:
		(hurtbox as Area2D).monitoring = enabled


func _set_hurtbox_size(large: bool) -> void:
	var hurtbox := get_node_or_null("Hurtbox")
	if hurtbox == null:
		return
	var shape_node := hurtbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or not (shape_node.shape is CapsuleShape2D):
		return
	var cap := shape_node.shape as CapsuleShape2D
	if large:
		cap.radius = 96.0
		cap.height = 192.0
	else:
		cap.radius = 48.0
		cap.height = 96.0



func _grant_blizzard_unlock_and_can() -> void:
	# Host-authored unlock + can drop. Do not call from play_death (clients).
	# user_stories/tasks/US-017/T004-death-unlock-can.md
	# Spawn/combat tests set grant_blizzard_on_death false so die() stays isolated.
	if not grant_blizzard_on_death:
		return
	if _blizzard_rewards_granted:
		return
	if not multiplayer.is_server():
		return
	_blizzard_rewards_granted = true
	DmManager.unlock("bemidji_blizzard")
	SignalBus.on_item_drop.emit({
		"item_type": BAJA_CAN_ITEM,
		"position": global_position,
	})


func die() -> void:
	# Host owns the kill (same is_server guard as enemy.gd).
	# Unlock + drop run once on the server before play_death.rpc.
	# user_stories/tasks/US-017/T003-host-boss-combat.md
	# user_stories/tasks/US-017/T004-death-unlock-can.md
	if _dying:
		return
	if not multiplayer.is_server():
		return
	_cancel_pending_jet()
	_grant_blizzard_unlock_and_can()
	play_death.rpc()
	var tree := get_tree()
	if tree:
		tree.create_timer(DIE_CLIP_SEC + PUFF_SEC).timeout.connect(queue_free)
	else:
		queue_free()


@rpc("authority", "call_local", "reliable")
func play_death() -> void:
	# Play die_* from the 3x5 sheet, then puff. Do not keep attacking after _dying.
	# MUST NOT unlock/drop here — clients run this RPC. Host die() grants T004 rewards.
	# user_stories/tasks/US-017/T003-host-boss-combat.md
	# user_stories/tasks/US-017/T004-death-unlock-can.md
	if _dying:
		return
	_dying = true
	_cancel_pending_jet()
	velocity = Vector2.ZERO
	combat_cooldown = 999.0
	jet_cooldown = 999.0
	if enemy_state_machine:
		enemy_state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	if _health_bar and is_instance_valid(_health_bar):
		_health_bar.visible = false
	var collision := get_node_or_null("CollisionShape2D")
	if collision is CollisionShape2D:
		(collision as CollisionShape2D).set_deferred("disabled", true)
	disable_hurtbox()
	var hurtbox := get_node_or_null("Hurtbox")
	if hurtbox is Area2D:
		(hurtbox as Area2D).monitorable = false
	if sprite:
		sprite.visible = true
	UpdateAnimation("die")
	var tree := get_tree()
	if tree:
		tree.create_timer(DIE_CLIP_SEC).timeout.connect(_puff_after_die)
	else:
		_puff_after_die()


func _puff_after_die() -> void:
	if sprite:
		sprite.visible = false
	var shadow := get_node_or_null("shadow")
	if shadow is CanvasItem:
		(shadow as CanvasItem).visible = false
	var effect := get_node_or_null("destroyEffectSprite")
	if effect is CanvasItem:
		(effect as CanvasItem).visible = true
		var effect_player := effect.get_node_or_null("AnimationPlayer")
		if effect_player is AnimationPlayer:
			(effect_player as AnimationPlayer).play("destroy")


func UpdateAnimation(state: String) -> void:
	# Map idle/wander/attack/blast/die onto the 3x5 S/N/E grid.
	# Missing clips fall back to south idle. Skip replay of looping clips (US-005 367a7f0).
	# Attack/blast/die oneshots must restart so a second swing is visible.
	if animation_player == null:
		return
	var clip := "%s_%s" % [state, AnimDirection()]
	if not animation_player.has_animation(clip):
		clip = FALLBACK_CLIP
	if clip.is_empty() or not animation_player.has_animation(clip):
		return
	var oneshot := state == "attack" or state == "blast" or state == "die"
	if not oneshot and animation_player.current_animation == clip:
		return
	animation_player.play(clip)
