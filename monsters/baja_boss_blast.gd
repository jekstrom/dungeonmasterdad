class_name BajaBossBlast extends EnemyState

## Host ranged Baja spit (blast_*), NOT Bemidji Blizzard, NOT US-018 fireball.
## user_stories/tasks/US-017/T003-host-boss-combat.md
## US-027 HARD RULE: KEEP this spit. Carbonated Jet is baja_boss_jet.gd.

@export var anim_name: String = "blast"
@export var idle_state: EnemyState
@export var wander_state: EnemyState
@export var chase_state: EnemyState
@export var clip_duration: float = 0.6

var _timer: float = 0.0
var _hit: bool = false

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
	_hit = false

func exit() -> void:
	if enemy.has_method("disable_hurtbox"):
		enemy.call("disable_hurtbox")
	if enemy.has_method("mark_combat_cooldown"):
		enemy.call("mark_combat_cooldown")

func process(_delta: float) -> EnemyState:
	if enemy == null or enemy._dying:
		return null
	_timer -= _delta
	if not _hit and _timer <= clip_duration * 0.5:
		_hit = true
		if enemy.has_method("apply_blast_hit"):
			enemy.call("apply_blast_hit")
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
