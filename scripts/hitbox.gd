# Takes damage
class_name Hitbox extends Area2D

signal Damaged(hurt_box: Hurtbox)

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func take_damage(hurt_box: Hurtbox) -> void:
	Damaged.emit(hurt_box)
