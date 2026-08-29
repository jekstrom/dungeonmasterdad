class_name StapleProjectile extends Hurtbox

@export var speed: float = 520.0
@export var max_range: float = 360.0

var shooter_id: int = 0
var direction: Vector2 = Vector2.RIGHT
var _origin: Vector2 = Vector2.ZERO
var _consumed: bool = false

func _ready() -> void:
	super._ready()
	add_to_group("staple_projectiles")
	collision_mask = collision_mask | 16
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	_origin = global_position
	if direction.length() < 0.001:
		direction = Vector2.RIGHT
	else:
		direction = direction.normalized()
	rotation = direction.angle()

func _process(delta: float) -> void:
	if _consumed:
		return
	global_position += direction * speed * delta
	if global_position.distance_to(_origin) >= max_range:
		consume()
		return
	if _exited_map_interior():
		consume()

func _area_entered(area: Area2D) -> void:
	if _consumed:
		return
	if not (area is Hitbox):
		return
	var victim: Node = area.get_parent()
	if victim != null and str(victim.name) == str(shooter_id):
		return
	if _is_building(victim):
		return
	if multiplayer.is_server():
		area.take_damage(self)
	consume()

func _on_body_entered(body: Node) -> void:
	if _consumed:
		return
	if body is CollisionObject2D and (body as CollisionObject2D).get_collision_layer_value(5):
		consume()

func _is_building(node: Node) -> bool:
	var n: Node = node
	while n:
		if n is Building:
			return true
		n = n.get_parent()
	return false

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
	return true

func consume() -> void:
	if _consumed:
		return
	_consumed = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	queue_free()
