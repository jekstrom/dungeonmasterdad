class_name EnemyStateWander extends EnemyState

@export var anim_name: String = "walk"
@export var wander_speed: float = 20

@export_category("AI")
@export var state_anim_duration: float = 0.5
@export var state_cycles_min: int = 1
@export var state_cycles_max: int = 3
@export var next_state: EnemyState
@export var attack_state: EnemyState
@export var trap_state: EnemyState
@export var enemy_node: Node2D

var _timer: float = 0.0
var _direction: Vector2

func init() -> void:
	pass
	
func enter() -> void:
	_timer = randi_range(state_cycles_min, state_cycles_max) * state_anim_duration
	_direction = enemy.DIR_4.pick_random()
	enemy.velocity = _direction * wander_speed
	enemy.SetDirection(_direction)
	enemy.UpdateAnimation(anim_name)
	
func exit() -> void:
	pass
	
func process(_delta: float) -> EnemyState:
	_timer -= _delta
	if attack_state and enemy.has_aggro_target():
		return attack_state
	if trap_state and enemy.can_lay_trap():
		return trap_state
	if _timer <= 0:
		return next_state
	return null
	
func physics(_delta: float) -> EnemyState:
	return null
