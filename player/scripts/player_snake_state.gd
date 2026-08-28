class_name PlayerSnakeState extends PlayerState

@export var move_speed: float = 100.0
@export var trail_interval: float = 16.0
@export var main_sprite: Sprite2D
@onready var idle: PlayerState = $"../idle"

var trail_positions: Array[Vector2] = []
var last_trail_position: Vector2
var player_id: int = -1
var trail_container: SnakeTrailContainer

@rpc("any_peer", "call_local", "reliable")
func notify_server_player_death(pid: int, death_pos: Vector2) -> void:
	if not multiplayer.is_server():
		return
	SignalBus.player_death_requested.emit(pid, death_pos)

func Enter() -> void:
	player.update_animation("walk")
	player_id = int(player.name)
	
	var original_mask = player.collision_mask
	player.collision_mask = original_mask | 32  # Add trail collision layer
	
func Exit() -> void:
	# Restore original collision mask by removing trail collision layer
	player.collision_mask = player.collision_mask & ~32  # Remove trail collision layer

func Process(_delta: float) -> PlayerState:
	if !is_multiplayer_authority(): 
		return null
	
	player.velocity = player.prev_direction * move_speed
	
	if player.set_direction_from_vector(player.prev_direction):
		player.update_animation("walk")
	
	player.move_and_slide()
	player.enforce_map_interior()

	return null
	
func Physics(_delta: float) -> PlayerState:
	return null
	
func HandleInput(_event: InputEvent) -> PlayerState:
	if !is_multiplayer_authority(): 
		return null
	
	if _event.is_action_pressed("attack"):
		return null
	if _event.is_action_pressed("interact"):
		PlayerManager.interact_pressed.emit()
		
	return null
