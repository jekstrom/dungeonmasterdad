class_name TrapState extends EnemyState

const TRAP_SCENE: PackedScene = preload("res://doodads/goblin_trap.tscn")

@export var next_state: EnemyState

var _timer_start: float = 0.5
var _timer: float = _timer_start
var dropped: bool = false

func init() -> void:
	pass

func enter() -> void:
	_timer = _timer_start
	dropped = false
	enemy.velocity = Vector2.ZERO
	enemy.UpdateAnimation("idle")
	if enemy.can_lay_trap():
		_drop_trap()

func exit() -> void:
	pass

func process(_delta: float) -> EnemyState:
	if _timer <= 0.0:
		enemy.velocity = Vector2.ZERO
		return next_state
	_timer -= _delta
	return null

func physics(_delta: float) -> EnemyState:
	return null

func _drop_trap() -> void:
	if dropped:
		return
	if not enemy.multiplayer.is_server():
		return
	var cell: Vector2i = DungeonGrid.from_world(enemy.global_position)
	var world: Vector2 = DungeonGrid.to_world(cell) + Vector2(DungeonGrid.CELL_PX * 0.5, DungeonGrid.SPRITE_TOP)
	var tree := enemy.get_tree()
	if tree != null:
		var spawner: Node = tree.get_first_node_in_group("multiplayer_spawner")
		if spawner != null and spawner.has_method("spawn_goblin_trap_at"):
			var spawned: Node = spawner.call("spawn_goblin_trap_at", world)
			if spawned != null:
				dropped = true
				enemy.mark_trap_laid()
				return
	if TRAP_SCENE == null:
		return
	var parent: Node = enemy.get_parent()
	if parent == null:
		return
	var trap: Node = TRAP_SCENE.instantiate()
	if trap is Node2D:
		(trap as Node2D).position = world
	parent.add_child(trap, true)
	dropped = true
	enemy.mark_trap_laid()
