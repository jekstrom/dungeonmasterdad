class_name Shadow extends Node2D


@export var texture: AtlasTexture
var trail_color: Color = Color(0.3, 0.3, 0.3, 0.7)
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var area_2d: Area2D = $Area2D

var debug = false
var enabled: bool = false
var player_id: int

func _ready() -> void:
	sprite_2d.z_index = -1
	area_2d.monitoring = false
	if multiplayer.is_server():
		area_2d.body_entered.connect(on_body_entered)

func _process(_delta: float) -> void:
	area_2d.monitoring = enabled
	sprite_2d.visible = true
	sprite_2d.modulate = trail_color
	sprite_2d.texture = texture
	if debug and !enabled:
		sprite_2d.modulate = Color.MAGENTA

func on_body_entered(_body) -> void:
	if not is_inside_tree() or is_queued_for_deletion() or not visible: return
	if not _body is Player: return
	
	if !has_meta("player_id"): 
		print("Shadow: FATAL - No player Id")
		assert(false)
		return
		
	# If first or second shadow, do not collide with trailing player
	TrailManager.handle_trail_death(int(_body.name), position)
