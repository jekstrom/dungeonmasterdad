extends Node

# Death system configuration constants
const RESPAWN_DELAY: float = 3.0
const MIN_RESPAWN_DELAY: float = 2.0
const MAX_RESPAWN_DELAY: float = 10.0
const MAX_DEATH_REQUESTS_PER_SECOND: float = 0.2  # One every 5 seconds
const RESPAWN_COUNTDOWN_UPDATE_INTERVAL: float = 0.5  # Update countdown every 0.5s

# Active tracking dictionaries
var active_death_timers: Dictionary = {}  # player_id -> Timer
var player_death_cooldowns: Dictionary = {}  # player_id -> last_death_time
var respawn_reservations: Dictionary = {}  # player_id -> spawn_point data
var respawn_countdown_timers: Dictionary = {}  # player_id -> countdown Timer

# Preloaded scenes
@onready var pickup_scene: PackedScene = preload("res://pickups/pickup.tscn")

func _ready():
	# Connect to SignalBus for loose coupling
	SignalBus.player_death_requested.connect(_on_death_requested)

# =============================================================================
# CLIENT → SERVER RPCs
# =============================================================================

@rpc("any_peer", "call_remote", "reliable")
func request_player_death(death_position: Vector2, cause: String = "") -> void:
	# Only server processes death requests
	if not multiplayer.is_server():
		return
	
	var player_id: int = multiplayer.get_remote_sender_id()
	
	# Validate death request
	if not _validate_death_request(player_id, death_position):
		print("DeathSystem: Invalid death request from player ", player_id)
		return
	
	# Process the death
	_handle_player_death(player_id, death_position, cause)



# =============================================================================
# SERVER → CLIENT RPCs
# =============================================================================

@rpc("authority", "call_local", "reliable")
func notify_player_death(player_id: int, death_position: Vector2, death_time: float) -> void:
	# Emit signal for local systems to handle
	SignalBus.player_death_processed.emit(player_id, [])
	print("DeathSystem: Player ", player_id, " died at position ", death_position)

@rpc("authority", "call_local", "reliable") 
func notify_items_dropped(items_data: Array, spawn_position: Vector2) -> void:
	print("DeathSystem: ", items_data.size(), " items dropped at ", spawn_position)
	# Emit signal for other systems (like UI notifications)
	SignalBus.items_dropped_at_location.emit(items_data, spawn_position)

@rpc("authority", "call_remote", "reliable")
func notify_player_respawn_delay(delay_duration: float, spawn_position: Vector2) -> void:
	# Client receives respawn delay notification
	SignalBus.player_respawn_delay_started.emit(multiplayer.get_remote_sender_id(), delay_duration)
	print("DeathSystem: Respawn delay of ", delay_duration, "s started. Will respawn at ", spawn_position)

@rpc("authority", "call_local", "reliable")
func notify_player_respawned(player_id: int, respawn_position: Vector2, respawn_time: float) -> void:
	# Broadcast player respawn to all clients
	SignalBus.player_respawn_completed.emit(player_id, respawn_position)
	
	# Clean up tracking data
	if player_id in active_death_timers:
		active_death_timers[player_id].queue_free()
		active_death_timers.erase(player_id)
	
	# Clean up countdown timer
	_cleanup_countdown_timer(player_id)
	
	respawn_reservations.erase(player_id)
	print("DeathSystem: Player ", player_id, " respawned at ", respawn_position)

# =============================================================================
# PRIVATE SERVER-SIDE PROCESSING METHODS
# =============================================================================

func _validate_death_request(player_id: int, death_position: Vector2) -> bool:
	# Check death cooldown to prevent spam
	var current_time = Time.get_time_dict_from_system()
	var current_timestamp = current_time.hour * 3600 + current_time.minute * 60 + current_time.second
	
	if player_id in player_death_cooldowns:
		var last_death_time = player_death_cooldowns[player_id]
		if current_timestamp - last_death_time < (1.0 / MAX_DEATH_REQUESTS_PER_SECOND):
			return false
	
	# TODO: Add more validation
	# - Check if player is actually alive and in snake-mode
	# - Validate death_position is reasonable for player location
	# - Check if player is not already in death processing
	
	return true



func _handle_player_death(player_id: int, death_position: Vector2, cause: String) -> void:
	var death_time: float = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	
	# Update death cooldown
	player_death_cooldowns[player_id] = death_time
	
	# Broadcast death event to all clients
	notify_player_death.rpc(player_id, death_position, death_time)
	
	# Extract and drop player inventory
	var dropped_items = _extract_player_inventory(player_id)
	if dropped_items.size() > 0:
		_create_dropped_items(dropped_items, death_position)
	
	# Start respawn delay timer
	_start_respawn_delay(player_id)



func _extract_player_inventory(player_id: int) -> Array:
	"""Extract inventory items from player for dropping as regular pickups"""
	var items_to_drop: Array = []
	
	# Extract items directly from PlayerManager's inventory system
	if not PlayerManager.players_data.has(player_id):
		print("DeathSystem: Player ", player_id, " not found in PlayerManager")
		return items_to_drop
	
	var player_data = PlayerManager.players_data[player_id]
	if not player_data.has("inventory"):
		print("DeathSystem: Player ", player_id, " has no inventory in PlayerManager")
		return items_to_drop
	
	var inventory_dict = player_data["inventory"]
	if inventory_dict.is_empty():
		print("DeathSystem: Player ", player_id, " inventory is empty")
		return items_to_drop
	
	# Convert PlayerManager inventory to ItemData format for pickup spawning
	for item_resource_path in inventory_dict.keys():
		var quantity = inventory_dict[item_resource_path]
		var item_data = ItemDatabase.get_item(item_resource_path)
		
		if item_data and quantity > 0:
			# Create one pickup per quantity (could be optimized with stacking later)
			for i in range(quantity):
				items_to_drop.append(item_data)
	
	# Clear the PlayerManager inventory
	inventory_dict.clear()
	PlayerManager.update_client_inventory.rpc_id(player_id, inventory_dict)
	
	print("DeathSystem: Extracted ", items_to_drop.size(), " items from PlayerManager for player ", player_id)
	return items_to_drop

func _get_player_node(player_id: int) -> Player:
	"""Find player node by multiplayer ID"""
	# Look for player in current scene
	var scene_tree = get_tree()
	if scene_tree == null:
		return null
	
	var current_scene = scene_tree.current_scene
	if current_scene == null:
		return null
	
	# Search for player with matching ID
	var players = current_scene.find_children("*", "Player", true, false)
	for player_node in players:
		if player_node.get_multiplayer_authority() == player_id:
			return player_node
	
	# Alternative: try by node name (common pattern)
	var player_by_name = current_scene.get_node_or_null(str(player_id))
	if player_by_name and player_by_name is Player:
		return player_by_name
	
	return null



func _create_dropped_items(items_data: Array, spawn_position: Vector2) -> void:
	# Use proper multiplayer spawning instead of manual client-side spawning
	_spawn_items_via_multiplayer_spawner(items_data, spawn_position)
	print("DeathSystem: Spawning ", items_data.size(), " pickup items via MultiplayerSpawner")

func _start_respawn_delay(player_id: int) -> void:
	# Get player's death position for spawn selection context
	var player_node = _get_player_node(player_id)
	var death_position = player_node.global_position if player_node else Vector2.ZERO
	
	# Select spawn point from reality zone
	var spawn_position = _select_respawn_location(player_id, death_position)
	
	# Reserve the spawn point
	respawn_reservations[player_id] = {
		"spawn_position": spawn_position,
		"reserved_time": _get_current_time()
	}
	
	# Send delay notification to specific client
	notify_player_respawn_delay.rpc_id(player_id, RESPAWN_DELAY, spawn_position)
	
	# Create server-side respawn timer
	var delay_timer = Timer.new()
	delay_timer.wait_time = RESPAWN_DELAY
	delay_timer.one_shot = true
	delay_timer.timeout.connect(_respawn_player.bind(player_id))
	add_child(delay_timer)
	delay_timer.start()
	
	active_death_timers[player_id] = delay_timer
	
	# Create countdown update timer for progress notifications
	_start_respawn_countdown_updates(player_id)

func _select_respawn_location(player_id: int, death_position: Vector2) -> Vector2:
	"""Select the best respawn location for a player"""
	
	# Try to find a reality zone
	var reality_zone = _find_reality_zone()
	if reality_zone == null:
		print("DeathSystem: No reality zone found, using fallback position")
		return Vector2.ZERO
	
	# Get spawn position from reality zone
	var spawn_position = Vector2.ZERO
	
	# Check if zone has advanced spawn point management
	if reality_zone.has_method("reserve_spawn_point_for_player"):
		spawn_position = reality_zone.reserve_spawn_point_for_player(player_id)
	else:
		# Fallback to zone center with small random offset
		spawn_position = reality_zone.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	
	# Validate spawn position if zone supports validation
	if reality_zone.has_method("is_position_within_zone"):
		if not reality_zone.is_position_within_zone(spawn_position):
			print("DeathSystem: WARNING - Spawn position outside reality zone, using zone center")
			spawn_position = reality_zone.global_position
	else:
		# Ensure spawn is within radius for basic Zone
		var distance_to_center = reality_zone.global_position.distance_to(spawn_position)
		if distance_to_center > reality_zone.radius:
			spawn_position = reality_zone.global_position
	
	print("DeathSystem: Selected respawn position ", spawn_position, " for player ", player_id)
	return spawn_position

# =============================================================================
# RESPAWN COUNTDOWN MANAGEMENT (User Story 3)
# =============================================================================

func _start_respawn_countdown_updates(player_id: int) -> void:
	"""Start periodic countdown updates for a respawning player"""
	var countdown_timer = Timer.new()
	countdown_timer.wait_time = RESPAWN_COUNTDOWN_UPDATE_INTERVAL
	countdown_timer.timeout.connect(_send_countdown_update.bind(player_id))
	add_child(countdown_timer)
	countdown_timer.start()
	
	respawn_countdown_timers[player_id] = countdown_timer

func _send_countdown_update(player_id: int) -> void:
	"""Send countdown update to specific player"""
	if not player_id in active_death_timers:
		# Respawn completed, clean up countdown timer
		_cleanup_countdown_timer(player_id)
		return
	
	var respawn_timer = active_death_timers[player_id]
	if not is_instance_valid(respawn_timer):
		_cleanup_countdown_timer(player_id)
		return
	
	var remaining_time = respawn_timer.time_left
	
	if remaining_time <= 0:
		# Respawn about to happen, clean up countdown
		_cleanup_countdown_timer(player_id)
		return
	
	# Send countdown update to client
	notify_respawn_countdown_update.rpc_id(player_id, remaining_time)

func _cleanup_countdown_timer(player_id: int) -> void:
	"""Clean up countdown update timer for a player"""
	if player_id in respawn_countdown_timers:
		var countdown_timer = respawn_countdown_timers[player_id]
		if is_instance_valid(countdown_timer):
			countdown_timer.queue_free()
		respawn_countdown_timers.erase(player_id)

func get_respawn_delay_for_player(player_id: int) -> float:
	"""Get configured respawn delay (could be dynamic based on player/conditions)"""
	# For now, use constant delay
	# Could be enhanced with:
	# - Longer delays for repeated deaths
	# - Shorter delays for new players
	# - Variable delays based on game state
	return RESPAWN_DELAY

func set_respawn_delay_for_player(player_id: int, new_delay: float) -> void:
	"""Set custom respawn delay for a player (admin/debug feature)"""
	var clamped_delay = clamp(new_delay, MIN_RESPAWN_DELAY, MAX_RESPAWN_DELAY)
	
	if player_id in active_death_timers:
		var timer = active_death_timers[player_id]
		if is_instance_valid(timer):
			timer.wait_time = clamped_delay
			print("DeathSystem: Updated respawn delay for player ", player_id, " to ", clamped_delay, "s")

func force_respawn_player(player_id: int) -> void:
	"""Force immediate respawn (admin/debug feature)"""
	if player_id in active_death_timers:
		var timer = active_death_timers[player_id]
		if is_instance_valid(timer):
			timer.timeout.emit()  # Trigger immediate respawn
			print("DeathSystem: Forced immediate respawn for player ", player_id)

# =============================================================================
# ADDITIONAL SERVER → CLIENT RPCS FOR USER STORY 3
# =============================================================================

@rpc("authority", "call_remote", "unreliable")
func notify_respawn_countdown_update(remaining_time: float) -> void:
	"""Send respawn countdown update to client"""
	# Client can handle this for UI updates
	var player_id = multiplayer.get_remote_sender_id()
	SignalBus.player_respawn_delay_started.emit(player_id, remaining_time)  # Reuse existing signal

func _find_multiplayer_spawner() -> Node:
	"""Find the MultiplayerSpawner in the scene"""
	var scene_tree = get_tree()
	if scene_tree == null:
		return null
	
	var current_scene = scene_tree.current_scene
	if current_scene == null:
		return null
	
	# Look for MultiplayerSpawner by group (added in multiplayer_spawner.gd)
	var spawners = current_scene.get_nodes_in_group("multiplayer_spawner")
	if spawners.size() > 0:
		return spawners[0]
	
	# Fallback: search by type
	var spawner = current_scene.find_child("MultiplayerSpawner", true, false)
	if spawner:
		return spawner
	
	return null

func _find_reality_zone() -> Zone:
	"""Find the first available reality zone in the scene"""
	var scene_tree = get_tree()
	if scene_tree == null:
		return null
	
	var current_scene = scene_tree.current_scene
	if current_scene == null:
		return null
	
	# Look for RealityZone nodes by name
	var reality_zone = current_scene.find_child("RealityZone", true, false)
	if reality_zone and reality_zone is Zone:
		return reality_zone
	
	# Fallback: look for any Zone with is_reality = true
	var zones = current_scene.find_children("*", "Zone", true, false)
	for zone in zones:
		if zone.get("is_reality") == true:
			return zone
	
	return null

func _respawn_player(player_id: int) -> void:
	# Get reserved spawn position
	var respawn_position = Vector2.ZERO
	if player_id in respawn_reservations:
		respawn_position = respawn_reservations[player_id].get("spawn_position", Vector2.ZERO)
	else:
		# Fallback if no reservation found
		respawn_position = _select_respawn_location(player_id, Vector2.ZERO)
	
	var respawn_time = _get_current_time()
	
	# Move player to respawn position on server
	var player_node = _get_player_node(player_id)
	if player_node:
		player_node.global_position = respawn_position
		
		# Force player to idle state after respawn
		if player_node.has_method("force_idle_state"):
			player_node.force_idle_state()
	
	# Broadcast respawn to all clients
	notify_player_respawned.rpc(player_id, respawn_position, respawn_time)

func _spawn_items_via_multiplayer_spawner(items_data: Array, spawn_position: Vector2) -> void:
	"""Spawn pickup items using proper MultiplayerSpawner (server-side only)"""
	if not multiplayer.is_server():
		print("DeathSystem: WARNING - _spawn_items_via_multiplayer_spawner called on client")
		return
	
	# Find the multiplayer spawner in the scene
	var multiplayer_spawner = _find_multiplayer_spawner()
	if multiplayer_spawner == null:
		print("DeathSystem: ERROR - Could not find MultiplayerSpawner to spawn items")
		# Fallback: broadcast to clients for manual spawning (old behavior)
		notify_items_dropped.rpc(items_data, spawn_position)
		return
	
	# Spawn each item via the proper multiplayer spawner
	for item_data in items_data:
		if item_data == null or not (item_data is ItemData):
			print("DeathSystem: Invalid item_data, skipping spawn")
			continue
		
		# Calculate spread position for multiple items
		var spread_offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
		var item_spawn_position = spawn_position + spread_offset
		
		# Add small velocity for visual effect
		var velocity = Vector2(randf_range(-50, 50), randf_range(-50, 50))
		
		# Use MultiplayerSpawner's proper method - this handles all the networking
		var spawned_pickup = multiplayer_spawner.spawn_pickup_item(item_data, item_spawn_position, velocity)
		
		if spawned_pickup:
			print("DeathSystem: Spawned pickup ", item_data.name, " at ", item_spawn_position, " via MultiplayerSpawner")
		else:
			print("DeathSystem: Failed to spawn pickup ", item_data.name)
	
	# Broadcast notification for UI/sound effects
	notify_items_dropped.rpc(items_data, spawn_position)

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_death_requested(player_id: int, position: Vector2) -> void:
	# Handle death request from signal system
	if multiplayer.is_server():
		_handle_player_death(player_id, position, "signal_triggered")



func _get_current_time() -> float:
	"""Get current timestamp in seconds"""
	var time_dict = Time.get_time_dict_from_system()
	return float(time_dict.hour * 3600 + time_dict.minute * 60 + time_dict.second)

# =============================================================================
# CLEANUP AND UTILITIES
# =============================================================================

func _exit_tree() -> void:
	# Clean up all active timers
	for timer in active_death_timers.values():
		if is_instance_valid(timer):
			timer.queue_free()
	
	# Clean up countdown timers
	for timer in respawn_countdown_timers.values():
		if is_instance_valid(timer):
			timer.queue_free()
	
	active_death_timers.clear()
	respawn_countdown_timers.clear()
	player_death_cooldowns.clear()
	respawn_reservations.clear()