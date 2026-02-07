class_name RealityZone extends Zone

# Spawn point management for player respawning
@export var spawn_points: Array[Vector2] = []
@export var spawn_point_spacing: float = 50.0  # Minimum distance between spawn points
@export var cooldown_duration: float = 10.0   # Seconds before spawn point can be reused

# Internal tracking
var spawn_point_data: Array[Dictionary] = []  # Detailed spawn point info
var last_used_spawn_index: int = 0
var next_spawn_point_id: int = 0

func _ready() -> void:
	super._ready()  # Call parent Zone._ready()
	
	# Initialize spawn point system
	_initialize_spawn_points()
	
	# Connect to SignalBus for respawn coordination
	SignalBus.respawn_location_selected.connect(_on_respawn_location_selected)

func _initialize_spawn_points() -> void:
	"""Set up spawn point data structures and generate default points if needed"""
	
	# If no spawn points are configured, generate them automatically
	if spawn_points.is_empty():
		_generate_default_spawn_points()
	
	# Initialize spawn point tracking data
	spawn_point_data.clear()
	for i in range(spawn_points.size()):
		var spawn_data = {
			"id": next_spawn_point_id,
			"position": spawn_points[i],
			"is_available": true,
			"last_used_time": 0.0,
			"priority": i,  # Lower index = higher priority
			"cooldown_remaining": 0.0
		}
		spawn_point_data.append(spawn_data)
		next_spawn_point_id += 1

func _generate_default_spawn_points() -> void:
	"""Create evenly distributed spawn points around the zone center"""
	var num_points = 8  # Generate 8 spawn points by default
	var spawn_radius = radius * 0.7  # Place points at 70% of zone radius
	
	spawn_points.clear()
	for i in range(num_points):
		var angle = (TAU / num_points) * i
		var spawn_pos = Vector2(cos(angle), sin(angle)) * spawn_radius
		spawn_points.append(spawn_pos)

func get_next_spawn_point() -> Vector2:
	"""Get the best available spawn point for a player respawn"""
	var current_time = _get_current_time()
	var best_spawn_data = null
	var best_index = -1
	
	# Update cooldowns first
	_update_spawn_cooldowns(current_time)
	
	# Find the best available spawn point
	for i in range(spawn_point_data.size()):
		var spawn_data = spawn_point_data[i]
		
		# Skip if not available or on cooldown
		if not spawn_data["is_available"] or spawn_data["cooldown_remaining"] > 0:
			continue
		
		# Use priority-based selection (lower priority value = higher priority)
		if best_spawn_data == null or spawn_data["priority"] < best_spawn_data["priority"]:
			best_spawn_data = spawn_data
			best_index = i
	
	# If no available points, use round-robin fallback
	if best_spawn_data == null:
		best_index = last_used_spawn_index
		best_spawn_data = spawn_point_data[best_index]
		print("RealityZone: No available spawn points, using fallback index ", best_index)
	
	# Reserve the selected spawn point
	if best_spawn_data != null:
		_reserve_spawn_point(best_index, current_time)
		last_used_spawn_index = (best_index + 1) % spawn_point_data.size()
		
		# Return world position (zone position + local spawn point offset)
		return global_position + best_spawn_data["position"]
	
	# Ultimate fallback - return zone center
	print("RealityZone: Error in spawn point selection, using zone center")
	return global_position

func reserve_spawn_point_for_player(player_id: int) -> Vector2:
	"""Reserve a spawn point for a specific player and return its position"""
	var spawn_position = get_next_spawn_point()
	
	# Emit signal to notify other systems
	SignalBus.respawn_location_selected.emit(player_id, spawn_position)
	
	return spawn_position

func _reserve_spawn_point(spawn_index: int, current_time: float) -> void:
	"""Mark a spawn point as reserved/in use"""
	if spawn_index >= 0 and spawn_index < spawn_point_data.size():
		var spawn_data = spawn_point_data[spawn_index]
		spawn_data["is_available"] = false
		spawn_data["last_used_time"] = current_time
		spawn_data["cooldown_remaining"] = cooldown_duration

func release_spawn_point(spawn_position: Vector2) -> void:
	"""Mark a spawn point as available again after player has spawned"""
	var local_position = spawn_position - global_position
	
	# Find the spawn point by position
	for spawn_data in spawn_point_data:
		if spawn_data["position"].distance_to(local_position) < 10.0:  # 10 pixel tolerance
			spawn_data["is_available"] = true
			break

func _update_spawn_cooldowns(current_time: float) -> void:
	"""Update cooldown timers for all spawn points"""
	for spawn_data in spawn_point_data:
		if spawn_data["cooldown_remaining"] > 0:
			var elapsed = current_time - spawn_data["last_used_time"] 
			spawn_data["cooldown_remaining"] = max(0.0, cooldown_duration - elapsed)
			
			# Mark as available if cooldown is complete
			if spawn_data["cooldown_remaining"] <= 0:
				spawn_data["is_available"] = true

func is_position_within_zone(pos: Vector2) -> bool:
	"""Check if a world position is within this reality zone's boundaries"""
	var distance_to_center = global_position.distance_to(pos)
	return distance_to_center <= radius

func get_safe_spawn_position_near(target_position: Vector2) -> Vector2:
	"""Get a spawn position as close as possible to the target while staying in zone"""
	# If target is already in zone, find closest spawn point to it
	if is_position_within_zone(target_position):
		return _get_closest_spawn_point_to(target_position)
	
	# If target is outside zone, use normal spawn point selection
	return get_next_spawn_point()

func _get_closest_spawn_point_to(target_position: Vector2) -> Vector2:
	"""Find the spawn point closest to the given target position"""
	var best_spawn_pos = global_position
	var best_distance = INF
	
	_update_spawn_cooldowns(_get_current_time())
	
	for spawn_data in spawn_point_data:
		# Only consider available spawn points
		if not spawn_data["is_available"] or spawn_data["cooldown_remaining"] > 0:
			continue
		
		var spawn_world_pos = global_position + spawn_data["position"]
		var distance = target_position.distance_to(spawn_world_pos)
		
		if distance < best_distance:
			best_distance = distance
			best_spawn_pos = spawn_world_pos
	
	return best_spawn_pos

func _get_current_time() -> float:
	"""Get current time in seconds (simple implementation)"""
	var time_dict = Time.get_time_dict_from_system()
	return float(time_dict.hour * 3600 + time_dict.minute * 60 + time_dict.second)

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_respawn_location_selected(player_id: int, pos: Vector2) -> void:
	"""Handle respawn location selection events"""
	# Could add logic here to track which players are assigned to which spawn points
	print("RealityZone: Player ", player_id, " assigned spawn position ", pos)

# =============================================================================
# DEBUG AND VISUALIZATION
# =============================================================================

func _draw() -> void:
	super._draw()  # Draw the zone circle
	
	# Draw spawn points in debug mode
	if OS.is_debug_build():
		_draw_spawn_points()

func _draw_spawn_points() -> void:
	"""Draw spawn points for debugging (only in debug builds)"""
	for spawn_data in spawn_point_data:
		var color = Color.GREEN if spawn_data["is_available"] else Color.RED
		if spawn_data["cooldown_remaining"] > 0:
			color = Color.YELLOW
		
		draw_circle(spawn_data["position"], 5.0, color)
		
		# Draw spawn point ID
		var font = ThemeDB.fallback_font
		var text = str(spawn_data["id"])
		draw_string(font, spawn_data["position"] + Vector2(8, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)

# =============================================================================
# VALIDATION AND UTILITIES
# =============================================================================

func validate_spawn_points() -> bool:
	"""Validate that spawn points are properly configured"""
	if spawn_points.is_empty():
		print("RealityZone: Warning - No spawn points configured")
		return false
	
	# Check for spawn points outside the zone
	for spawn_pos in spawn_points:
		if spawn_pos.length() > radius:
			print("RealityZone: Warning - Spawn point ", spawn_pos, " is outside zone radius")
	
	return true

func get_spawn_statistics() -> Dictionary:
	"""Return spawn point usage statistics for monitoring"""
	var stats = {
		"total_spawn_points": spawn_point_data.size(),
		"available_spawn_points": 0,
		"cooldown_spawn_points": 0,
		"reserved_spawn_points": 0
	}
	
	_update_spawn_cooldowns(_get_current_time())
	
	for spawn_data in spawn_point_data:
		if spawn_data["is_available"] and spawn_data["cooldown_remaining"] <= 0:
			stats["available_spawn_points"] += 1
		elif spawn_data["cooldown_remaining"] > 0:
			stats["cooldown_spawn_points"] += 1
		else:
			stats["reserved_spawn_points"] += 1
	
	return stats
