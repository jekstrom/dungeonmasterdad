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
func request_player_death(death_position: Vector2) -> void:
	# Only server processes death requests
	if not multiplayer.is_server():
		return
	
	var player_id: int = multiplayer.get_remote_sender_id()
	
	# Validate death request
	if not _validate_death_request(player_id):
		print("DeathSystem: Invalid death request from player ", player_id)
		return
	
	# Process the death
	_handle_player_death(player_id, death_position)

# =============================================================================
# SERVER → CLIENT RPCs
# =============================================================================

@rpc("authority", "call_local", "reliable")
func notify_player_death(player_id: int, death_position: Vector2) -> void:
	print("DeathSystem: Notifying player ", player_id, " death at position ", death_position)
	
	# Clean up trails on all clients (server and clients)
	_cleanup_player_trails_client_side(player_id)
	
	# Trigger death state on the appropriate player node
	var player_node = _get_player_node(player_id)
	if player_node:
		_trigger_player_death_state(player_node)
	else:
		print("DeathSystem: Could not find player node for death notification: ", player_id)
	
	# Clear player inventory on all clients (server and remote clients)
	_clear_player_inventory_on_death(player_id)
	
	# Emit signal for local systems to handle
	SignalBus.player_death_processed.emit(player_id, [])
	print("DeathSystem: Player ", player_id, " death notification processed")

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
func notify_player_respawned(player_id: int, respawn_position: Vector2) -> void:
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

func _validate_death_request(player_id: int) -> bool:
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



func _handle_player_death(player_id: int, death_position: Vector2) -> void:
	var death_time: float = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	
	print("DeathSystem: Processing death for player ", player_id, " at position ", death_position)
	
	# Update death cooldown
	player_death_cooldowns[player_id] = death_time
	
	# CRITICAL: Clean up player trails immediately
	_cleanup_player_trails(player_id)
	
	# CRITICAL: Trigger death state transition on the player
	var player_node = _get_player_node(player_id)
	if player_node:
		_trigger_player_death_state(player_node)
	else:
		print("DeathSystem: ERROR - Could not find player node for death state transition: ", player_id)
	
	# Extract and drop player inventory (handled by death state now, but keep as backup)
	var dropped_items = _extract_player_inventory(player_id)
	if dropped_items.size() > 0:
		_create_dropped_items(dropped_items, death_position)
		# Emit signal for UI systems (sound effects, HUD notifications, etc.)
		SignalBus.items_dropped_at_location.emit(dropped_items, death_position)
	
	notify_player_death.rpc(player_id, death_position)
	# Start respawn delay timer
	_start_respawn_delay(player_id)



func _extract_player_inventory(player_id: int) -> Dictionary:
	"""Extract inventory items from player for dropping as regular pickups"""
	var items_to_drop: Dictionary = {}
	
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
		if quantity > 0:
			items_to_drop[item_resource_path] = quantity

	PlayerManager.update_client_inventory.rpc_id(player_id, {})
	
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



func _create_dropped_items(items_data: Dictionary, spawn_position: Vector2) -> void:
	# Use proper multiplayer spawning instead of manual client-side spawning
	_spawn_items_via_multiplayer_spawner(items_data, spawn_position)
	print("DeathSystem: Spawning ", items_data.size(), " pickup items via MultiplayerSpawner")

func _start_respawn_delay(player_id: int) -> void:
	var spawn_position = _select_respawn_location(player_id)
	
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

func _select_respawn_location(player_id: int) -> Vector2:
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

func get_respawn_delay_for_player() -> float:
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
	var spawners = scene_tree.get_nodes_in_group("multiplayer_pickup_spawner")
	if spawners.size() > 0:
		return spawners[0]
		
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
		respawn_position = _select_respawn_location(player_id)
	
	var respawn_time = _get_current_time()
	
	# Move player to respawn position on server and restore to world
	var player_node = _get_player_node(player_id)
	if player_node:
		print("DeathSystem: Respawning player ", player_id, " at ", respawn_position)
		
		# Move to respawn position
		player_node.global_position = respawn_position
		
		# Force player to idle state after respawn
		if player_node.has_method("force_idle_state"):
			player_node.force_idle_state()
			print("DeathSystem: Forced player ", player_id, " to idle state")
		else:
			print("DeathSystem: WARNING - Player node does not have force_idle_state method")
	else:
		print("DeathSystem: ERROR - Could not find player node for respawn: ", player_id)
	
	# Broadcast respawn to all clients
	notify_player_respawned.rpc(player_id, respawn_position)
	
	print("DeathSystem: Player ", player_id, " respawn process completed")

func _spawn_items_via_multiplayer_spawner(items_data: Dictionary, spawn_position: Vector2) -> void:
	"""Spawn pickup items using MultiplayerSpawner (server-side only)"""
	if not multiplayer.is_server():
		print("DeathSystem: WARNING - _spawn_items_via_multiplayer_spawner called on client")
		return

	if items_data.is_empty():
		print("DeathSystem: No items to spawn")
		return

	print("DeathSystem: Spawning ", items_data.size(), " item types at ", spawn_position)
	
	# Spawn each item via the proper multiplayer spawner
	for key in items_data.keys():
		var quantity = items_data[key]
		if !quantity or quantity <= 0:
			continue
		
		print("DeathSystem: Spawning ", quantity, " of item ", key)
		
		for i in range(quantity):
			# Calculate spread position for multiple items
			var spread_offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
			var item_spawn_position = spawn_position + spread_offset
			
			# Add small velocity for visual effect
			var velocity = Vector2(randf_range(-20, 20), randf_range(-20, 20))
			
			var spawn_data = {
				"item_type": key, 
				"position": item_spawn_position,
				"velocity": velocity
			}
			
			# Use call_deferred to prevent overwhelming the spawning system
			call_deferred("_emit_item_drop", spawn_data)

func _emit_item_drop(spawn_data: Dictionary) -> void:
	"""Deferred item drop emission to prevent race conditions"""
	SignalBus.on_item_drop.emit(spawn_data)

func _trigger_player_death_state(player_node: Node) -> void:
	"""Trigger the player to enter death state via their state machine"""
	if not player_node or not is_instance_valid(player_node):
		print("DeathSystem: Invalid player node for death state trigger")
		return
	
	var state_machine = player_node.get_node_or_null("PlayerStateMachine")
	if not state_machine:
		print("DeathSystem: Could not find PlayerStateMachine on player node")
		return
	
	# Trigger death state via RPC to ensure it works across all clients
	if state_machine.has_method("ChangeStateTo"):
		state_machine.ChangeStateTo.rpc("death")
		print("DeathSystem: Triggered death state transition for player ", player_node.get_multiplayer_authority())
	else:
		print("DeathSystem: PlayerStateMachine does not have ChangeStateTo method")
		
		# Fallback: try to find death state directly
		var death_state = state_machine.get_node_or_null("death")
		if death_state and state_machine.has_method("ChangeState"):
			state_machine.ChangeState(death_state)
			print("DeathSystem: Fallback death state transition successful")
		else:
			print("DeathSystem: ERROR - Could not trigger death state transition")

func _cleanup_player_trails(player_id: int) -> void:
	"""Clean up all trails for a dead player - both server tracking and visual trails"""
	print("DeathSystem: Cleaning up trails for player ", player_id)
	
	# First, stop server-side trail tracking and clean up trail data
	# This needs to happen on the server and be communicated to all clients
	if multiplayer.is_server():
		_stop_server_trail_tracking_for_player(player_id)
	
	# Then, clean up visual trails and collision bodies on all clients
	# Use the death-specific cleanup which handles proper broadcasting
	if TrailManager.has_method("cleanup_player_trail_on_death"):
		TrailManager.cleanup_player_trail_on_death(player_id)
		print("DeathSystem: Trail cleanup completed for player ", player_id)
	else:
		# Fallback to regular cleanup if death-specific method not available
		if TrailManager.has_method("cleanup_player_trail"):
			TrailManager.cleanup_player_trail(player_id)
			print("DeathSystem: Fallback trail cleanup completed for player ", player_id)
		else:
			print("DeathSystem: WARNING - TrailManager cleanup methods not available")

func _stop_server_trail_tracking_for_player(player_id: int) -> void:
	"""Stop server-side trail tracking for a specific player"""
	# Access the snake state's static trail data and stop tracking
	# We can't rely on finding the player's current state since they might be transitioning
	
	# Try to find any snake state instance to call the cleanup method
	var scene_tree = get_tree()
	if not scene_tree:
		print("DeathSystem: Could not access scene tree for trail cleanup")
		return
	
	var current_scene = scene_tree.current_scene
	if not current_scene:
		print("DeathSystem: Could not access current scene for trail cleanup") 
		return
	
	# Find any player node with a snake state to call the static cleanup method
	var players = current_scene.find_children("*", "Player", true, false)
	for player_node in players:
		var state_machine = player_node.get_node_or_null("PlayerStateMachine")
		if state_machine:
			var snake_state = state_machine.get_node_or_null("snake")
			if snake_state and snake_state.has_method("stop_server_trail_tracking"):
				snake_state.stop_server_trail_tracking(player_id)
				print("DeathSystem: Stopped server trail tracking for player ", player_id)
				return
	
	print("DeathSystem: Could not find snake state to stop trail tracking for player ", player_id)

func _cleanup_player_trails_client_side(player_id: int) -> void:
	"""Clean up player trails on client side (called via RPC)"""
	print("DeathSystem: Client-side trail cleanup for player ", player_id)
	
	# Clean up visual trails and collision bodies
	if TrailManager.has_method("cleanup_player_trail"):
		TrailManager.cleanup_player_trail(player_id)
		print("DeathSystem: Client-side trail cleanup completed for player ", player_id)
	else:
		print("DeathSystem: WARNING - TrailManager.cleanup_player_trail not available on client")

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_death_requested(player_id: int, position: Vector2) -> void:
	# Handle death request from signal system
	if multiplayer.is_server():
		_handle_player_death(player_id, position)



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

# =============================================================================
# INVENTORY CLEARING HELPERS
# =============================================================================

func _clear_player_inventory_on_death(player_id: int) -> void:
	"""Clear player inventory on death notification (called on all clients)"""
	print("DeathSystem: Clearing inventory for player ", player_id, " on death notification")
	
	# Only server should modify PlayerManager data
	if multiplayer.is_server():
		# Clear server-side PlayerManager inventory if not already cleared
		if PlayerManager.players_data.has(player_id):
			var player_data = PlayerManager.players_data[player_id]
			if player_data.has("inventory") and not player_data["inventory"].is_empty():
				print("DeathSystem: Clearing remaining server-side inventory for player ", player_id)
				player_data["inventory"].clear()
		
		# Send empty inventory update to the specific client
		PlayerManager.update_client_inventory.rpc_id(player_id, {})
	
	# On all clients (including server): trigger UI inventory clearing
	# This ensures the client-side inventory UI is properly updated
	if player_id == multiplayer.get_unique_id():
		# This is the local player dying - clear their client-side inventory UI
		SignalBus.inventory_updated.emit([])
		print("DeathSystem: Cleared local player inventory UI")
