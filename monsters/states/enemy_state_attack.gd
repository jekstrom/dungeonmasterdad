class_name EnemyStateAttack extends EnemyState

@export var anim_name: String = "walk"
@export var walk_speed: float = 20

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
	if DmManager.dm and enemy_node and DmManager.dm.position.distance_to(enemy_node.position) < 200:
		_direction = enemy_node.position.direction_to(DmManager.dm.position)
		enemy.velocity = _direction * walk_speed
		enemy.SetDirection(_direction)
		return null
		
	else:
		return next_state
	
func physics(_delta: float) -> EnemyState:
	return null
