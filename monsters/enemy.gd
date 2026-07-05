class_name Enemy extends CharacterBody2D

signal direction_changed(new_direction: Vector2)
#signal enemy_damaged(hurt_box: Hurtbox)
#signal enemy_destroyed(hurt_box: Hurtbox)
const DIR_4 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO
var player: Player
var invulnerable: bool = false

@export var hp: int = 4

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var enemy_state_machine: EnemyStateMachine = $EnemyStateMachine
#@onready var hurtbox: Hurtbox = $Hurtbox
#@onready var hitbox: Hitbox = $Hitbox

func _ready() -> void:
	enemy_state_machine.initialize(self)
	player = PlayerManager.player
	#hitbox.Damaged.connect(_take_damage)

func _process(_delta: float) -> void:
	pass

func SetDirection(_new_direction: Vector2) -> bool:
	if _new_direction == Vector2.ZERO:
		return false
		
	direction = _new_direction
	
	var direction_id: int = int(round((direction + cardinal_direction * 0.1).angle() / TAU * DIR_4.size()))
	var new_dir = DIR_4[direction_id]
		
	if new_dir == cardinal_direction:
		return false
	
	cardinal_direction = new_dir
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	
	direction_changed.emit(new_dir)
	
	return true
	
@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	move_and_slide()
	
func UpdateAnimation(state: String) -> void:
	animation_player.play(state + "_" + AnimDirection())

func AnimDirection() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	return "side"

#func _take_damage(hurt_box: Hurtbox) -> void:
	#pass
	#if invulnerable:
		#return
	#hp -= hurt_box.damage
	#if hp > 0:
		#enemy_damaged.emit(hurt_box)
	#else:
		#enemy_destroyed.emit(hurt_box)
