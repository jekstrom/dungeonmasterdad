class_name DmWalkState extends DmState

@export var move_speed: float = 100.0
@onready var idle: DmState = $"../idle"
#@onready var attack: StateAttack = $"../attack"

func Enter() -> void:
	dm.update_animation("walk")
	
func Exit() -> void:
	pass

func Process(_delta: float) -> DmState:
	if dm.direction == Vector2.ZERO:
		return idle
		
	dm.velocity = dm.direction * move_speed
	
	if dm.set_direction():
		dm.update_animation("walk")
	
	return null
	
func Physics(_delta: float) -> DmState:
	return null
	
func HandleInput(_event: InputEvent) -> DmState:
	if _event.is_action_pressed("attack"):
		return null
		#return attack
	if _event.is_action_pressed("interact"):
		DmManager.interact_pressed.emit()
	return null
