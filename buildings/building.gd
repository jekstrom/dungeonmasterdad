class_name Building extends Node

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d_3: Sprite2D = $Sprite2D3
@onready var sprite_2d_2: Sprite2D = $Sprite2D2
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var timer: float = 0.0
var interval: float = 1.0
var is_ghost: bool = true

func _ready() -> void:
	sprite_2d_2.visible = false
	sprite_2d_3.visible = false

func set_ghost() -> void:
	is_ghost = true
	collision_shape_2d.set_deferred("disabled", true)

func enable() -> void:
	is_ghost = false
	animation_player.play("smoke")
	collision_shape_2d.set_deferred("disabled", false)
	set_deferred("collision_layer", 1)
	set_deferred("collision_mask", 1)

func _process(_delta: float) -> void:
	if is_ghost: return
	pass
