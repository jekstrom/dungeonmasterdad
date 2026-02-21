class_name BlitzCharge extends EnemyState

@export var anim_name: String = "walk"
@export var wander_speed: float = 950

@export_category("AI")
@export var state_anim_duration: float = 0.5
@export var state_cycles_min: int = 1
@export var state_cycles_max: int = 3
@export var next_state: EnemyState
@onready var cpu_particles: CPUParticles2D = $"../../CPUParticles2D"
@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $"../../AudioStreamPlayer2D"
const LIGHTNING_KNIGHT_ATTACK = preload("uid://10d0bbngacih")

var _timer_start: float = 0.5
var _switch_timer_start: float = 0.1
var _timer: float = _timer_start
var _switch_timer: float = _switch_timer_start
var cnt = 0
var charge_array = []
var is_moving: bool = false

func init() -> void:
	pass
	
func enter() -> void:
	#_timer = randi_range(state_cycles_min, state_cycles_max) * state_anim_duration
	_timer = _timer_start
	_switch_timer = _switch_timer_start
	var number_directions = randi_range(2, 5)
	cnt = number_directions
	audio_stream_player_2d.stream = LIGHTNING_KNIGHT_ATTACK
	audio_stream_player_2d.play()
	
	var prev_dir: Vector2
	for i in number_directions:
		var direction: Vector2
		if prev_dir:
			direction = prev_dir.orthogonal() if randi_range(0, 1) == 0 else prev_dir.orthogonal() * -1
		else:
			direction = enemy.DIR_4[randi_range(0,3)]
			
		prev_dir = direction
		charge_array.push_back(direction)

	animation_player.play("attack")
	cpu_particles.emitting = true
	
func exit() -> void:
	pass
	
func process(_delta: float) -> EnemyState:
	if _timer <= 0:
		enemy.velocity = Vector2.ZERO
		return next_state
	
	if _switch_timer <= 0:
		var dir = charge_array.pop_front()
		if dir:
			enemy.velocity = dir * wander_speed
			enemy.SetDirection(dir)
			_switch_timer = _switch_timer_start

	_timer -= _delta
	_switch_timer -= _delta
	return null
	
func physics(_delta: float) -> EnemyState:
	return null
