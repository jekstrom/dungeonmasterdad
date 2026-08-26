extends Node2D

var damage_numbers_scene: PackedScene = preload("res://spells/damage_number.tscn")
var is_shadow_zone: bool = false
var generated_dungeon_container: Node2D = null

# Live dungeon stays until a replacement fully succeeds (swap-on-success).
var _live_generated_nodes: Array[Node] = []
var _staged_generated_nodes: Array[Node] = []

# Handle global level-based events such as projectiles

func _ready() -> void:
	if not is_in_group("level_manager"):
		add_to_group("level_manager")

	if !SignalBus.on_explosion.is_connected(on_explosion):
		SignalBus.on_explosion.connect(on_explosion)
	
	# Set up periodic cleanup of invalid nodes to prevent RPC errors
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 5.0  # Clean up every 5 seconds
	cleanup_timer.timeout.connect(_periodic_cleanup)
	cleanup_timer.autostart = true
	add_child(cleanup_timer)

func on_explosion(proj_position: Vector2, explosion_data: Dictionary) -> void:
	if !multiplayer.is_server(): return
	explosion_data["position"] = proj_position
	handle_explosion(explosion_data)

func handle_explosion(explosion_data: Dictionary) -> void:
	if !multiplayer.is_server(): return
	for player_id in PlayerManager.players_data.keys():
		var player_node = get_node_or_null(str(player_id)) as Node2D
		if !player_node or !player_node is Player: continue
		if player_node.position.distance_to(explosion_data.position) <= explosion_data.radius:
			print("player ", player_id, " hit!")
			if explosion_data.damage:
				show_damage_number.rpc(explosion_data.damage, player_node.global_position, player_node.sync_color)
				PlayerManager.update_reality_level(-explosion_data.damage)

@rpc("any_peer", "call_local", "reliable")
func show_damage_number(damage: int, spawn_pos: Vector2, color: Color):
	var dmg_numbers = damage_numbers_scene.instantiate() as Node2D
	dmg_numbers.global_position = spawn_pos
	dmg_numbers.get_node("DamageNumber").text = str(damage)
	dmg_numbers.get_node("DamageNumber").self_modulate = color
	get_tree().current_scene.add_child(dmg_numbers)

func _periodic_cleanup():
	"""Periodic cleanup to prevent RPC errors on deleted nodes"""
	if multiplayer.is_server():
		# Clean up any pickup spawners' invalid references
		var pickup_spawners = get_tree().get_nodes_in_group("multiplayer_pickup_spawner")
		for spawner in pickup_spawners:
			if spawner.has_method("cleanup_invalid_pickups"):
				spawner.cleanup_invalid_pickups()

func begin_generated_dungeon_stage() -> void:
	if not multiplayer.is_server():
		return
	_free_node_list(_staged_generated_nodes)
	_staged_generated_nodes.clear()

func register_staged_generated_node(node: Node) -> void:
	if node == null:
		return
	_staged_generated_nodes.append(node)

func commit_generated_dungeon_stage() -> void:
	if not multiplayer.is_server():
		return
	# Only discard the last good dungeon after the replacement is fully spawned.
	_free_node_list(_live_generated_nodes)
	_live_generated_nodes = _staged_generated_nodes.duplicate()
	_staged_generated_nodes.clear()
	generated_dungeon_container = _first_valid_node(_live_generated_nodes)

func rollback_generated_dungeon_stage() -> void:
	if not multiplayer.is_server():
		return
	_free_node_list(_staged_generated_nodes)
	_staged_generated_nodes.clear()

func replace_generated_dungeon_container(new_container: Node2D) -> void:
	if not multiplayer.is_server():
		return
	# Do not wipe the live dungeon unless a replacement node exists.
	if not new_container:
		return
	begin_generated_dungeon_stage()
	if new_container.get_parent():
		new_container.get_parent().remove_child(new_container)
	get_tree().current_scene.add_child(new_container)
	register_staged_generated_node(new_container)
	commit_generated_dungeon_stage()

func clear_generated_dungeon_container() -> void:
	if not multiplayer.is_server():
		return
	_free_node_list(_live_generated_nodes)
	_free_node_list(_staged_generated_nodes)
	_live_generated_nodes.clear()
	_staged_generated_nodes.clear()
	if generated_dungeon_container and is_instance_valid(generated_dungeon_container):
		generated_dungeon_container.queue_free()
	generated_dungeon_container = null

func _first_valid_node(nodes: Array[Node]) -> Node2D:
	for node in nodes:
		if node and is_instance_valid(node) and node is Node2D:
			return node
	return null

func _free_node_list(nodes: Array[Node]) -> void:
	for node in nodes:
		if node and is_instance_valid(node):
			node.queue_free()
