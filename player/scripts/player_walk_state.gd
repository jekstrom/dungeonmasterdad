class_name PlayerWalkState extends PlayerState

const DewSlickScript = preload("res://doodads/dew_slick.gd")

@export var move_speed: float = 100.0
@onready var idle: PlayerState = $"../idle"
@onready var attack: PlayerState = $"../attack"

func Enter() -> void:
	player.update_animation("walk")
	
func Exit() -> void:
	pass

func Process(_delta: float) -> PlayerState:
	if !is_multiplayer_authority(): return
	if player.is_stunned():
		player.velocity = Vector2.ZERO
		player.direction = Vector2.ZERO
		return idle

	if player.direction == Vector2.ZERO:
		return idle
	if not DewSlickScript.any_covers_world(player.global_position):
		player.velocity = player.direction * player.get_move_speed()

	if player.is_ranged_fire_playing():
		return null
	
	if player.set_direction():
		player.update_animation("walk")
	
	return null
	
func Physics(_delta: float) -> PlayerState:
	return null
	
func HandleInput(_event: InputEvent) -> PlayerState:
	if !is_multiplayer_authority():
		return null
	if player.wants_melee_attack(_event):
		return attack
	if player.wants_fire_staple(_event):
		player.try_fire_staple_from_input()
		return null
	if _event.is_action_pressed("interact"):
		player.try_interact()
	player.handle_form_input(_event)
	return null
