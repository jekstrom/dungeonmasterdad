class_name PlayerIdleState extends PlayerState

const DewSlickScript = preload("res://doodads/dew_slick.gd")

@onready var walk: PlayerState = $"../walk"
@onready var snake: PlayerState = $"../snake"
@onready var attack: PlayerState = $"../attack"

func Enter() -> void:
	player.update_animation("idle")
	
func Exit() -> void:
	pass

func Process(_delta: float) -> PlayerState:
	if player.is_ranged_fire_playing():
		if player.direction != Vector2.ZERO:
			return walk
		if not DewSlickScript.any_covers_world(player.global_position):
			player.velocity = Vector2.ZERO
		return null
	if player.direction != Vector2.ZERO:
		return walk
	if not DewSlickScript.any_covers_world(player.global_position):
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
	if player.wants_fire_staple(_event):
		player.try_fire_staple_from_input()
		return null
	if _event.is_action_pressed("interact"):
		player.try_interact()
	player.handle_form_input(_event)
	return null
