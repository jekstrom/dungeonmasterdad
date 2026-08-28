class_name EnemyStateAttack extends EnemyState

@export var anim_name: String = "walk"
@export var walk_speed: float = 220

@export_category("AI")
@export var state_anim_duration: float = 0.5
@export var state_cycles_min: int = 1
@export var state_cycles_max: int = 3
@export var next_state: EnemyState
@export var enemy_node: Node2D

var _direction: Vector2

func init() -> void:
	pass
	
func enter() -> void:
	enemy.UpdateAnimation(anim_name)
	
func exit() -> void:
	pass
	
func process(_delta: float) -> EnemyState:
	if not enemy.can_see_dm() or DmManager.dm == null:
		return next_state
	_direction = enemy.global_position.direction_to(DmManager.dm.global_position)
	enemy.velocity = _direction * walk_speed
	enemy.SetDirection(_direction)
	enemy.UpdateAnimation(anim_name)
	return null
	
func physics(_delta: float) -> EnemyState:
	return null
