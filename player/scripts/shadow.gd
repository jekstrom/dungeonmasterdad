class_name Shadow extends Node2D


@export var texture: AtlasTexture
var trail_color: Color = Color(0.3, 0.3, 0.3, 0.7)
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var area_2d: Area2D = $Area2D

var debug = false
@export var enabled: bool = false
var player_id: int

func _ready() -> void:
	if sprite_2d:
		sprite_2d.z_index = 1
		sprite_2d.position = Vector2(0, -13)
		sprite_2d.visible = true
		sprite_2d.modulate = trail_color
		if texture:
			sprite_2d.texture = texture
	if area_2d:
		area_2d.monitoring = false
		area_2d.monitorable = false
		area_2d.collision_layer = 0
		area_2d.collision_mask = 1
		if Lobby.is_network_server():
			if not area_2d.body_entered.is_connected(on_body_entered):
				area_2d.body_entered.connect(on_body_entered)

func _process(_delta: float) -> void:
	if area_2d:
		area_2d.monitoring = enabled
	if sprite_2d:
		sprite_2d.visible = true
		sprite_2d.modulate = trail_color
		if texture:
			sprite_2d.texture = texture
		if debug and !enabled:
			sprite_2d.modulate = Color.MAGENTA

func on_body_entered(_body) -> void:
	if not is_inside_tree() or is_queued_for_deletion() or not visible:
		return
	if not enabled:
		return
	if not _body is Player:
		return
	if not has_meta("player_id"):
		return
	var owner_id: int = int(get_meta("player_id"))
	var victim_id: int = int(_body.name)
	if owner_id == victim_id:
		var segment_id := str(get_meta("id")) if has_meta("id") else ""
		if TrailManager.should_ignore_self_trail(owner_id, segment_id):
			return
	TrailManager.handle_trail_death(victim_id, position)
