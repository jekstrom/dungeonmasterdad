class_name Zone extends Area2D

@export var radius: float = 100.0
@export var zone_color: Color = Color(0, 1, 0, 0.3) # Semi-transparent green
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

func _ready():
	collision_shape_2d.shape.radius = radius

func _draw():
	draw_circle(Vector2.ZERO, radius, zone_color)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, zone_color.darkened(0.5), 2.0, true)

func _process(_delta):
	queue_redraw()
