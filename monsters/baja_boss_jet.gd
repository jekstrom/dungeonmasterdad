class_name BajaBossJet extends EnemyState

## US-027 T001/T002: Carbonated Jet telegraph then piercing neon stream.
## Distinct from US-017 blast spit (`baja_boss_blast.gd`). KEEP blast.
## user_stories/tasks/US-027/T001-jet-telegraph.md
## user_stories/tasks/US-027/T002-piercing-stream.md
##
## Pose: boss row 3 (frames 9/10/11 = blast_down/up/side) is the mace arm-point
## telegraph with lime spark. That pose IS the T001 tell. Play blast_* from THIS
## jet state only. Do not enter BajaBossBlast. Do not call apply_blast_hit or
## pulse_blast_hurtbox.

@export var anim_name: String = "blast"
@export var idle_state: EnemyState
@export var wander_state: EnemyState
@export var chase_state: EnemyState
@export var telegraph_sec: float = 0.6

var _timer: float = 0.0
var _fired: bool = false
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
	if enemy is BajaBoss:
		(enemy as BajaBoss).show_jet_tell.rpc(_aim)
	elif enemy.has_method("show_jet_tell"):
		enemy.rpc("show_jet_tell", _aim)

func exit() -> void:
	if enemy == null:
		return
	if enemy is BajaBoss:
		(enemy as BajaBoss).hide_jet_tell.rpc()
	elif enemy.has_method("hide_jet_tell"):
		enemy.rpc("hide_jet_tell")
	if _fired and enemy.has_method("mark_jet_cooldown"):
		enemy.call("mark_jet_cooldown")

func process(_delta: float) -> EnemyState:
	if enemy == null:
		return null
	if enemy._dying or bool(enemy.get("_jet_cancelled")):
		return null
	if (not _fired) and enemy.can_melee_current_target():
		return chase_state if chase_state else _after_clip()
	_timer -= _delta
	if not _fired and _timer <= 0.0:
		_fired = true
		if enemy.has_method("fire_carbonated_jet"):
			enemy.call("fire_carbonated_jet", _aim)
		return _after_clip()
	if _timer > 0.0:
		return null
	return _after_clip()

func physics(_delta: float) -> EnemyState:
	return null

func _after_clip() -> EnemyState:
	if enemy.has_aggro_target() and chase_state:
		return chase_state
	if idle_state:
		return idle_state
	return wander_state
