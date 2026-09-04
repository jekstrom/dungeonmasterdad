class_name GoblinTrap extends Node2D

@onready var sprite_2d_closed: Sprite2D = $Sprite2D_closed
@onready var sprite_2d_open: Sprite2D = $Sprite2D_open

@onready var area_2d: Area2D = $Area2D

var triggered: bool = false

func _ready() -> void:
	triggered = false
	area_2d.body_entered.connect(_on_enter)
	
func _on_enter(_body: Node2D) -> void:
	if !triggered:
		sprite_2d_closed.visible = true
		sprite_2d_open.visible = false
		triggered = true
	
