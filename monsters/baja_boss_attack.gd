class_name BajaBossAttack extends EnemyState

## Host melee clip. Pattern off enemy_state_attack.gd, oneshot attack_* then wander/idle.
## user_stories/tasks/US-017/T003-host-boss-combat.md

@export var anim_name: String = "attack"
@export var idle_state: EnemyState
@export var wander_state: EnemyState
@export var chase_state: EnemyState
@export var clip_duration: float = 0.6

var _timer: float = 0.0

func enter() -> void:
	if enemy == null or enemy._dying:
		return
	enemy.velocity = Vector2.ZERO
	enemy.acquire_aggro_target()
	if enemy.aggro_target:
		var to_target: Vector2 = enemy.global_position.direction_to(enemy.aggro_target.global_position)
		enemy.SetDirection(to_target)
	enemy.UpdateAnimation(anim_name)
	_timer = clip_duration
	if enemy.has_method("pulse_melee_hurtbox"):
		enemy.call("pulse_melee_hurtbox")
	else:
		_set_hurtbox_monitoring(false)
		_set_hurtbox_monitoring(true)

func exit() -> void:
	if enemy.has_method("disable_hurtbox"):
		enemy.call("disable_hurtbox")
	if enemy.has_method("mark_combat_cooldown"):
		enemy.call("mark_combat_cooldown")
	else:
		_set_hurtbox_monitoring(false)

func process(_delta: float) -> EnemyState:
	if enemy == null or enemy._dying:
		return null
	_timer -= _delta
	if _timer > 0.0:
		return null
	return _after_clip()

func physics(_delta: float) -> EnemyState:
	return null

func _after_clip() -> EnemyState:
	if enemy.has_aggro_target() and chase_state:
		return chase_state
	if enemy.has_aggro_target() and not enemy.can_melee_current_target():
		if wander_state:
			return wander_state
	if idle_state:
		return idle_state
	return wander_state

func _set_hurtbox_monitoring(enabled: bool) -> void:
	var hurtbox := enemy.get_node_or_null("Hurtbox")
	if hurtbox is Area2D:
		(hurtbox as Area2D).monitoring = enabled
