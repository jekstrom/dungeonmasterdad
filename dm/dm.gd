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
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		update_target(get_global_mouse_position())
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func _physics_process(_delta: float) -> void:
	if !is_multiplayer_authority(): return
	
	direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()
	velocity = direction * 300
	move_and_slide()

func update_animation(state: String) -> void:
	animation_player.play(state + "_" + anim_direction())

func anim_direction() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	return "side"

func set_direction() -> bool:
	if direction == Vector2.ZERO:
		return false
	
	var direction_id: int = int(round((direction + cardinal_direction * 0.1).angle() / TAU * DIR_4.size()))
	var new_dir = DIR_4[direction_id]
	
	if new_dir == cardinal_direction:
		return false
	
	cardinal_direction = new_dir
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	
	DirectionChanged.emit(new_dir)
	
	return true

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
