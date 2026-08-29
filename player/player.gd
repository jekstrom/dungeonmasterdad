class_name Player extends CharacterBody2D

const DIR_4 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO
var prev_direction: Vector2 = Vector2.ZERO
var invulnerable: bool = false
var hitpoints: int = 6
var max_hp: int = 6

@onready var camera_2d: PlayerCamera = $Camera2D
@onready var label: Label = $Label

var current_building_data: BuildingData
var ghost_building: Node2D

@export var num_shadows: int = 0
@export var shadow_scene: PackedScene

@onready var hitbox: Hitbox = $Hitbox
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_hurtbox: Hurtbox = $AttackHurtbox

@export var melee_damage: int = 1
@export var staple_magazine_max: int = 20
@export var staple_damage: int = 1
@export var staple_speed: float = 520.0
@export var staple_max_range: float = 360.0
var staple_count: int = 20
var empty_click_played: bool = false
var _melee_swing_active: bool = false
var _queued_staple_fire: bool = false

const TEX_STAPLE_GUN: Texture2D = preload("res://player/sprites/player_staple_gun.png")
const TEX_PENCIL_MELEE: Texture2D = preload("res://player/sprites/player_pencil_melee.png")
const TEX_INK_SLASH: Texture2D = preload("res://sprites/melee_ink_slash.png")
const TEX_SWORD_FALLBACK: Texture2D = preload("res://player/sprites/PlayerSprite02.png")

signal staple_count_changed(count: int)

@export var sync_name: String:
	set(val):
		sync_name = val
		var name_label = get_node_or_null("Label")
		if name_label:
			name_label.text = val
			
@export var sync_color: Color:
	set(val):
		sync_color = val
		var name_label = get_node_or_null("Label")
		if name_label:
			name_label.self_modulate = val
			
@onready var state_machine: PlayerStateMachine = $PlayerStateMachine
signal DirectionChanged(new_direction: Vector2)

func _enter_tree() -> void:
	var id: int = name.to_int()
	print("player id: " + str(id))
	# Only set authority if multiplayer is ready and we have a valid ID
	if multiplayer.has_multiplayer_peer() and id > 0:
		set_multiplayer_authority(id)
	# 16 = walls/cliffs. Clear bit 32 so a leftover Fantasy exclusion shape cannot block Paper Pushers (US-003 T011).
	collision_mask = (collision_mask | 16) & ~32

func _ready() -> void:
	if is_multiplayer_authority():
		camera_2d.make_current()
	else:
		camera_2d.enabled = false
		
	_ensure_combat_visuals()
	state_machine.Initialize(self)
	staple_count = staple_magazine_max
	_refresh_staple_hud()
	SignalBus.build_smoke_building_pressed.connect(setup_building)
	SignalBus.build_paper_building_pressed.connect(setup_building)
	SignalBus.on_dm_unlock.connect(dm_unlock_listener)
	SignalBus.on_dm_lock.connect(dm_lock_listener)

	await get_tree().process_frame
	if not multiplayer.is_server() and is_multiplayer_authority():
		request_name_fix.rpc_id(1)
	label.text = sync_name
	label.self_modulate = sync_color
	
	# Connect to death system signals for respawn handling
	SignalBus.player_respawn_completed.connect(_on_player_respawn_completed)
	hitbox.Damaged.connect(take_damage)
	
func dm_unlock_listener(unlock_name: String) -> void:
	if unlock_name == "shadow_zone" and DmUnlocks.dm_unlocks.get("shadow_zone"):
		state_machine.RequestChangeStateTo.rpc_id(1, "snake")
	elif unlock_name == "shadow_zone" and !DmUnlocks.dm_unlocks.get("shadow_zone"):
		state_machine.ChangeStateTo("idle")
	
func dm_lock_listener(unlock_name: String) -> void:
	if unlock_name == "shadow_zone" and !DmUnlocks.dm_unlocks.get("shadow_zone"):
		state_machine.RequestChangeStateTo.rpc_id(1, "idle")
		
# Force player to idle state (used for respawn)
func force_idle_state() -> void:
	if state_machine and state_machine.has_method("ChangeStateTo"):
		state_machine.ChangeStateTo("idle")
		
# Force player to snake state (used for respawn)
func force_snake_state() -> void:
	if state_machine and state_machine.has_method("ChangeStateTo"):
		state_machine.RequestChangeStateTo.rpc_id(1, "snake")
		
@rpc("any_peer", "reliable")
func request_name_fix():
	if not multiplayer.is_server(): return
	update_client_name.rpc(sync_name, sync_color)
	
@rpc("any_peer", "reliable")
func update_client_name(n, c):
	sync_name = n
	sync_color = c
	
func _process(_delta: float) -> void:
	if !is_multiplayer_authority(): return
	if current_building_data:
		update_ghost(get_global_mouse_position())
		queue_redraw()

func setup_building(building: String):
	current_building_data = load("res://buildings/buildables/" + building + ".tres")
	if ghost_building:
		remove_child(ghost_building)
		ghost_building = null
	ghost_building = current_building_data.scene.instantiate()
	ghost_building.name = "ghost"
	var collision = ghost_building.get_node_or_null("CollisionShape2D")
	if collision:
		collision.disabled = true
	
	add_child(ghost_building)
	ghost_building.set_ghost()
	
func update_ghost(pos: Vector2):
	if ghost_building == null:
		return
	var valid_placement = BuildingManager.is_area_clear(pos, Vector2(BuildingData.building_size, BuildingData.building_size))
	if !valid_placement:
		ghost_building.modulate = Color(1, 0, 0, 0.7)
	else:
		ghost_building.modulate = Color(0, 1, 0, 0.7)
	@warning_ignore("integer_division")
	ghost_building.global_position = Vector2(pos.x, pos.y + BuildingData.building_size / 2)

func _physics_process(_delta: float) -> void:
	if !is_multiplayer_authority(): return
	if state_machine.current_state == null: return
	var state_name: String = state_machine.current_state.name
	if state_name == "death":
		_queued_staple_fire = false
		enforce_map_interior()
		return
	
	if direction != Vector2.ZERO:
		prev_direction = direction
	direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()
	
	if state_name == "snake":
		_queued_staple_fire = false
		enforce_map_interior()
		return
	if state_name == "attack":
		velocity = Vector2.ZERO
		move_and_slide()
		enforce_map_interior()
		_flush_queued_staple_fire()
		_melee_swing_active = false
		return
	velocity = direction * 300
	move_and_slide()
	enforce_map_interior()
	_flush_queued_staple_fire()
	_melee_swing_active = false

func enforce_map_interior() -> void:
	var level: Node = get_tree().get_first_node_in_group("level_manager") if get_tree() else null
	if level and level.has_method("enforce_body_interior"):
		level.enforce_body_interior(self)

@rpc("any_peer", "reliable")
func apply_interior_clamp(pos: Vector2) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != 1:
		return
	if not is_multiplayer_authority():
		return
	global_position = pos
	velocity = Vector2.ZERO

func wants_melee_attack(event: InputEvent) -> bool:
	if not event.is_action_pressed("attack"):
		return false
	if is_combat_locked():
		return false
	return true

static func cardinal_from_aim(aim: Vector2, current: Vector2 = Vector2.DOWN) -> Vector2:
	if aim.length() < 8.0:
		return current
	var biased: Vector2 = aim.normalized() + current * 0.1
	var direction_id: int = posmod(int(round(biased.angle() / TAU * float(DIR_4.size()))), DIR_4.size())
	return DIR_4[direction_id]

func apply_aim(aim: Vector2) -> bool:
	var new_dir: Vector2 = cardinal_from_aim(aim, cardinal_direction)
	if new_dir == cardinal_direction:
		return false
	cardinal_direction = new_dir
	if sprite:
		# Dedicated left/right frames live on the office sheets; do not mirror the sword sheet.
		sprite.scale = Vector2.ONE
	DirectionChanged.emit(new_dir)
	return true

func set_direction() -> bool:
	if not is_inside_tree():
		return false
	return apply_aim(get_global_mouse_position() - global_position)

func set_direction_from_vector(vec: Vector2) -> bool:
	return apply_aim(vec)

func start_melee_attack() -> void:
	if is_combat_locked():
		return
	var facing: Vector2 = cardinal_direction
	_melee_swing_active = true
	if multiplayer.is_server():
		_pulse_melee_hurtbox(facing)
	else:
		request_melee_attack.rpc_id(1, facing)

func end_melee_attack() -> void:
	_melee_swing_active = false
	if attack_hurtbox:
		attack_hurtbox.monitoring = false
	var slash := get_node_or_null("MeleeInkSlash") as Sprite2D
	if slash:
		slash.visible = false

@rpc("any_peer", "reliable")
func request_melee_attack(facing: Vector2) -> void:
	if not multiplayer.is_server():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != get_multiplayer_authority():
		return
	if is_combat_locked():
		return
	_melee_swing_active = true
	_pulse_melee_hurtbox(facing)

func _pulse_melee_hurtbox(facing: Vector2) -> void:
	if is_combat_locked():
		return
	if attack_hurtbox == null:
		return
	_melee_swing_active = true
	attack_hurtbox.damage = melee_damage
	attack_hurtbox.position = Vector2(facing.x * 20.0, facing.y * 16.0 - 8.0)
	attack_hurtbox.monitoring = false
	attack_hurtbox.monitoring = true
	var tree := get_tree()
	if tree:
		tree.create_timer(0.12).timeout.connect(func() -> void:
			if is_instance_valid(attack_hurtbox):
				attack_hurtbox.monitoring = false
		)

func update_animation(state: String) -> void:
	if sprite:
		sprite.scale = Vector2.ONE
		if state == "attack":
			sprite.texture = TEX_PENCIL_MELEE
		else:
			sprite.texture = TEX_STAPLE_GUN
	var anim_name: String = state + "_" + anim_direction()
	if animation_player == null:
		return
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	elif animation_player.has_animation(state + "_side"):
		animation_player.play(state + "_side")

func anim_direction() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	if cardinal_direction == Vector2.UP:
		return "up"
	if cardinal_direction == Vector2.LEFT:
		return "left"
	return "right"

func is_ranged_fire_playing() -> bool:
	if animation_player == null:
		return false
	return str(animation_player.current_animation).begins_with("fire_")

func play_ranged_fire_animation() -> void:
	if sprite:
		sprite.texture = TEX_STAPLE_GUN
		sprite.scale = Vector2.ONE
	var anim_name: String = "fire_" + anim_direction()
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func combat_sheet_path() -> String:
	if sprite and sprite.texture:
		return str(sprite.texture.resource_path)
	return ""



func is_combat_locked() -> bool:
	if current_building_data:
		return true
	var pid: int = get_multiplayer_authority()
	if pid > 0:
		if DeathSystem.active_death_timers.has(pid) or DeathSystem.respawn_reservations.has(pid):
			return true
	if TrailManager.shadow_mode_active:
		return true
	if state_machine and state_machine.current_state:
		var state_name: String = state_machine.current_state.name
		if state_name == "death" or state_name == "respawn_wait" or state_name == "snake":
			return true
	return false

func wants_fire_staple(event: InputEvent) -> bool:
	if is_combat_locked():
		return false
	if event.is_action_pressed("fire"):
		return true
	# LMB is also primary_click (building). Fire only when not placing.
	if event.is_action_pressed("primary_click"):
		return true
	return false

func _gui_blocks_world_fire() -> bool:
	if not is_inside_tree():
		return false
	var hovered: Control = get_viewport().gui_get_hovered_control()
	var n: Node = hovered
	while n:
		if n is BaseButton or n is LineEdit or n is TextEdit:
			return true
		n = n.get_parent()
	return false

func try_fire_staple_from_input() -> void:
	if not is_multiplayer_authority():
		return
	if is_combat_locked():
		return
	# Queue until end of physics frame so same-frame melee (T006) can win.
	_queued_staple_fire = true

func _flush_queued_staple_fire() -> void:
	if not _queued_staple_fire:
		return
	_queued_staple_fire = false
	if not is_multiplayer_authority():
		return
	if is_combat_locked():
		return
	if _melee_swing_active:
		return
	if state_machine and state_machine.current_state and state_machine.current_state.name == "attack":
		return
	if Input.is_action_pressed("attack"):
		return
	var aim: Vector2 = cardinal_direction
	if is_inside_tree():
		var mouse_aim: Vector2 = get_global_mouse_position() - global_position
		if mouse_aim.length() >= 0.01:
			aim = mouse_aim
	if staple_count > 0:
		play_ranged_fire_animation()
	if multiplayer.is_server():
		request_fire_staple(aim)
	else:
		request_fire_staple.rpc_id(1, aim)

# Fire mapping: LMB is `fire` (and `primary_click` when not placing a building).
# Melee is `attack` (Space only). Building placement keeps primary_click.
# Owning client requests; host validates ammo, lockouts, and aim dir.
@rpc("any_peer", "reliable")
func request_fire_staple(aim: Vector2) -> void:
	if not multiplayer.is_server():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != get_multiplayer_authority():
		return
	_host_fire_staple(aim)

func _host_fire_staple(aim: Vector2) -> void:
	if is_combat_locked():
		return
	if _melee_swing_active:
		return
	if state_machine and state_machine.current_state and state_machine.current_state.name == "attack":
		return
	if staple_count <= 0:
		staple_count = 0
		_replicate_staple_count()
		_notify_empty_click()
		return
	var dir: Vector2 = aim
	if dir.length() < 0.01:
		dir = cardinal_direction
	else:
		dir = dir.normalized()
	staple_count -= 1
	if staple_count < 0:
		staple_count = 0
	_replicate_staple_count()
	var spawner: Node = _find_projectile_spawner()
	if spawner == null or not spawner.has_method("spawn_staple"):
		return
	var muzzle: Vector2 = global_position + dir * 18.0
	spawner.spawn_staple({
		"kind": "staple",
		"shooter_id": get_multiplayer_authority(),
		"position": muzzle,
		"direction": dir,
		"damage": staple_damage,
		"speed": staple_speed,
		"max_range": staple_max_range,
	})

func _find_projectile_spawner() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var nodes: Array = tree.get_nodes_in_group("projectile_spawner")
	if nodes.size() > 0:
		return nodes[0]
	return null

func _replicate_staple_count() -> void:
	_refresh_staple_hud()
	if not multiplayer.is_server():
		return
	var owner_id: int = get_multiplayer_authority()
	if owner_id <= 0 or owner_id == multiplayer.get_unique_id():
		return
	receive_staple_count.rpc_id(owner_id, staple_count)

@rpc("any_peer", "reliable")
func receive_staple_count(count: int) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != 1:
		return
	staple_count = maxi(0, count)
	_refresh_staple_hud()

func _refresh_staple_hud() -> void:
	staple_count_changed.emit(staple_count)
	if not is_multiplayer_authority():
		return
	if PlayerHud and PlayerHud.has_method("update_staple_magazine"):
		PlayerHud.update_staple_magazine(staple_count, staple_magazine_max)

func _notify_empty_click() -> void:
	var owner_id: int = get_multiplayer_authority()
	if owner_id == multiplayer.get_unique_id() or owner_id <= 0:
		play_empty_magazine_click()
		return
	play_empty_magazine_click.rpc_id(owner_id)

@rpc("any_peer", "reliable")
func play_empty_magazine_click() -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != 1 and sender != get_multiplayer_authority():
		return
	empty_click_played = true
	var player_audio := AudioStreamPlayer.new()
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 11025
	stream.stereo = false
	var frames: int = 110
	var data := PackedByteArray()
	data.resize(frames)
	for i in frames:
		var t: float = 1.0 - float(i) / float(frames)
		data[i] = 128 + int(sin(float(i) * 1.4) * 36.0 * t)
	stream.data = data
	player_audio.stream = stream
	add_child(player_audio)
	player_audio.play()
	player_audio.finished.connect(player_audio.queue_free)

func _input(event: InputEvent) -> void:
	# Live LMB cannot live only in _unhandled_input: HUD Controls consume the click.
	if not is_multiplayer_authority():
		return
	if not wants_fire_staple(event):
		return
	if _gui_blocks_world_fire():
		return
	try_fire_staple_from_input()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("primary_click"):
		if current_building_data:
			BuildingManager.request_placement.rpc_id(1, current_building_data.resource_path, ghost_building.global_position, get_global_mouse_position())
			remove_child(ghost_building)
			current_building_data = null
			ghost_building = null

# =============================================================================
# DEATH SYSTEM INTEGRATION
# =============================================================================
func _on_player_respawn_completed(player_id: int, respawn_position: Vector2) -> void:
	"""Handle respawn completion - move to respawn position and reset state"""
	# Only handle for this player
	if player_id != get_multiplayer_authority():
		return
	
	print("Player ", player_id, " respawning at ", respawn_position)
	
	global_position = respawn_position
	enforce_map_interior()
	
	# Reset player state
	velocity = Vector2.ZERO
	hitpoints = max_hp
	invulnerable = false
	
	# The death state Exit() method will handle restoring visibility and collisions
	# This ensures consistency between all death/respawn pathways
	print("Player ", player_id, " respawn completed - death state will handle restoration")
	
	# Force to idle state if not already
	if TrailManager.shadow_mode_active:
		force_snake_state()
	else:
		force_idle_state()

func take_damage(_hurt_box: Hurtbox) -> void:
	if not multiplayer.is_server(): return
	if invulnerable: return
	DeathSystem.request_player_death(int(name), position)


func _ensure_combat_visuals() -> void:
	if sprite:
		sprite.hframes = 16
		sprite.vframes = 3
		sprite.texture = TEX_STAPLE_GUN
		sprite.scale = Vector2.ONE
	_ensure_ink_slash()
	_rebuild_combat_animations()

func _ensure_ink_slash() -> void:
	var slash := get_node_or_null("MeleeInkSlash") as Sprite2D
	if slash == null:
		slash = Sprite2D.new()
		slash.name = "MeleeInkSlash"
		add_child(slash)
	slash.texture = TEX_INK_SLASH
	slash.hframes = 12
	slash.vframes = 1
	slash.visible = false
	slash.z_index = 2
	slash.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _rebuild_combat_animations() -> void:
	if animation_player == null:
		return
	var lib: AnimationLibrary = animation_player.get_animation_library("")
	if lib == null:
		lib = AnimationLibrary.new()
		animation_player.add_animation_library("", lib)
	var gun := {
		"down": {"idle": [0, 1], "walk": [2, 3, 4, 5], "fire": [6, 7]},
		"up": {"idle": [8, 9], "walk": [10, 11, 12, 13], "fire": [14, 15]},
		# E/W cells mix full-height and half-height. Use the large cells only.
		# No idle/breathe on sides; do not scale E/W down to fit N/S.
		"right": {"idle": [17], "walk": [19, 21], "fire": [23]},
		"left": {"idle": [24], "walk": [26, 27, 28, 29], "fire": [31]},
	}
	# Packed DOWN/LEFT/RIGHT/UP, idle x2, walk x4, swing x3 (T005 / T008).
	var pencil := {
		"down": {"idle": [0, 1], "walk": [2, 3, 4, 5], "attack": [6, 7, 8]},
		"left": {"idle": [9, 10], "walk": [11, 12, 13, 14], "attack": [15, 16, 17]},
		"right": {"idle": [18, 19], "walk": [20, 21, 22, 23], "attack": [24, 25, 26]},
		"up": {"idle": [27, 28], "walk": [29, 30, 31, 32], "attack": [33, 34, 35]},
	}
	for d in ["down", "up", "left", "right"]:
		var side: bool = d == "left" or d == "right"
		_put_anim(lib, "idle_" + d, TEX_STAPLE_GUN, gun[d]["idle"], 0.1 if side else 0.4, not side, false, d)
		_put_anim(lib, "walk_" + d, TEX_STAPLE_GUN, gun[d]["walk"], 0.4, true, false, d)
		_put_anim(lib, "fire_" + d, TEX_STAPLE_GUN, gun[d]["fire"], 0.18, false, false, d)
		_put_anim(lib, "attack_" + d, TEX_PENCIL_MELEE, pencil[d]["attack"], 0.28, false, true, d)
	# Keep *_side as right-facing aliases for older play() calls.
	_put_anim(lib, "idle_side", TEX_STAPLE_GUN, gun["right"]["idle"], 0.1, false, false, "right")
	_put_anim(lib, "walk_side", TEX_STAPLE_GUN, gun["right"]["walk"], 0.4, true, false, "right")
	_put_anim(lib, "attack_side", TEX_PENCIL_MELEE, pencil["right"]["attack"], 0.28, false, true, "right")
	_put_anim(lib, "fire_side", TEX_STAPLE_GUN, gun["right"]["fire"], 0.18, false, false, "right")

func _put_anim(lib: AnimationLibrary, anim_name: String, tex: Texture2D, frames: Array, length: float, loop: bool, ink: bool, dir_name: String) -> void:
	var anim := Animation.new()
	anim.length = length
	anim.loop_mode = Animation.LOOP_PINGPONG if loop else Animation.LOOP_NONE
	var tex_i: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tex_i, NodePath("Sprite2D:texture"))
	anim.value_track_set_update_mode(tex_i, Animation.UPDATE_DISCRETE)
	anim.track_insert_key(tex_i, 0.0, tex)
	var fr_i: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(fr_i, NodePath("Sprite2D:frame"))
	anim.value_track_set_update_mode(fr_i, Animation.UPDATE_DISCRETE)
	var n: int = maxi(1, frames.size())
	for i in n:
		var t: float = 0.0 if n == 1 else length * float(i) / float(n)
		anim.track_insert_key(fr_i, t, int(frames[i]))
	var vis_i: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(vis_i, NodePath("MeleeInkSlash:visible"))
	anim.value_track_set_update_mode(vis_i, Animation.UPDATE_DISCRETE)
	anim.track_insert_key(vis_i, 0.0, ink)
	if ink:
		anim.track_insert_key(vis_i, maxf(0.0, length - 0.01), false)
		var ink_fr: int = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(ink_fr, NodePath("MeleeInkSlash:frame"))
		anim.value_track_set_update_mode(ink_fr, Animation.UPDATE_DISCRETE)
		for i in 12:
			anim.track_insert_key(ink_fr, length * float(i) / 12.0, i)
		var pos_i: int = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(pos_i, NodePath("MeleeInkSlash:position"))
		anim.value_track_set_update_mode(pos_i, Animation.UPDATE_DISCRETE)
		anim.track_insert_key(pos_i, 0.0, _ink_slash_position(dir_name))
		var rot_i: int = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(rot_i, NodePath("MeleeInkSlash:rotation"))
		anim.value_track_set_update_mode(rot_i, Animation.UPDATE_DISCRETE)
		anim.track_insert_key(rot_i, 0.0, _ink_slash_rotation(dir_name))
	if lib.has_animation(anim_name):
		lib.remove_animation(anim_name)
	lib.add_animation(anim_name, anim)

func _ink_slash_position(dir_name: String) -> Vector2:
	if dir_name == "down":
		return Vector2(0, 22)
	if dir_name == "up":
		return Vector2(0, -28)
	if dir_name == "left":
		return Vector2(-24, -8)
	return Vector2(24, -8)

func _ink_slash_rotation(dir_name: String) -> float:
	if dir_name == "down":
		return PI * 0.5
	if dir_name == "up":
		return -PI * 0.5
	if dir_name == "left":
		return PI
	return 0.0
