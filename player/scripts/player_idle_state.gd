class_name PlayerIdleState extends PlayerState

@onready var walk: PlayerState = $"../walk"
@onready var snake: PlayerState = $"../snake"
#@onready var attack: State = $"../attack"

func Enter() -> void:
	player.update_animation("idle")
	
func Exit() -> void:
	pass

func Process(_delta: float) -> PlayerState:
	if player.direction != Vector2.ZERO:
		return walk
	player.velocity = Vector2.ZERO
	return null
	
func Physics(_delta: float) -> PlayerState:
	return null
	
func HandleInput(_event: InputEvent) -> PlayerState:
	if _event.is_action_pressed("attack"):
		return null
		#return attack
	if _event.is_action_pressed("interact"):
		PlayerManager.interact_pressed.emit()
	
	# Temporary test: Press 'S' to enter snake mode for testing
	if _event is InputEventKey and _event.pressed and _event.keycode == KEY_S:
		print("Test: Entering snake mode manually")
		return snake
		
	return null
