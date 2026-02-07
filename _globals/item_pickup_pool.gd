extends Node

@export var pool_size: int = 100
var pool: Dictionary = {}
var pickup_scene: PackedScene
var total_pooled: int = 0

func _ready() -> void:
	pickup_scene = preload("res://pickups/pickup.tscn")

func get_pickup(item_path: String, position: Vector2, velocity: Vector2) -> Dictionary:
	if not pool.has(item_path):
		pool[item_path] = []
	
	var pickup_pool: Array = pool[item_path]
	
	if pickup_pool.size() > 0:
		var pickup = pickup_pool.pop_back()
		total_pooled -= 1
		_activate_pickup(pickup, item_path, position, velocity)
		return {"node": pickup, "is_pooled": true}
	
	return {"item_type": item_path, "position": position, "is_pooled": false}

func return_to_pool(pickup: Node) -> void:
	var item_path = pickup.item_data.resource_path if pickup.item_data else ""
	if item_path == "":
		pickup.queue_free()
		return
	
	if total_pooled >= pool_size:
		pickup.queue_free()
		return
	
	if not pickup.is_inside_tree():
		pickup.queue_free()
		return
	
	if not pool.has(item_path):
		pool[item_path] = []
	
	_deactivate_pickup(pickup)
	pool[item_path].push_back(pickup)
	total_pooled += 1

func _activate_pickup(pickup: Node, item_path: String, position: Vector2, velocity: Vector2) -> void:
	var item_data = ItemDatabase.get_item(item_path)
	pickup.item_data = item_data
	pickup.position = position
	pickup.velocity = velocity
	pickup.grace_time_remaining = 1.0
	pickup.can_be_picked_up = false
	pickup.visible = true
	pickup.collision_layer = 0
	pickup.collision_mask = 16
	if pickup.has_node("Area2D"):
		var area = pickup.get_node("Area2D")
		area.monitoring = true
		area.collision_layer = 1
		area.collision_mask = 1
		if not area.body_entered.is_connected(pickup.on_body_entered):
			area.body_entered.connect(pickup.on_body_entered)
	if multiplayer.is_server():
		_sync_pickup_activate.rpc(pickup.name, position, velocity)

func _deactivate_pickup(pickup: Node) -> void:
	if multiplayer.is_server():
		_sync_pickup_deactivate.rpc(pickup.name)
	pickup.visible = false
	pickup.collision_layer = 0
	pickup.collision_mask = 0
	if pickup.has_node("Area2D"):
		var area = pickup.get_node("Area2D")
		area.monitoring = false
		area.collision_layer = 0
		area.collision_mask = 0
		if area.body_entered.is_connected(pickup.on_body_entered):
			area.body_entered.disconnect(pickup.on_body_entered)
	pickup.velocity = Vector2.ZERO
	pickup.grace_time_remaining = 0.0
	pickup.can_be_picked_up = false
	pickup.position = Vector2(-10000, -10000)

@rpc("authority", "call_remote", "reliable")
func _sync_pickup_activate(pickup_name: String, position: Vector2, velocity: Vector2) -> void:
	var pickup = _find_pickup_by_name(pickup_name)
	if pickup and pickup.is_inside_tree():
		pickup.position = position
		pickup.velocity = velocity
		pickup.visible = true
		pickup.grace_time_remaining = 1.0
		pickup.can_be_picked_up = false

@rpc("authority", "call_remote", "reliable")
func _sync_pickup_deactivate(pickup_name: String) -> void:
	var pickup = _find_pickup_by_name(pickup_name)
	if pickup and pickup.is_inside_tree():
		pickup.visible = false
		pickup.position = Vector2(-10000, -10000)

func _find_pickup_by_name(pickup_name: String) -> Node:
	var scene_tree = get_tree()
	if not scene_tree or not scene_tree.current_scene:
		return null
	return scene_tree.current_scene.find_child(pickup_name, true, false)
