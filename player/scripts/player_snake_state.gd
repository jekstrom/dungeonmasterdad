class_name PlayerSnakeState extends PlayerState

@export var move_speed: float = 100.0
@export var trail_interval: float = 16.0
@export var main_sprite: Sprite2D
@onready var idle: PlayerState = $"../idle"

var trail_positions: Array[Vector2] = []
var num_trail_segments: int = 0
var last_trail_position: Vector2
var player_id: int = -1

static var server_trail_data: Dictionary = {}
static var trail_broadcast_needed: bool = false
static var trail_broadcast_timer: Timer = null

func get_player_by_id(pid: int) -> Node:
	var players = get_tree().get_nodes_in_group("players")
	for player_node in players:
		if player_node.name.is_valid_int() and int(player_node.name) == pid:
			return player_node
	
	for player_node in players:
		if player_node.has_method("get_player_id") and player_node.get_player_id() == pid:
			return player_node
		elif "player_id" in player_node and player_node.player_id == pid:
			return player_node
	
	if multiplayer.has_multiplayer_peer():
		for player_node in players:
			if player_node.is_multiplayer_authority() and player_node.get_multiplayer_authority() == pid:
				return player_node
	
	return null

# Check if a player is a DM by their ID
func is_player_dm(pid: int) -> bool:
	var player_node = get_player_by_id(pid)
	# DM player is always named "dm" and has ID 1
	return player_node != null and (player_node.name == "dm" or pid == 1)

# Check if current player is a DM  
func is_current_player_dm() -> bool:
	# Check if the player node name is "dm" (DM players are named "dm")
	return player.name == "dm"

# Check for trail collisions after movement  
# Grace system: Players don't die from their own first 2 trail segments, but others can still collide with them
func check_trail_collisions() -> bool:
	# DM is immune to trail collisions
	if is_current_player_dm():
		return false
	
	# Performance optimization: early exit if no collisions
	var collision_count = player.get_slide_collision_count()
	if collision_count == 0:
		return false
	
	for i in collision_count:
		var collision = player.get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Skip null colliders
		if not collider:
			continue
		
		# Check if we collided with a trail collision body
		if TrailManager.is_trail_collision_body(collider):
			var trail_owner_id = TrailManager.get_trail_owner_from_collision_body(collider)
			
			# Performance: skip invalid owner IDs
			if trail_owner_id == -1:
				continue
			
			# DM trails don't kill players (DM immunity)
			if is_player_dm(trail_owner_id):
				print("🛡️ IMMUNE: Collision with DM trail ignored")
				continue
			
			# Self-collision grace check ONLY - other players can always collide with your trails
			if trail_owner_id == player_id:
				# Get trail segment index from collision body metadata
				var segment_index = -1
				if collider.has_meta("trail_segment_index"):
					segment_index = collider.get_meta("trail_segment_index")
				
				# Grace ONLY for the first 2 segments (recent trail behind player)
				if segment_index >= 0 and segment_index < 2:
					print("🔄 SELF-GRACE: Own trail segment (index:", segment_index, ") - safe from self")
					continue
				
				print("💀 SELF-COLLISION: Collided with own trail segment ", segment_index)
			
			# Valid fatal collision detected
			print("💀 FATAL: Trail collision detected! (Owner: ", trail_owner_id, ", Victim: ", player_id, ")")
			return true
	
	return false

# Handle player death from trail collision
func handle_trail_death(death_position: Vector2) -> void:
	print("💀 DEATH: Player ", player_id, " died from trail collision at ", death_position)
	
	# Immediate visual feedback - freeze player movement
	player.velocity = Vector2.ZERO
	
	# Use DeathSystem for consistent death handling
	if multiplayer.has_multiplayer_peer():
		# Request death through the centralized DeathSystem
		DeathSystem.request_player_death.rpc_id(1, death_position)
		print("SnakeState: Requested death processing from DeathSystem")
	else:
		# Single player fallback - trigger death state directly
		var death_state = state_machine.current_state.get_node("../death")
		if death_state:
			state_machine.ChangeState(death_state)
			print("SnakeState: Direct death state transition (single player)")
		else:
			print("ERROR: Could not find death state for single player death")

# RPC to notify server of player death
@rpc("any_peer", "call_local", "reliable")
func notify_server_player_death(pid: int, death_pos: Vector2) -> void:
	if not multiplayer.is_server():
		return
	process_player_death(pid, death_pos)

# Server-side death processing (LEGACY - now handled by DeathSystem)
func process_player_death(pid: int, death_pos: Vector2) -> void:
	print("SERVER: Processing death for player ", pid, " at ", death_pos, " (LEGACY - should not be called)")
	
	# Trail cleanup is now handled by DeathSystem._cleanup_player_trails()
	# Inventory and respawn is handled by DeathSystem._handle_player_death()
	
	# This should only be called if DeathSystem is not available (fallback)
	if not DeathSystem:
		print("WARNING: DeathSystem not available, using legacy death handling")
		# Clean up trails as fallback
		TrailManager.cleanup_player_trail_on_death(pid)
		# Request death through the proper SignalBus signal
		SignalBus.player_death_requested.emit(pid, death_pos)
	else:
		print("WARNING: Legacy death processing called when DeathSystem available - this should not happen")

# RPC to notify all clients of player death for visual effects
@rpc("authority", "call_local", "reliable")
func notify_death_to_all_clients(pid: int, death_pos: Vector2) -> void:
	print("CLIENT: Player ", pid, " died at ", death_pos)
	# Could add death particle effects, sound, screen shake, etc.
	
	# Ensure local trail cleanup happens on all clients
	if TrailManager.has_trail_for_player(pid):
		print("CLIENT: Cleaning up visual trails for dead player ", pid)
		TrailManager.cleanup_player_trail(pid)

func Enter() -> void:
	player.update_animation("walk")
	player_id = int(player.name)
	num_trail_segments = 1
	
	# Enable trail collision detection by adding layer 32 to collision mask
	var original_mask = player.collision_mask
	player.collision_mask = original_mask | 32  # Add trail collision layer
	
	if multiplayer.has_multiplayer_peer():
		notify_server_snake_mode_entered.rpc_id(1, player_id)
	else:
		start_server_trail_tracking(player_id)
	
func Exit() -> void:
	# Restore original collision mask by removing trail collision layer
	player.collision_mask = player.collision_mask & ~32  # Remove trail collision layer
	
	if multiplayer.has_multiplayer_peer():
		notify_server_snake_mode_exited.rpc_id(1, player_id)
	else:
		stop_server_trail_tracking(player_id)

@rpc("any_peer", "call_local", "reliable")
func notify_server_snake_mode_entered(pid: int) -> void:
	if not multiplayer.is_server():
		return
	start_server_trail_tracking(pid)

@rpc("any_peer", "call_local", "reliable")
func notify_server_snake_mode_exited(pid: int) -> void:
	if not multiplayer.is_server():
		return
	stop_server_trail_tracking(pid)

@rpc("any_peer", "call_local", "reliable")
func notify_server_player_moved(pid: int, position: Vector2) -> void:
	if not multiplayer.is_server():
		return
	update_server_trail_tracking(pid, position)

func start_server_trail_tracking(pid: int) -> void:
	print("start_server_trail_tracking")
	var player_node = get_player_by_id(pid)
	if not player_node:
		print("DID NOT FIND PLAYER NODE: ", pid)
		return
	
	setup_broadcast_timer_if_needed()
	
	server_trail_data[pid] = {
		"positions": [],
		"segments": 1,
		"last_position": player_node.global_position,
		"player_node": player_node
	}
	
	var positions = server_trail_data[pid]["positions"]
	positions.push_back(player_node.global_position)
	
	var behind_direction = Vector2.DOWN if player_node.prev_direction == Vector2.ZERO else player_node.prev_direction  
	# Place initial trail at 1.5x trail_interval for safety (balanced grace)
	var initial_trail_pos = player_node.global_position - behind_direction * (trail_interval * 1.5)
	positions.push_back(initial_trail_pos)
	
	if not SignalBus.on_item_pickup.is_connected(_on_item_pickup_server_handler):
		print("Connected on_item_pickup")
		SignalBus.on_item_pickup.connect(_on_item_pickup_server_handler)
	
	mark_trail_broadcast_needed()
	broadcast_all_trail_data()

func stop_server_trail_tracking(pid: int) -> void:
	if server_trail_data.has(pid):
		print("Stopping server trail tracking for player ", pid)
		server_trail_data.erase(pid)
		
		# Clean up visual trails immediately
		TrailManager.cleanup_player_trail(pid)
	
	if server_trail_data.is_empty():
		if SignalBus.on_item_pickup.is_connected(_on_item_pickup_server_handler):
			print("Disconnected on_item_pickup - no more snake players")
			SignalBus.on_item_pickup.disconnect(_on_item_pickup_server_handler)
		cleanup_broadcast_timer()
	
	mark_trail_broadcast_needed()

func update_server_trail_tracking(pid: int, position: Vector2) -> void:
	if not server_trail_data.has(pid):
		return
		
	var data = server_trail_data[pid]
	var last_pos = data["last_position"]
	
	if last_pos.distance_to(position) >= trail_interval:
		data["positions"].push_back(last_pos)
		data["last_position"] = position
		
		var max_positions = data["segments"] * 3 + 20
		while data["positions"].size() > max_positions:
			data["positions"].pop_front()
		
		mark_trail_broadcast_needed()

func _on_item_pickup_server_handler() -> void:
	print(" ____on_item_pickup!")
	for pid in server_trail_data.keys():
		var data = server_trail_data[pid]
		data["segments"] += 1
	
	mark_trail_broadcast_needed()

func setup_broadcast_timer_if_needed() -> void:
	if trail_broadcast_timer != null:
		return
	
	var scene_root = get_tree().current_scene
	if not scene_root:
		return
	
	trail_broadcast_timer = Timer.new()
	trail_broadcast_timer.name = "TrailBroadcastTimer"
	trail_broadcast_timer.wait_time = 0.1
	trail_broadcast_timer.autostart = false
	trail_broadcast_timer.timeout.connect(_on_broadcast_timer_timeout)
	scene_root.add_child(trail_broadcast_timer)

func cleanup_broadcast_timer() -> void:
	if trail_broadcast_timer != null and is_instance_valid(trail_broadcast_timer):
		trail_broadcast_timer.queue_free()
		trail_broadcast_timer = null

func mark_trail_broadcast_needed() -> void:
	trail_broadcast_needed = true
	if trail_broadcast_timer != null and not trail_broadcast_timer.is_stopped():
		return
	
	if trail_broadcast_timer != null:
		trail_broadcast_timer.start()

func _on_broadcast_timer_timeout() -> void:
	if trail_broadcast_needed:
		broadcast_all_trail_data()
		trail_broadcast_needed = false
	
	if trail_broadcast_timer != null:
		trail_broadcast_timer.stop()

func get_server_trail_segment_index(positions: Array, segment_num: int) -> int:
	var target_distance = (segment_num + 1) * trail_interval
	var current_distance = 0.0
	
	for i in range(positions.size() - 1, 0, -1):
		var segment_distance = positions[i].distance_to(positions[i - 1])
		current_distance += segment_distance
		
		if current_distance >= target_distance:
			return i
	
	return -1

func get_player_sprite_data(pid: int) -> Dictionary:
	var player_node = get_player_by_id(pid)
	if not player_node:
		return {}
	
	var sprite_node = player_node.get_node_or_null("Sprite2D")
	if not sprite_node:
		return {}
	
	var sprite_data = {}
	if sprite_node.texture:
		sprite_data["texture_path"] = sprite_node.texture.resource_path
	sprite_data["hframes"] = sprite_node.hframes
	sprite_data["vframes"] = sprite_node.vframes
	sprite_data["frame"] = sprite_node.frame
	sprite_data["scale"] = {"x": sprite_node.scale.x, "y": sprite_node.scale.y}
	sprite_data["texture_filter"] = sprite_node.texture_filter
	
	return sprite_data

func broadcast_all_trail_data() -> void:
	if not multiplayer.is_server():
		return
	
	var all_trail_data = {}
	
	for pid in server_trail_data.keys():
		var data = server_trail_data[pid]
		var positions = data["positions"]
		var segments = data["segments"]
		
		if positions.size() == 0:
			continue
		
		var current_positions: Array[Vector2] = []
		
		if positions.size() == 1:
			current_positions.append(positions[0])
		else:
			for i in range(segments):
				var segment_index = get_server_trail_segment_index(positions, i)
				if segment_index >= 0 and segment_index < positions.size():
					current_positions.append(positions[segment_index])
				elif positions.size() > 0:
					current_positions.append(positions[0])
		
		if current_positions.size() > 0:
			all_trail_data[pid] = {
				"positions": current_positions,
				"segments": segments,
				"sprite_data": get_player_sprite_data(pid)
			}
	
	TrailManager.sync_all_player_trails.rpc(all_trail_data)

@rpc("authority", "call_local", "reliable")
func cleanup_trail_on_clients(_pid: int) -> void:
	pass

func Process(_delta: float) -> PlayerState:
	if !is_multiplayer_authority(): 
		return null
	
	player.velocity = player.prev_direction * move_speed
	
	var current_pos = player.global_position
	if last_trail_position.distance_to(current_pos) >= trail_interval:
		last_trail_position = current_pos
		
		if multiplayer.has_multiplayer_peer():
			notify_server_player_moved.rpc_id(1, player_id, current_pos)
		else:
			update_server_trail_tracking(player_id, current_pos)
	
	if player.set_direction():
		player.update_animation("walk")
	
	player.move_and_slide()
	
	# Check for trail collisions after movement
	if check_trail_collisions():
		# Start death process but don't change state immediately
		handle_trail_death(current_pos)
		# Return idle to exit snake state immediately
		return idle
	
	return null
	
func Physics(_delta: float) -> PlayerState:
	return null
	
func HandleInput(_event: InputEvent) -> PlayerState:
	if !is_multiplayer_authority(): 
		return null
	
	if _event.is_action_pressed("attack"):
		return null
	if _event.is_action_pressed("interact"):
		PlayerManager.interact_pressed.emit()
		
	return null
