class_name PlayerWalkState extends PlayerState

@export var move_speed: float = 100.0
@onready var idle: PlayerState = $"../idle"
@onready var attack: PlayerState = $"../attack"

func Enter() -> void:
	player.update_animation("walk")
	
func Exit() -> void:
	pass

func Process(_delta: float) -> PlayerState:
	if !is_multiplayer_authority(): return

	if player.direction == Vector2.ZERO:
		return idle

	player.velocity = player.direction * move_speed
	
	if player.set_direction():
		player.update_animation("walk")
	
	return null
	
func Physics(_delta: float) -> PlayerState:
	return null
	
func HandleInput(_event: InputEvent) -> PlayerState:
	if !is_multiplayer_authority(): return
	
	if _event.is_action_pressed("attack"):
		return attack
	if _event.is_action_pressed("interact"):
		PlayerManager.interact_pressed.emit()
	return null
