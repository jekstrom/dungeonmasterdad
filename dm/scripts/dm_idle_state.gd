class_name DmIdleState extends DmState

const DewSlickScript = preload("res://doodads/dew_slick.gd")

@onready var walk: DmState = $"../walk"
@onready var attack: DmState = $"../attack"

func Enter() -> void:
	dm.update_animation("idle")
	
func Exit() -> void:
	pass

func Process(_delta: float) -> DmState:
	if dm.direction != Vector2.ZERO:
		return walk
	if not DewSlickScript.any_covers_world(dm.global_position):
		dm.velocity = Vector2.ZERO
	if dm.set_direction():
		dm.update_animation("idle")
	return null
	
func Physics(_delta: float) -> DmState:
	return null
	
func HandleInput(_event: InputEvent) -> DmState:
	if !is_multiplayer_authority():
		return null
	if dm.wants_melee_attack(_event):
		return attack
	if _event.is_action_pressed("interact"):
		DmManager.interact_pressed.emit()
	for i in 4:
		if _event.is_action_pressed("inv_slot_%d" % i):
			PlayerManager.use_instant_slot(dm.get_multiplayer_authority(), i)
			break
	return null
