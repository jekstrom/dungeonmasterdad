class_name FireballSpell extends Area2D

@export var radius: float = 100.0
@export var base_damage: int = 5
@export var speed: float = 565

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var explosion: Sprite2D = $Explosion
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var shooter_id: int
var target: Vector2
var exploding: bool = false

func _ready() -> void:
	explosion.visible = false
	collision_mask = collision_mask | 16
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	look_at(target)
	
func _process(_delta: float) -> void:
	if exploding: return
	if target:
		position = global_position.move_toward(target, speed * _delta)

	if _exited_map_interior():
		explode()
		return
	if global_position.distance_to(target) <= 0.01:
		sprite_2d.visible = false
		explode()
	
func set_target(pos: Vector2) -> void:
	target = pos

func _on_body_entered(body: Node) -> void:
	if exploding:
		return
	if body is CollisionObject2D and (body as CollisionObject2D).get_collision_layer_value(5):
		explode()

func _exited_map_interior() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	var level: Node = tree.get_first_node_in_group("level_manager")
	if level == null or not level.has_method("has_map_bounds") or not level.has_map_bounds():
		return false
	var bounds: MapBounds = level.get_map_bounds()
	if bounds.is_world_position_walkable(global_position):
		return false
	global_position = bounds.clamp_world_to_interior(global_position)
	return true

func explode() -> void:
	if exploding: return
	exploding = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	collision_shape_2d.set_deferred("disabled", true)
	_apply_explosion_scale()
	animation_player.play("explode")
	
	if multiplayer.is_server():
		var explosion_data = {
			"type": "fire",
			"damage": base_damage,
			"radius": radius,
		}
		SignalBus.on_explosion.emit(position, explosion_data)
	
	await animation_player.animation_finished
	queue_free()


func _apply_explosion_scale() -> void:
	var visual: float = 1.0
	if radius > 0.0:
		visual = radius / 100.0
	if explosion:
		explosion.scale = Vector2(visual, visual)
	var particles: Node = get_node_or_null("GPUParticles2D")
	if particles is Node2D:
		(particles as Node2D).scale = Vector2(visual, visual)
