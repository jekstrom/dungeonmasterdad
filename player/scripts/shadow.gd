class_name Shadow extends Node2D

@export var enabled: bool = true
@export var texture: AtlasTexture
var trail_color: Color = Color(0.3, 0.3, 0.3, 0.7)
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var area_2d: Area2D = $Area2D

var player_id: int

func _ready() -> void:
	sprite_2d.z_index = -1

func _process(_delta: float) -> void:
	sprite_2d.visible = enabled
	sprite_2d.modulate = trail_color
	sprite_2d.texture = texture
	area_2d.monitoring = enabled
