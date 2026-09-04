class_name EnemyStateIdle extends EnemyState

@export var anim_name: String = "idle"

@export_category("AI")
@export var state_duration_min: float = 0.5
@export var state_duration_max: float = 1.5
@export var next_state: EnemyState
@export var attack_state: EnemyState
@export var trap_state: EnemyState

var _timer: float = 0.5

@export var cpu_particles: CPUParticles2D
@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"

func init() -> void:
	pass
	
func enter() -> void:
	enemy.velocity = Vector2.ZERO
	_timer = randf_range(state_duration_min, state_duration_max)
	animation_player.play("RESET")
	if cpu_particles:
		cpu_particles.emitting = false
	
func exit() -> void:
	pass
	
func process(_delta: float) -> EnemyState:
	if attack_state and enemy.has_aggro_target():
		return attack_state
	if trap_state and enemy.can_lay_trap():
		return trap_state
	_timer -= _delta
	if _timer <= 0:
		return next_state
	return null
	
func physics(_delta: float) -> EnemyState:
	return null
