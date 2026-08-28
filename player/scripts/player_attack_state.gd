class_name PlayerAttackState extends PlayerState

@onready var idle: PlayerState = $"../idle"

var _finished: bool = false

func Enter() -> void:
	_finished = false
	player.velocity = Vector2.ZERO
	player.set_direction()
	player.update_animation("attack")
	player.start_melee_attack()
	if not player.animation_player.animation_finished.is_connected(_on_animation_finished):
		player.animation_player.animation_finished.connect(_on_animation_finished)
	var tree := player.get_tree()
	if tree:
		tree.create_timer(0.32).timeout.connect(func() -> void:
			_finished = true
		)

func Exit() -> void:
	if player.animation_player.animation_finished.is_connected(_on_animation_finished):
		player.animation_player.animation_finished.disconnect(_on_animation_finished)
	player.end_melee_attack()

func Process(_delta: float) -> PlayerState:
	player.velocity = Vector2.ZERO
	if _finished:
		return idle
	return null

func Physics(_delta: float) -> PlayerState:
	return null

func HandleInput(_event: InputEvent) -> PlayerState:
	return null

func _on_animation_finished(_anim_name: String) -> void:
	_finished = true
