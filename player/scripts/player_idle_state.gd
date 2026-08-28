class_name PlayerIdleState extends PlayerState

@onready var walk: PlayerState = $"../walk"
@onready var snake: PlayerState = $"../snake"
@onready var attack: PlayerState = $"../attack"

func Enter() -> void:
	player.update_animation("idle")
	
func Exit() -> void:
	pass

func Process(_delta: float) -> PlayerState:
	if player.direction != Vector2.ZERO:
		return walk
	player.velocity = Vector2.ZERO
	if player.set_direction():
		player.update_animation("idle")
	return null
	
func Physics(_delta: float) -> PlayerState:
	return null
	
func HandleInput(_event: InputEvent) -> PlayerState:
	if !is_multiplayer_authority():
		return null
	if player.wants_melee_attack(_event):
		return attack
	if _event.is_action_pressed("interact"):
		PlayerManager.interact_pressed.emit()
		
	return null
