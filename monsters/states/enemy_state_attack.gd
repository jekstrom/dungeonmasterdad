class_name EnemyStateAttack extends EnemyState

@export var anim_name: String = "walk"
@export var walk_speed: float = 220
@export var next_state: EnemyState
@export var wander_state: EnemyState
@export var melee_cooldown: float = 1.0

var _melee_timer: float = 0.0

func enter() -> void:
	_melee_timer = 0.0
	enemy.acquire_aggro_target()
	enemy.UpdateAnimation(anim_name)

func exit() -> void:
	enemy.aggro_target = null
	_set_hurtbox_monitoring(false)

func process(_delta: float) -> EnemyState:
	if not enemy.has_aggro_target():
		return _lose_target_state()
	var target: Node2D = enemy.aggro_target
	var to_target: Vector2 = enemy.global_position.direction_to(target.global_position)
	enemy.velocity = to_target * walk_speed
	enemy.SetDirection(to_target)
	enemy.UpdateAnimation(anim_name)
	_update_melee(_delta)
	return null

func physics(_delta: float) -> EnemyState:
	return null

func _lose_target_state() -> EnemyState:
	if wander_state:
		return wander_state
	return next_state

func _update_melee(delta: float) -> void:
	_melee_timer = maxf(0.0, _melee_timer - delta)
	if not enemy.can_melee_current_target():
		_set_hurtbox_monitoring(false)
		return
	if _melee_timer > 0.0:
		return
	_set_hurtbox_monitoring(false)
	_set_hurtbox_monitoring(true)
	_melee_timer = melee_cooldown

func _set_hurtbox_monitoring(enabled: bool) -> void:
	var hurtbox := enemy.get_node_or_null("Hurtbox")
	if hurtbox is Area2D:
		(hurtbox as Area2D).monitoring = enabled
