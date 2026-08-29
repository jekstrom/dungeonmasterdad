class_name Building extends Node

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@export var interval: float = 1.0
@export var hitpoints: int = 10
var timer: float = 0.0
var is_ghost: bool = true

func set_ghost() -> void:
	is_ghost = true
	collision_shape_2d.set_deferred("disabled", true)

func enable() -> void:
	is_ghost = false
	collision_shape_2d.set_deferred("disabled", false)
	set_deferred("collision_layer", 1)
	set_deferred("collision_mask", 1)

func _process(_delta: float) -> void:
	if is_ghost: return
	pass
