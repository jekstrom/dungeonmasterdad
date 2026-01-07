class_name Zone extends Area2D

@export var base_radius: float = 100.0
@export var zone_color: Color = Color(0, 1, 0, 0.3) # Semi-transparent green
@export var is_reality: bool = false
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var radius

func _ready():
	if is_reality:
		PlayerManager.reality_level_changed.connect(on_level_changed)
	else:
		DmManager.fantasy_level_changed.connect(on_level_changed)
	radius = base_radius + PlayerManager.reality_level
	collision_shape_2d.shape.radius = radius

func _draw():
	draw_circle(Vector2.ZERO, radius, zone_color)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, zone_color.darkened(0.5), 2.0, true)

func _process(_delta):
	pass

func on_level_changed(new_level: int) -> void:
	radius = base_radius + new_level
	queue_redraw()
