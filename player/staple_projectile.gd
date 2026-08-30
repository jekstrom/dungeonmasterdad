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
	monitoring = true
	# Layer 0 + monitorable=false skips wall body overlap in Godot 4.7.
	monitorable = true
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	_origin = global_position
	if direction.length() < 0.001:
		direction = Vector2.RIGHT
	else:
		direction = direction.normalized()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	if _consumed:
		return
	if not _is_host():
		return
	if speed != 0.0:
		global_position += direction * speed * delta
	if global_position.distance_to(_origin) >= max_range:
		consume()
		return
	if _exited_map_interior():
		consume()
		return
	for body in get_overlapping_bodies():
		_on_body_entered(body)
		if _consumed:
			return

func _area_entered(area: Area2D) -> void:
	if _consumed:
		return
	if not (area is Hitbox):
		return
	var victim: Node = area.get_parent()
	if victim != null and str(victim.name) == str(shooter_id):
		return
	# T004: buildings take no staple damage (US-011 is goblin raids, not staples).
	if _is_building(victim):
		return
	# T004: Reality/Fantasy occupancy and overlapping zones must not cancel combat.
	if multiplayer.is_server():
		area.take_damage(self)
	consume()

func _on_body_entered(body: Node) -> void:
	if _consumed:
		return
	if body is StaticBody2D:
		consume()
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

func _is_host() -> bool:
	if not is_inside_tree() or multiplayer == null:
		return true
	return multiplayer.is_server()

func consume() -> void:
	if _consumed:
		return
	_consumed = true
	if area_entered.is_connected(_area_entered):
		area_entered.disconnect(_area_entered)
	if body_entered.is_connected(_on_body_entered):
		body_entered.disconnect(_on_body_entered)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	visible = false
	if not _is_host():
		return
	call_deferred("queue_free")
