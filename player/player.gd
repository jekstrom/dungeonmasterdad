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
	collision_mask = collision_mask | 16

func _ready() -> void:
	if is_multiplayer_authority():
		camera_2d.make_current()
	else:
		camera_2d.enabled = false
		
	state_machine.Initialize(self)
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
	var reality_zone_radius = get_parent().find_child("RealityZone").radius
	var reality_zone_pos = get_parent().find_child("RealityZone").global_position
	var valid_placement = BuildingManager.is_area_clear(pos, Vector2(BuildingData.building_size, BuildingData.building_size), reality_zone_radius, reality_zone_pos)
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
