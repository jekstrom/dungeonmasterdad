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
		enforce_map_interior()
		return
	
	if direction != Vector2.ZERO:
		prev_direction = direction
	direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()
	
	if state_name == "snake":
		enforce_map_interior()
		return
	if state_name == "attack":
		velocity = Vector2.ZERO
		move_and_slide()
		enforce_map_interior()
		return
	velocity = direction * 300
	move_and_slide()
	enforce_map_interior()

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
	if current_building_data:
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
		sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	DirectionChanged.emit(new_dir)
	return true

func set_direction() -> bool:
	if not is_inside_tree():
		return false
	return apply_aim(get_global_mouse_position() - global_position)

func set_direction_from_vector(vec: Vector2) -> bool:
	return apply_aim(vec)

func start_melee_attack() -> void:
	var facing: Vector2 = cardinal_direction
	if multiplayer.is_server():
		_pulse_melee_hurtbox(facing)
	else:
		request_melee_attack.rpc_id(1, facing)

func end_melee_attack() -> void:
	if attack_hurtbox:
		attack_hurtbox.monitoring = false

@rpc("any_peer", "reliable")
func request_melee_attack(facing: Vector2) -> void:
	if not multiplayer.is_server():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != get_multiplayer_authority():
		return
	_pulse_melee_hurtbox(facing)

func _pulse_melee_hurtbox(facing: Vector2) -> void:
	if attack_hurtbox == null:
		return
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
	animation_player.play(state + "_" + anim_direction())

func anim_direction() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	return "side"



func is_combat_locked() -> bool:
	if current_building_data:
		return true
	if state_machine == null or state_machine.current_state == null:
		return true
	var state_name: String = state_machine.current_state.name
	if state_name == "death" or state_name == "respawn_wait" or state_name == "snake":
		return true
	return false

func wants_fire_staple(event: InputEvent) -> bool:
	if current_building_data:
		return false
	if event.is_action_pressed("fire"):
		return true
	if event.is_action_pressed("primary_click"):
		return true
	return false

func try_fire_staple_from_input() -> void:
	if not is_multiplayer_authority():
		return
	# Same-frame melee wins; do not spend a staple if melee takes the frame.
	if Input.is_action_pressed("attack"):
		return
	var aim: Vector2 = cardinal_direction
	if is_inside_tree():
		var mouse_aim: Vector2 = get_global_mouse_position() - global_position
		if mouse_aim.length() >= 0.01:
			aim = mouse_aim
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
