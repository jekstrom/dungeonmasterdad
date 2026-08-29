class_name BajaBossJet extends EnemyState

## US-027 T001/T002: Carbonated Jet telegraph then piercing neon stream.
## user_stories/tasks/US-027/T001-jet-telegraph.md
## user_stories/tasks/US-027/T002-piercing-stream.md
##
## This is the boss special attack: jet_tell_* once, then the beam, then idle recover.
## Planted for telegraph_sec (charge) then recover_sec of idle so the DM can react.

@export var anim_name: String = "jet_tell"
@export var idle_anim_name: String = "idle"
@export var idle_state: EnemyState
@export var wander_state: EnemyState
@export var chase_state: EnemyState
@export var telegraph_sec: float = 1.0
@export var recover_sec: float = 1.0

var _timer: float = 0.0
var _fired: bool = false
var _recovering: bool = false
var _aim: Vector2 = Vector2.RIGHT

func enter() -> void:
	if enemy == null or enemy._dying:
		return
	enemy.velocity = Vector2.ZERO
	enemy.acquire_aggro_target()
	if enemy.aggro_target:
		_aim = enemy.global_position.direction_to(enemy.aggro_target.global_position)
	elif enemy.cardinal_direction != Vector2.ZERO:
		_aim = enemy.cardinal_direction
	else:
		_aim = Vector2.RIGHT
	if _aim.length() < 0.001:
		_aim = Vector2.RIGHT
	else:
		_aim = _aim.normalized()
	enemy.SetDirection(_aim)
	enemy.UpdateAnimation(anim_name)
	_timer = telegraph_sec
	_fired = false
	_recovering = false
	if enemy.has_method("begin_jet_tell"):
		enemy.call("begin_jet_tell")

func exit() -> void:
	if enemy == null:
		return
	if enemy.has_method("end_jet_tell"):
		enemy.call("end_jet_tell")
	if _fired and enemy.has_method("mark_jet_cooldown"):
		enemy.call("mark_jet_cooldown")

func process(_delta: float) -> EnemyState:
	if enemy == null:
		return null
	if enemy._dying or bool(enemy.get("_jet_cancelled")):
		return null
	enemy.velocity = Vector2.ZERO
	_timer -= _delta
	if not _fired and _timer <= 0.0:
		_fired = true
		_recovering = true
		if enemy.has_method("fire_carbonated_jet"):
			enemy.call("fire_carbonated_jet", _aim)
		if idle_anim_name:
			enemy.UpdateAnimation(idle_anim_name)
		_timer = recover_sec
		return null
	if _timer > 0.0:
		return null
	return _after_clip()

func physics(_delta: float) -> EnemyState:
	if enemy:
		enemy.velocity = Vector2.ZERO
	return null

func _after_clip() -> EnemyState:
	if enemy.has_aggro_target() and chase_state:
		return chase_state
	if idle_state:
		return idle_state
	return wander_state
