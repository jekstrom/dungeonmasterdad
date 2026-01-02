class_name EnemyStateStun extends EnemyState

@export var anim_name: String = "stun"
@export var knockback_speed: float = 200.0
@export var decelerate_speed: float = 10.0

@export_category("AI")
@export var next_state: EnemyState

var _damage_pos: Vector2
var _direction: Vector2
var _animation_finished: bool = false

func init() -> void:
	enemy.enemy_damaged.connect(_on_enemy_damaged)
	
func enter() -> void:
	enemy.invulnerable = true
	_animation_finished = false
	
	_direction = enemy.global_position.direction_to(_damage_pos)
	enemy.SetDirection(_direction)
	enemy.velocity = _direction * -knockback_speed
	enemy.UpdateAnimation(anim_name)
	enemy.animation_player.animation_finished.connect(_on_animation_finished)
	
func exit() -> void:
	enemy.invulnerable = false
	enemy.animation_player.animation_finished.disconnect(_on_animation_finished)
	
func process(_delta: float) -> EnemyState:
	if _animation_finished:
		return next_state
	enemy.velocity -= enemy.velocity * decelerate_speed * _delta
	return null
	
func physics(_delta: float) -> EnemyState:
	return null

func _on_enemy_damaged(hurt_box: Hurtbox) -> void:
	_damage_pos = hurt_box.global_position
	state_machine.change_state(self)

func _on_animation_finished(_animation_name: String) -> void:
	_animation_finished = true
