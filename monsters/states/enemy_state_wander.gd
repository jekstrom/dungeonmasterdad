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
	enemy.SetDirection(_direction)
	enemy.UpdateAnimation(anim_name)
	_pick_walkable_direction()
	
func exit() -> void:
	pass
	
func process(_delta: float) -> EnemyState:
	_timer -= _delta
	if attack_state and enemy.has_aggro_target():
		return attack_state
	if trap_state and enemy.can_lay_trap():
		return trap_state
	if _direction_blocked(_direction):
		_pick_walkable_direction()
	enemy.velocity = _direction * wander_speed
	if _timer <= 0:
		return next_state
	return null


func _direction_blocked(dir: Vector2) -> bool:
	if dir.length_squared() < 0.0001:
		return true
	var finder: Node = enemy.get_tree().root.get_node_or_null("MonsterPathfinder") if enemy.get_tree() else null
	if finder == null or not finder.has_method("is_walkable_cell"):
		return false
	var probe: Vector2 = enemy.global_position + dir.normalized() * 40.0
	return not bool(finder.is_world_walkable(probe))


func _pick_walkable_direction() -> void:
	var options: Array[Vector2] = []
	for d in enemy.DIR_4:
		options.append(d)
	options.shuffle()
	for dir in options:
		if not _direction_blocked(dir):
			_direction = dir
			enemy.SetDirection(_direction)
			enemy.velocity = _direction * wander_speed
			return
	_direction = Vector2.ZERO
	enemy.velocity = Vector2.ZERO
	
func physics(_delta: float) -> EnemyState:
	return null
