class_name EnemyStateKnightBlitzChargeUp extends EnemyState

@export var anim_name: String = "walk"
@export var wander_speed: float = 90

@export_category("AI")
@export var state_anim_duration: float = 0.5
@export var next_state: EnemyState

@onready var animation_player: AnimationPlayer = $"../../AnimationPlayer"
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $"../../AudioStreamPlayer2D"
const POWER_UP = preload("uid://rds6e43nkpjp")

@onready var shadow: Sprite2D = $"../../shadow"
@onready var sprite: Sprite2D = $"../../Sprite2D"
var original_pos: Vector2
var original_shadow_pos: Vector2

var _timer: float = 3.0
var cnt = 0

func init() -> void:
	pass
	
func enter() -> void:
	_timer = 3
	if DmUnlocks.dm_unlocks.has("spark"):
		_timer = 1.5
	
	original_pos = sprite.position
	original_shadow_pos = shadow.position
	audio_stream_player_2d.stream = POWER_UP
	audio_stream_player_2d.play()
	
	animation_player.play("charge")

func exit() -> void:
	pass
	
func process(_delta: float) -> EnemyState:
	_timer -= _delta
	if _timer <= 0:
		sprite.position = original_pos
		shadow.position = original_shadow_pos
		sprite.modulate = Color.WHITE
		cnt = 0
		return next_state
	
	if cnt % 2 == 0:
		sprite.position = original_pos
		shadow.position = original_shadow_pos
		sprite.modulate = Color.YELLOW
		
	if cnt % 3 == 0:
		sprite.modulate = Color.CYAN
		var x = randf_range(0, 4)
		var y = randf_range(0, 4)
		sprite.global_position.x += x
		sprite.global_position.y += y
		shadow.global_position.x += x
		shadow.global_position.y += y
	
	cnt += 1
	
	return null
	
func physics(_delta: float) -> EnemyState:
	return null
