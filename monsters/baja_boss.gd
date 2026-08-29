class_name BajaBoss extends Enemy

## US-017 T001/T002/T003/T004: Baja Blast boss at dungeon exit.
## Host HP, wander, melee attack, jet, and die. See user_stories/tasks/US-017/T003-host-boss-combat.md
## Host death unlocks bemidji_blizzard and drops the can. See user_stories/tasks/US-017/T004-death-unlock-can.md
## Cast pocket + slow is T005 — do not plant a pocket here.
## Sheet: monsters/baja_boss.png 1152x768, 128x128 cells, hframes=9 vframes=6 (SHA 3912f0b). Transparent bg.
## Each row is a state with 3 frames per facing: cols 0-2 South, 3-5 North, 6-8 East.
## Row 0 idle, 1 walk, 2 attack, 3 die, 4 jet telegraph, 5 jet attack.
## Frame = row*9 + dir_offset + frame. dir_offset: down=0, up=3, side=6.
## Jet is the special attack: jet_tell_* then the beam. Melee uses attack_*.
## Do not use pickups/bajablast/bajablast.png. Do not stretch a goblin.
## NOT Freeze Wave, NOT Sugar Rush, NOT US-018 fireball, NOT Bemidji Blizzard pocket.

const FALLBACK_CLIP := "idle_down"
const WANDER_CHEBYSHEV := 2
const JET_RANGE_PX := 640.0
const JET_SPAWN_OFFSET := 48.0
const MELEE_DAMAGE := 6
const JET_DAMAGE := 20
const AGGRO_RANGE_PX := 1024.0
const COMBAT_COOLDOWN := 0.8
const JET_COOLDOWN := 3.0
const BAJA_CAN_ITEM := "res://pickups/bajablast/bajablast.tres"

var home_cell: Vector2i = Vector2i.ZERO
var combat_cooldown: float = 0.0
var jet_cooldown: float = JET_COOLDOWN  # opening CD so chase/melee still happen first
var jet_telling: bool = false
var _home_cell_captured: bool = false
var _blizzard_rewards_granted: bool = false
var _jet_cancelled: bool = false
@export var grant_blizzard_on_death: bool = true

func _init() -> void:
	max_hp = 12
	hp = 12
	aggro_faction = AggroFaction.DM
	health_bar_title = "BAJA BOSS"


func _ready() -> void:
	health_bar_title = "BAJA BOSS"
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2.ONE
		sprite.region_enabled = false
	_ensure_jet_state_node()
	super._ready()
	_capture_home_cell()



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


func mark_combat_cooldown() -> void:
	combat_cooldown = COMBAT_COOLDOWN


func ready_for_jet() -> bool:
	return (not _dying) and (not _jet_cancelled) and jet_cooldown <= 0.0


func in_jet_range_of(node: Node2D) -> bool:
	# Carbonated Jet lane ~512-640px.
	# user_stories/tasks/US-027/T001-jet-telegraph.md
	if node == null or not is_instance_valid(node):
		return false
	return global_position.distance_to(node.global_position) <= JET_RANGE_PX


func mark_jet_cooldown() -> void:
	jet_cooldown = JET_COOLDOWN


func begin_jet_tell() -> void:
	jet_telling = true


func end_jet_tell() -> void:
	jet_telling = false


func is_showing_jet_tell() -> bool:
	if jet_telling:
		return true
	if animation_player and str(animation_player.current_animation).begins_with("jet_tell_"):
		return true
	return false


func _cancel_pending_jet() -> void:
	_jet_cancelled = true
	jet_telling = false


func fire_carbonated_jet(dir: Vector2) -> Node:
	# Host-only spawn of the piercing neon stream.
	# user_stories/tasks/US-027/T002-piercing-stream.md
	if not multiplayer.is_server():
		return null
	if _dying or _jet_cancelled:
		return null
	end_jet_tell()
	if dir.length() < 0.001:
		dir = Vector2.RIGHT
	else:
		dir = dir.normalized()
	var spawn_pos: Vector2 = global_position + dir * JET_SPAWN_OFFSET
	var data := {
		"kind": "carbonated_jet",
		"position": spawn_pos,
		"direction": dir,
		"damage": JET_DAMAGE,
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
	jet.set("damage", JET_DAMAGE)
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
	var hurtbox := get_node_or_null("Hurtbox")
	if hurtbox and "damage" in hurtbox:
		hurtbox.damage = MELEE_DAMAGE
	_set_hurtbox_size(false)
	_set_hurtbox_monitoring(false)
	_set_hurtbox_monitoring(true)


func disable_hurtbox() -> void:
	_set_hurtbox_monitoring(false)
	_set_hurtbox_size(false)


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


@rpc("authority", "call_local", "reliable")
func play_death() -> void:
	# Play die_* and leave the corpse on the last frame. Do not puff or free.
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
	var hitbox := get_node_or_null("Hitbox")
	if hitbox is Area2D:
		(hitbox as Area2D).monitorable = false
		(hitbox as Area2D).monitoring = false
	if sprite:
		sprite.visible = true
	_place_corpse()
	UpdateAnimation("die")


func _place_corpse() -> void:
	# Stop y-sorting with the player so the puddle cannot draw over them.
	# Reparent onto a non-y-sorted layer so Playground y-sort does not use our Y.
	y_sort_enabled = false
	if sprite:
		sprite.y_sort_enabled = false
	z_index = 0
	var tree := get_tree()
	if tree == null:
		return
	var root: Node = tree.current_scene
	if root == null:
		return
	var corpses: Node = root.get_node_or_null("Corpses")
	if corpses == null:
		var layer := Node2D.new()
		layer.name = "Corpses"
		layer.y_sort_enabled = false
		layer.z_index = 0
		root.add_child(layer)
		corpses = layer
	var keep: Vector2 = global_position
	reparent(corpses)
	global_position = keep


func UpdateAnimation(state: String) -> void:
	# Map idle/walk/attack/die/jet_tell onto the 9x6 S/N/E grid.
	# Missing clips fall back to south idle. Skip replay of looping clips (US-005 367a7f0).
	# Attack/die/jet_tell oneshots must restart so a second tell is visible.
	if animation_player == null:
		return
	var clip := "%s_%s" % [state, AnimDirection()]
	if not animation_player.has_animation(clip):
		clip = FALLBACK_CLIP
	if clip.is_empty() or not animation_player.has_animation(clip):
		return
	var oneshot := state == "attack" or state == "die" or state == "jet_tell"
	if not oneshot and animation_player.current_animation == clip:
		return
	animation_player.play(clip)
