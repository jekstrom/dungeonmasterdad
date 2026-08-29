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

const FALLBACK_CLIP := "idle_down"
const WANDER_CHEBYSHEV := 2
const BLAST_CHEBYSHEV := 2
const BLAST_RANGE_PX := 256.0
const COMBAT_COOLDOWN := 0.8
const DIE_CLIP_SEC := 0.6
const PUFF_SEC := 0.65
const BAJA_CAN_ITEM := "res://pickups/bajablast/bajablast.tres"

var home_cell: Vector2i = Vector2i.ZERO
var combat_cooldown: float = 0.0
var _home_cell_captured: bool = false
var _blizzard_rewards_granted: bool = false
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
	super._ready()
	_capture_home_cell()


func _capture_home_cell() -> void:
	# Wander stays in the exit room: Chebyshev <= 2 of spawn cell.
	# user_stories/tasks/US-017/T003-host-boss-combat.md
	if _home_cell_captured:
		return
	home_cell = DungeonGrid.from_world(global_position)
	_home_cell_captured = true


func _physics_process(delta: float) -> void:
	combat_cooldown = maxf(0.0, combat_cooldown - delta)
	super._physics_process(delta)
	if _dying:
		return
	_clamp_wander_to_home()


func _clamp_wander_to_home() -> void:
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
	# Do not spawn US-018 fireball, do not create a Fantasy pocket, do not call bemidji_blizzard.
	# user_stories/tasks/US-017/T003-host-boss-combat.md
	if not multiplayer.is_server() or _dying:
		return
	acquire_aggro_target()
	var target: Node2D = aggro_target
	if target == null or not is_instance_valid(target):
		return
	var self_cell: Vector2i = DungeonGrid.from_world(global_position)
	var other_cell: Vector2i = DungeonGrid.from_world(target.global_position)
	var in_cells := DungeonGrid.chebyshev(self_cell, other_cell) <= BLAST_CHEBYSHEV
	var in_px := global_position.distance_to(target.global_position) <= BLAST_RANGE_PX
	if not in_cells and not in_px:
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
	velocity = Vector2.ZERO
	combat_cooldown = 999.0
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
