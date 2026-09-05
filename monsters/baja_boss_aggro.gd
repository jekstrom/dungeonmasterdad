class_name BajaBossAggro extends EnemyState

## Host chase + combat dispatcher. Walk toward the DM until melee, then attack.
## Priority: melee if in melee; else jet if ready + in jet range (~512-640px); else chase.
## Jet cooldown ~3s so melee still happens. After jet, chase_state=aggro.
## Do not wander-skip aggro.
## user_stories/tasks/US-017/T003-host-boss-combat.md
## user_stories/tasks/US-027/T001-jet-telegraph.md
## NOT Freeze Wave, NOT Sugar Rush, NOT US-018 fireball, NOT Bemidji Blizzard.

@export var attack_state: EnemyState
@export var jet_state: EnemyState
@export var wander_state: EnemyState
@export var idle_state: EnemyState
@export var anim_name: String = "walk"
@export var chase_speed: float = 220.0

func enter() -> void:
	if enemy == null or enemy._dying:
		return
	enemy.acquire_aggro_target()
	var next := _pick_combat()
	if next:
		state_machine.change_state(next)
		return
	_chase(0.016)

func exit() -> void:
	pass

func process(_delta: float) -> EnemyState:
	if enemy == null or enemy._dying:
		return null
	var next := _pick_combat()
	if next:
		return next
	_chase(_delta)
	return null

func physics(_delta: float) -> EnemyState:
	return null

func _pick_combat() -> EnemyState:
	if enemy == null or enemy._dying:
		return null
	if not enemy.has_aggro_target():
		if wander_state:
			return wander_state
		return idle_state
	if enemy.can_melee_current_target():
		enemy.velocity = Vector2.ZERO
		if _ready_for_combat():
			return attack_state
		enemy.UpdateAnimation("idle")
		return null
	if _ready_for_jet() and _in_jet_range() and jet_state:
		return jet_state
	return null

func _ready_for_combat() -> bool:
	if enemy.has_method("ready_for_combat"):
		return bool(enemy.call("ready_for_combat"))
	return true

func _ready_for_jet() -> bool:
	if enemy.has_method("ready_for_jet"):
		return bool(enemy.call("ready_for_jet"))
	return false

func _in_jet_range() -> bool:
	if enemy == null:
		return false
	if enemy.has_method("in_jet_range_of"):
		return bool(enemy.call("in_jet_range_of", enemy.aggro_target))
	return false

func _chase(delta: float) -> void:
	if enemy == null or enemy._dying:
		return
	enemy.acquire_aggro_target()
	var target: Node2D = enemy.aggro_target
	if target == null or not is_instance_valid(target):
		enemy.velocity = Vector2.ZERO
		return
	if enemy.can_melee_current_target():
		enemy.velocity = Vector2.ZERO
		enemy.UpdateAnimation("idle")
		return
	enemy.follow_path_to(target.global_position, chase_speed, delta)
	enemy.UpdateAnimation(anim_name)
