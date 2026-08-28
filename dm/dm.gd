class_name DM extends CharacterBody2D

const DIR_4 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO
var invulnerable: bool = false

var hitpoints: int = 6
var max_hp: int = 6

@export var targeting_scene: PackedScene
@export var fireball_spell: PackedScene
var current_targeting: Node

@onready var camera_2d: DmCamera = $Camera2D

@onready var state_machine: DmStateMachine = $DmStateMachine
signal DirectionChanged(new_direction: Vector2)


@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var label: Label = $Label
@onready var hitbox: Hitbox = $Hitbox
@onready var attack_hurtbox: Hurtbox = $AttackHurtbox

@export var melee_damage: int = 1

func _ready() -> void:
	if is_multiplayer_authority():
		camera_2d.make_current()
	else:
		camera_2d.enabled = false
		
	DmManager.dm = self
	state_machine.Initialize(self)
	label.text = DmManager.dm_player_name
	SignalBus.start_spell_cast.connect(setup_targeting)

func setup_targeting(spell_id: String):
	print("targeting for ", spell_id)
	if current_targeting:
		remove_child(current_targeting)
		current_targeting = null
	current_targeting = targeting_scene.instantiate()
	current_targeting.name = "reticle"
	current_targeting.modulate = Color.RED
	var collision = current_targeting.get_node_or_null("CollisionShape2D")
	if collision:
		collision.disabled = true
	
	add_child(current_targeting)
	
func update_target(pos):
	current_targeting.global_position = pos

func _process(_delta: float) -> void:
	if !is_multiplayer_authority(): return
	if current_targeting:
		update_target(get_global_mouse_position())
	
func _physics_process(_delta: float) -> void:
	if !is_multiplayer_authority(): return
	if state_machine.current_state and state_machine.current_state.name == "attack":
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()
	velocity = direction * 300
	move_and_slide()

func wants_melee_attack(event: InputEvent) -> bool:
	if not event.is_action_pressed("attack"):
		return false
	if current_targeting:
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



func apply_fantasy_hit(amount: int) -> void:
	if not multiplayer.is_server():
		return
	if invulnerable:
		return
	invulnerable = true
	var tree := get_tree()
	if tree:
		tree.create_timer(0.6).timeout.connect(_clear_invulnerable)
	else:
		_clear_invulnerable()
	DmManager.update_fantasy_level(-maxi(1, amount))


func _clear_invulnerable() -> void:
	invulnerable = false


func play_audio(_stream: AudioStream) -> void:
	print("playing audio")
	audio_stream_player_2d.stream = _stream
	audio_stream_player_2d.play()
	
func _unhandled_input(event: InputEvent) -> void:
	if multiplayer.is_server() and event.is_action_pressed("primary_click") and current_targeting:
		var spell_data = {
			"shooter_id" = multiplayer.get_unique_id(),
			"position" = Vector2(global_position.x, global_position.y - 16),
			"target" = current_targeting.global_position,
			"radius_bonus" = 0,
			"base_damage_bonus" = 0,
			"speed_bonus" = 0,
		}
		SignalBus.spell_cast.emit("fireball", spell_data)
		remove_child(current_targeting)
		current_targeting = null
