class_name BajaBossAggro extends EnemyState

## Tiny host dispatcher: melee -> attack else -> blast.
## user_stories/tasks/US-017/T003-host-boss-combat.md
## Blast is Baja spit, not Bemidji Blizzard. T004 unlock is not here.

@export var attack_state: EnemyState
@export var blast_state: EnemyState
@export var wander_state: EnemyState
@export var idle_state: EnemyState

func enter() -> void:
	if enemy == null or enemy._dying:
		return
	enemy.velocity = Vector2.ZERO
	var next := _pick()
	if next:
		state_machine.change_state(next)
		return
	enemy.UpdateAnimation("idle")

func exit() -> void:
	pass

func process(_delta: float) -> EnemyState:
	return _pick()

func physics(_delta: float) -> EnemyState:
	return null

func _pick() -> EnemyState:
	if enemy == null or enemy._dying:
		return null
	if not enemy.has_aggro_target():
		if wander_state:
			return wander_state
		return idle_state
	if enemy.has_method("ready_for_combat") and not enemy.call("ready_for_combat"):
		return null
	if enemy.can_melee_current_target():
		return attack_state
	return blast_state
