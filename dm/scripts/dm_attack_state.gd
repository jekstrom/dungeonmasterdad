class_name DmAttackState extends DmState

@onready var idle: DmState = $"../idle"

var _finished: bool = false

func Enter() -> void:
	_finished = false
	dm.velocity = Vector2.ZERO
	dm.update_animation("attack")
	dm.start_melee_attack()
	if not dm.animation_player.animation_finished.is_connected(_on_animation_finished):
		dm.animation_player.animation_finished.connect(_on_animation_finished)
	var tree := dm.get_tree()
	if tree:
		tree.create_timer(0.32).timeout.connect(func() -> void:
			_finished = true
		)

func Exit() -> void:
	if dm.animation_player.animation_finished.is_connected(_on_animation_finished):
		dm.animation_player.animation_finished.disconnect(_on_animation_finished)
	dm.end_melee_attack()

func Process(_delta: float) -> DmState:
	dm.velocity = Vector2.ZERO
	if _finished:
		return idle
	return null

func Physics(_delta: float) -> DmState:
	return null

func HandleInput(_event: InputEvent) -> DmState:
	return null

func _on_animation_finished(_anim_name: String) -> void:
	_finished = true
