class_name TrapState extends EnemyState

@export var next_state: EnemyState
#@onready var cpu_particles: CPUParticles2D = $"../../CPUParticles2D"
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $"../../AudioStreamPlayer2D"

var _timer_start: float = 0.5
var _timer: float = _timer_start
var dropped: bool = false

func init() -> void:
	pass
	
func enter() -> void:
	#_timer = randi_range(state_cycles_min, state_cycles_max) * state_anim_duration
	_timer = _timer_start
	#audio_stream_player_2d.stream = LIGHTNING_KNIGHT_ATTACK
	#audio_stream_player_2d.play()
	
	#cpu_particles.emitting = true
	
func exit() -> void:
	pass
	
func process(_delta: float) -> EnemyState:
	if _timer <= 0:
		enemy.velocity = Vector2.ZERO
		return next_state
	
	_timer -= _delta
	return null
	
func physics(_delta: float) -> EnemyState:
	return null
