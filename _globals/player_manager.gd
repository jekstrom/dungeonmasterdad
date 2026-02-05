extends Node

#const __DM__ = preload("uid://e1aypo2ysyyc")
#const INVENTORY_DATA: InventoryData = preload("res://gui/pause_menu/inventory/player_inventory.tres")

#signal interact_pressed

var player: Player
var player_spawned: bool = false

@export var max_inv_slots: int = 8
@export var reality_level: int = 0
signal reality_level_changed(new_reality_level: int)

# Structure: { peer_id: { "inventory": { "item_id": quantity } } }
var players_data = {}

func _ready() -> void:
	add_player_instance()
	await get_tree().create_timer(0.2).timeout
	player_spawned = true
	
func register_player(id: int, player_name: String):
	if not multiplayer.is_server(): return
	
	if !player_name or player_name.is_empty():
		player_name = "Paper Pusher"
	
	# Initialize empty data for new player
	players_data[id] = {
		"inventory": {},
		"name": player_name,
	}
	print("Player ", id, " registered in Global Manager with name ", player_name)

func unregister_player(id: int):
	if multiplayer.is_server() and players_data.has(id):
		print("Unregistering player ", id, " - cleaning up all data")
		
		# Clean up any trails for disconnecting player
		TrailManager.cleanup_player_trail(id)
		
		# Clean up server trail tracking if in snake mode
		var players = get_tree().get_nodes_in_group("players")
		for player_node in players:
			if player_node.name.is_valid_int() and int(player_node.name) == id:
				var state_machine = player_node.get_node_or_null("PlayerStateMachine")
				if state_machine and state_machine.current_state and state_machine.current_state.name == "snake":
					# Player was in snake mode, clean up server tracking
					if player_node.get_script() and player_node.get_script().has_method("stop_server_trail_tracking"):
						var snake_state = state_machine.current_state
						if snake_state.has_method("stop_server_trail_tracking"):
							snake_state.stop_server_trail_tracking(id)
		
		# Optional: Save to disk here before erasing
		players_data.erase(id)
		print("Player ", id, " fully unregistered and cleaned up")
		
func add_item_to_inventory(player_id: int, item_data: ItemData, amount: int = 1):
	if not multiplayer.is_server(): return
	if !players_data.has(player_id): return
	
	var item_id = item_data.resource_path
	
	var inventory = players_data[player_id]["inventory"]

	if inventory.keys().size() < max_inv_slots:
		if inventory.has(item_id):
			inventory[item_id] += amount
		else:
			inventory[item_id] = amount
		# Sync the entire inventory dictionary to the specific client
		update_client_inventory.rpc_id(player_id, inventory)
		SignalBus.on_item_pickup.emit()

@rpc("authority", "call_local", "reliable")
func update_client_inventory(new_items: Dictionary):
	var display_list = []
	for id in new_items.keys():
		var resource = ItemDatabase.get_item(id)
		if resource:
			var quantity = new_items[id]
			display_list.append({"data": resource, "quantity": quantity})
	
	SignalBus.emit_signal("inventory_updated", display_list)

@rpc("authority", "reliable")
func has_resources(player_id, resource_id, cost) -> bool:
	if not multiplayer.is_server(): 
		return false
	if !players_data.has(player_id): 
		return false
	
	var inventory = players_data[player_id]["inventory"]
	if !inventory.has(resource_id):
		return false
	var x = inventory[resource_id] >= cost
	print("player has resources? ", x)
	return x
	
@rpc("authority", "reliable")
func consume_resources(player_id, resource_id, cost) -> void:
	if not multiplayer.is_server(): 
		return
	if !players_data.has(player_id): 
		return
			
	var inventory = players_data[player_id]["inventory"]
	inventory[resource_id] -= cost
	update_client_inventory.rpc_id(player_id, inventory)

# Drop all inventory items on the ground at specified position
func drop_all_inventory(player_id: int, drop_position: Vector2) -> void:
	if not multiplayer.is_server():
		print("WARNING: drop_all_inventory called on non-server")
		return
	if not players_data.has(player_id):
		print("WARNING: drop_all_inventory called for non-existent player ", player_id)
		return
	
	var player_data = players_data[player_id]
	if not player_data.has("inventory"):
		print("WARNING: Player ", player_id, " has no inventory data")
		return
		
	var inventory = player_data["inventory"]
	if inventory.is_empty():
		print("Player ", player_id, " has no items to drop")
		return
	
	print("Dropping ", inventory.size(), " item types for player ", player_id, " at ", drop_position)
	
	# Get the world node to spawn items in
	var world_node = get_tree().current_scene
	if not world_node:
		print("ERROR: Could not find world node to drop items in")
		return
	
	# Drop each item type in inventory
	for item_resource_path in inventory.keys():
		var quantity = inventory[item_resource_path]
		var item_data = ItemDatabase.get_item(item_resource_path)
		
		if not item_data:
			print("ERROR: Could not load item data for ", item_resource_path)
			continue
		
		# Create individual pickups for each item (or stacks if quantity > 1)
		create_dropped_item_pickups(world_node, item_data, quantity, drop_position)
	
	# Clear the player's inventory
	inventory.clear()
	update_client_inventory.rpc_id(player_id, inventory)
	print("Player ", player_id, " inventory cleared after dropping items")
	
	# Emit signal for other systems
	SignalBus.inventory_dropped.emit(player_id, drop_position)

# Create pickup items for dropped inventory using MultiplayerSpawner for proper sync
func create_dropped_item_pickups(world_node: Node, item_data: ItemData, quantity: int, center_position: Vector2) -> void:
	print("DEBUG: Creating ", quantity, " pickups for ", item_data.name, " at ", center_position)
	
	# Try to find and use MultiplayerSpawner for synchronized pickup creation
	# Use multiple lookup strategies to ensure we find the spawner
	var spawner = null
	
	# Strategy 1: Direct child lookup
	spawner = world_node.get_node_or_null("MultiplayerSpawner")
	
	# Strategy 2: Search in tree if not found as direct child
	if not spawner:
		spawner = get_tree().get_first_node_in_group("multiplayer_spawner")
	
	# Strategy 3: Find by class name if group not found
	if not spawner:
		var nodes = get_tree().get_nodes_in_group("multiplayer_spawners")
		for node in nodes:
			if node.has_method("spawn_pickup_item"):
				spawner = node
				break
	
	# Strategy 4: Search entire tree as last resort
	if not spawner:
		spawner = _find_multiplayer_spawner_recursive(get_tree().root)
	
	var use_spawner = spawner != null and spawner.has_method("spawn_pickup_item")
	
	if use_spawner:
		print("DEBUG: Using MultiplayerSpawner for synchronized pickup creation")
		print("DEBUG: Found spawner: ", spawner, " with scene path: ", spawner.get_path())
	else:
		print("WARNING: MultiplayerSpawner not available, using fallback direct creation")
		print("DEBUG: This means pickups will only appear on server!")
		print("DEBUG: Current scene: ", world_node, " path: ", world_node.get_path())
		var child_names = []
		for child in world_node.get_children():
			child_names.append(child.name)
		print("DEBUG: Current scene children: ", child_names)
	
	# Limit maximum drops to prevent performance issues
	var max_drops = min(quantity, 50)  # Cap at 50 individual items
	if quantity > max_drops:
		print("WARNING: Capping drop quantity from ", quantity, " to ", max_drops, " for performance")
	
	# Create pickups with scattered positions and random velocities
	for i in range(max_drops):
		# Calculate scattered position (random offset from center)
		var scatter_radius = 40.0 + (i * 2.0)  # Slightly increase radius for each item
		var angle = randf() * TAU  # Random angle
		var distance = randf() * scatter_radius  # Random distance within radius
		var offset = Vector2(cos(angle), sin(angle)) * distance
		var pickup_position = center_position + offset
		
		# Add random velocity for physics scatter effect
		var velocity_strength = randf_range(80.0, 200.0)
		var velocity_angle = randf() * TAU
		var pickup_velocity = Vector2(cos(velocity_angle), sin(velocity_angle)) * velocity_strength
		
		var pickup = null
		
		if use_spawner:
			# Try MultiplayerSpawner first
			pickup = spawner.spawn_pickup_item(item_data, pickup_position, pickup_velocity)
			if pickup:
				print("SUCCESS: Created synced pickup for ", item_data.name, " (#", i+1, "/", max_drops, ")")
			else:
				print("ERROR: MultiplayerSpawner failed to create pickup, falling back to direct creation")
		
		# Fallback to direct creation if spawner failed or not available
		if not pickup:
			const PICKUP_SCENE_PATH = "res://pickups/pickup.tscn"
			var pickup_scene = load(PICKUP_SCENE_PATH)
			
			if pickup_scene:
				pickup = pickup_scene.instantiate()
				if pickup:
					pickup.item_data = item_data
					pickup.global_position = pickup_position
					pickup.velocity = pickup_velocity
					
					# Add to world directly (server-only, not synced)
					# Use 'true' parameter to prevent reserved name conflicts in multiplayer
					world_node.add_child(pickup, true)
					print("FALLBACK: Created server-only pickup for ", item_data.name, " (#", i+1, "/", max_drops, ")")
				else:
					print("ERROR: Failed to instantiate pickup scene")
			else:
				print("ERROR: Failed to load pickup scene from ", PICKUP_SCENE_PATH)
	
func add_player_instance() -> void:
	pass
	#dm = __DM__.instantiate()
	#add_child(player)

func set_player_pos(new_pos: Vector2) -> void:
	player.global_position = new_pos

func set_player_health(hp: int, max_hp: int) -> void:
	player.max_hp = max_hp
	player.hitpoints = hp
	#DmHud.update_hp(hp, max_hp)

func set_as_parent(p: Node2D) -> void:
	if player.get_parent():
		player.get_parent().remove_child(player)
	p.add_child(player)

func unparent_player(p: Node2D) -> void:
	p.remove_child(player)

func update_reality_level(level_inc: int) -> void:
	if multiplayer.is_server():
		reality_level += level_inc
		request_reality_level_incrase.rpc(reality_level)

@rpc("authority", "call_local", "reliable")
func request_reality_level_incrase(new_reality_level: int):
		reality_level = new_reality_level
		reality_level_changed.emit(new_reality_level)

# Respawn a player at the starting location with a delay
func respawn_player(player_id: int) -> void:
	if not multiplayer.is_server():
		print("WARNING: respawn_player called on non-server")
		return
	
	# Get the player node
	var player_node = get_player_node_by_id(player_id)
	if not player_node:
		print("ERROR: Could not find player node for respawn: ", player_id)
		return
	
	print("Scheduling respawn for player ", player_id, " in 2 seconds...")
	
	# Add a 2-second delay before respawn for dramatic effect
	await get_tree().create_timer(2.0).timeout
	
	# Double-check player still exists after delay
	player_node = get_player_node_by_id(player_id)
	if not player_node:
		print("ERROR: Player node disappeared during respawn delay: ", player_id)
		return
	
	# Get respawn position (near Reality Zone center)
	var respawn_position = get_respawn_position()
	
	print("Respawning player ", player_id, " at ", respawn_position)
	
	# Reset player position
	player_node.global_position = respawn_position
	
	# Reset player health
	player_node.hitpoints = player_node.max_hp
	
	# Reset player state to idle (exit snake mode if active)
	if player_node.has_method("force_idle_state"):
		player_node.force_idle_state()
	elif player_node.has_node("PlayerStateMachine"):
		var state_machine = player_node.get_node("PlayerStateMachine")
		if state_machine.has_method("force_change_state"):
			var idle_state = state_machine.get_node_or_null("idle")
			if idle_state:
				state_machine.force_change_state(idle_state)
	
	# Notify all clients of the respawn
	notify_player_respawned.rpc(player_id, respawn_position)
	
	# Emit signal for other systems
	SignalBus.player_respawned.emit(player_id, respawn_position)

# Get a player node by ID (similar to snake state function but in manager)
func get_player_node_by_id(pid: int) -> Node:
	var world_node = get_tree().current_scene
	if not world_node:
		return null
	
	# Try direct name lookup first (most common case)
	var player_node = world_node.get_node_or_null(str(pid))
	if player_node:
		return player_node
	
	# Fallback to searching all players in group
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player.name.is_valid_int() and int(player.name) == pid:
			return player
		elif player.has_method("get_player_id") and player.get_player_id() == pid:
			return player
		elif "player_id" in player and player.player_id == pid:
			return player
	
	return null

# Get the respawn position (near Reality Zone)
func get_respawn_position() -> Vector2:
	var world_node = get_tree().current_scene
	if not world_node:
		return Vector2(183, 74)  # Fallback to Reality Zone center
	
	# Try to find Reality Zone
	var reality_zone = world_node.get_node_or_null("RealityZone")
	if reality_zone:
		# Spawn at Reality Zone center with small random offset
		var center_pos = reality_zone.global_position
		var random_offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		return center_pos + random_offset
	
	# Fallback position near Reality Zone
	return Vector2(183, 74)

@rpc("authority", "call_local", "reliable")
func notify_player_respawned(player_id: int, respawn_position: Vector2) -> void:
	print("Player ", player_id, " respawned at ", respawn_position)

# Helper function to recursively find MultiplayerSpawner in the scene tree
func _find_multiplayer_spawner_recursive(node: Node) -> Node:
	# Check if current node is a MultiplayerSpawner with spawn_pickup_item method
	if node.get_class() == "MultiplayerSpawner" and node.has_method("spawn_pickup_item"):
		return node
	
	# Search children recursively
	for child in node.get_children():
		var result = _find_multiplayer_spawner_recursive(child)
		if result:
			return result
	
	return null
