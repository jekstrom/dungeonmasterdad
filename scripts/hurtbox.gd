# Does damage
class_name Hurtbox extends Area2D

@onready var p = $".."
@export var damage: int = 1

func _ready() -> void:
	area_entered.connect(_area_entered)
	if p and p is Enemy:
		damage = p.damage
	pass


func _process(_delta: float) -> void:
	pass

func _area_entered(area: Area2D) -> void:
	if area is Hitbox:
		area.take_damage(self)
