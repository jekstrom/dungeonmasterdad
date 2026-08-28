class_name DmIdleState extends DmState

@onready var walk: DmState = $"../walk"
@onready var attack: DmState = $"../attack"

func Enter() -> void:
	dm.update_animation("idle")
	
func Exit() -> void:
	pass

func Process(_delta: float) -> DmState:
	if dm.direction != Vector2.ZERO:
		return walk
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
	return null
