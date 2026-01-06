class_name FireballSpell extends Area2D

@export var radius: float = 100.0
@export var base_damage: int = 5
@export var speed: float = 565

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var explosion: Sprite2D = $Explosion
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var shooter_id: int
var target: Vector2
var exploding: bool = false

func _ready() -> void:
	explosion.visible = false
	look_at(target)
	
func _process(_delta: float) -> void:
	if exploding: return
	if target:
		position = global_position.move_toward(target, speed * _delta)

	if global_position.distance_to(target) <= 0.01:
		sprite_2d.visible = false
		explode()
	
func set_target(pos: Vector2) -> void:
	target = pos

func explode() -> void:
	if exploding: return
	exploding = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	collision_shape_2d.set_deferred("disabled", true)
	animation_player.play("explode")
	var explosion_data = {
		"type": "fire",
		"damage": base_damage,
		"radius": radius,
	}
	SignalBus.on_explosion.emit(position, explosion_data)
	
	await animation_player.animation_finished
	queue_free()
