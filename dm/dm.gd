class_name DM extends CharacterBody2D

const DIR_4 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO
var invulnerable: bool = false

var hitpoints: int = 6
var max_hp: int = 6

@onready var camera_2d: DmCamera = $Camera2D

@onready var state_machine: DmStateMachine = $DmStateMachine
signal DirectionChanged(new_direction: Vector2)


@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

#func _enter_tree() -> void:
	#var id: int = name.to_int()
	#print("dm mp id: " + str(id))
	#set_multiplayer_authority(name.to_int())

func _ready() -> void:
	if is_multiplayer_authority():
		camera_2d.make_current()
	else:
		camera_2d.enabled = false
		
	DmManager.dm = self
	state_machine.Initialize(self)

func _process(_delta: float) -> void:
	if !is_multiplayer_authority(): return
	pass
	
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
