# Does damage
class_name Hurtbox extends Area2D

@export var damage: int = 1

func _ready() -> void:
	area_entered.connect(_area_entered)
	pass


func _process(_delta: float) -> void:
	pass

func _area_entered(area: Area2D) -> void:
	if area is Hitbox:
		area.take_damage(self)
