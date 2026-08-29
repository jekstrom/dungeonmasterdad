class_name SpawnManager extends Node

# Spawn management constants
const MIN_SPAWN_DISTANCE_FROM_PLAYERS: float = 100.0
const PREFERRED_SPAWN_DISTANCE: float = 200.0
const MAX_SPAWN_ATTEMPTS: int = 10

# Cached references
var reality_zones: Array[Zone] = []
var cached_players: Array[Player] = []
var last_cache_update: float = 0.0
const CACHE_REFRESH_INTERVAL: float = 1.0

func _ready() -> void:
	# Connect to SignalBus for spawn coordination
	SignalBus.respawn_location_selected.connect(_on_respawn_location_selected)
	
	# Initialize zone cache
	_update_reality_zone_cache()

func _update_reality_zone_cache() -> void:
	"""Update cached list of reality zones"""
	var current_time = _get_current_time()
	
	# Only update cache periodically for performance
	if current_time - last_cache_update < CACHE_REFRESH_INTERVAL:
		return
	
	reality_zones.clear()
	
	var scene_tree = get_tree()
	if scene_tree == null:
		return
	
	var current_scene = scene_tree.current_scene
	if current_scene == null:
		return
	
	# Find all Zone instances with is_reality = true
	var zones = current_scene.find_children("*", "Zone", true, false)
	for zone in zones:
		if zone is Zone and zone.get("is_reality") == true:
			reality_zones.append(zone)
	
	print("SpawnManager: Found ", reality_zones.size(), " reality zones")
	last_cache_update = current_time

func _update_player_cache() -> void:
	"""Update cached list of active players"""
	cached_players.clear()
	
	var scene_tree = get_tree()
	if scene_tree == null:
		return
	
	var current_scene = scene_tree.current_scene
	if current_scene == null:
		return
	
	# Find all Player instances
	var players = current_scene.find_children("*", "Player", true, false)
	for player in players:
		if player is Player:
			cached_players.append(player)

func get_best_respawn_location(player_id: int, preferred_position: Vector2 = Vector2.ZERO) -> Vector2:
	"""Get the best respawn location for a player"""
	_update_reality_zone_cache()
	_update_player_cache()
	
	if reality_zones.is_empty():
		print("SpawnManager: No reality zones found, using fallback position")
		return Vector2.ZERO
	
	# Try each reality zone to find the best spawn point
	for zone in reality_zones:
		var spawn_position = _get_best_spawn_in_zone(zone, player_id, preferred_position)
		if spawn_position != Vector2.ZERO:
			return spawn_position
	
	# Fallback to first zone center if no good spawn found
	print("SpawnManager: Using fallback zone center spawn")
	return reality_zones[0].global_position

func _get_best_spawn_in_zone(zone: Zone, player_id: int, preferred_position: Vector2) -> Vector2:
	"""Find the best spawn point within a specific reality zone"""
	var best_spawn_position = Vector2.ZERO
	var best_score = -1.0
	
	# Try multiple spawn attempts for the best position
	for attempt in range(MAX_SPAWN_ATTEMPTS):
		var candidate_position = Vector2.ZERO
		if zone.has_method("get_next_spawn_point"):
			candidate_position = zone.get_next_spawn_point()
		else:
			# Fallback: generate random position within zone
			var angle = randf() * TAU
			var distance = randf() * zone.radius * 0.8
			candidate_position = zone.global_position + Vector2(cos(angle), sin(angle)) * distance
		
		# Score this spawn position
		var score = _score_spawn_position(candidate_position, player_id, preferred_position)
		
		if score > best_score:
			best_score = score
			best_spawn_position = candidate_position
	
	# Only return position if it meets minimum quality
	if best_score > 0.0:
		return best_spawn_position
	
	return Vector2.ZERO

func _score_spawn_position(position: Vector2, player_id: int, preferred_position: Vector2) -> float:
	"""Score a spawn position based on various criteria (higher is better)"""
	var score = 1.0  # Base score
	
	# Penalize spawns too close to other players
	var min_distance_to_players = INF
	for player in cached_players:
		if player.get_multiplayer_authority() == player_id:
			continue  # Skip the respawning player
		
		var distance = position.distance_to(player.global_position)
		min_distance_to_players = min(min_distance_to_players, distance)
	
	# Score based on distance from other players
	if min_distance_to_players < MIN_SPAWN_DISTANCE_FROM_PLAYERS:
		score *= 0.1  # Heavy penalty for spawning too close
	elif min_distance_to_players > PREFERRED_SPAWN_DISTANCE:
		score *= 1.2  # Bonus for good separation
	
	# Bonus for spawning near preferred position if specified
	if preferred_position != Vector2.ZERO:
		var distance_to_preferred = position.distance_to(preferred_position)
		if distance_to_preferred < 100.0:
			score *= 1.1
	
	# Check for obstacles or hazards at spawn position
	if _is_spawn_position_safe(position):
		score *= 1.0  # Safe position
	else:
		score *= 0.5  # Unsafe position
	
	return score

func _is_spawn_position_safe(position: Vector2) -> bool:
	"""Check if a spawn position is safe from obstacles"""
	# TODO: Implement collision checking
	# For now, assume all positions within reality zones are safe
	return true

func get_reality_zone_for_position(position: Vector2) -> Zone:
	"""Find which reality zone contains a position"""
	_update_reality_zone_cache()
	
	for zone in reality_zones:
		if zone.has_method("is_claimed_world"):
			if zone.is_claimed_world(position):
				return zone
		elif zone.has_method("is_position_within_zone"):
			if zone.is_position_within_zone(position):
				return zone
	
	return null

func get_nearest_reality_zone(position: Vector2) -> Zone:
	"""Get the reality zone nearest to a position"""
	_update_reality_zone_cache()
	
	if reality_zones.is_empty():
		return null
	
	var nearest_zone = reality_zones[0]
	var nearest_distance = position.distance_to(nearest_zone.global_position)
	
	for zone in reality_zones:
		var distance = position.distance_to(zone.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_zone = zone
	
	return nearest_zone

func reserve_spawn_point_for_player(player_id: int, death_position: Vector2 = Vector2.ZERO) -> Dictionary:
	"""Reserve a spawn point for a player and return spawn data"""
	var spawn_position = get_best_respawn_location(player_id, death_position)
	var spawn_zone = get_reality_zone_for_position(spawn_position)
	
	var spawn_data = {
		"player_id": player_id,
		"spawn_position": spawn_position,
		"zone": spawn_zone,
		"reservation_time": _get_current_time()
	}
	
	# Reserve the spawn point in the zone if it supports it
	if spawn_zone and spawn_zone.has_method("reserve_spawn_point_for_player"):
		spawn_zone.reserve_spawn_point_for_player(player_id)
	
	# Emit signal for coordination
	SignalBus.respawn_location_selected.emit(player_id, spawn_position)
	
	print("SpawnManager: Reserved spawn point for player ", player_id, " at ", spawn_position)
	return spawn_data

func release_spawn_point_reservation(player_id: int, spawn_data: Dictionary) -> void:
	"""Release a previously reserved spawn point"""
	var spawn_zone = spawn_data.get("zone", null)
	var spawn_position = spawn_data.get("spawn_position", Vector2.ZERO)
	
	if spawn_zone and spawn_zone.has_method("release_spawn_point"):
		spawn_zone.release_spawn_point(spawn_position)
	
	print("SpawnManager: Released spawn point reservation for player ", player_id)

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_respawn_location_selected(player_id: int, position: Vector2) -> void:
	"""Handle respawn location selection events"""
	print("SpawnManager: Player ", player_id, " assigned to spawn at ", position)

# =============================================================================
# UTILITIES
# =============================================================================

func _get_current_time() -> float:
	"""Get current time in seconds"""
	var time_dict = Time.get_time_dict_from_system()
	return float(time_dict.hour * 3600 + time_dict.minute * 60 + time_dict.second)

func get_spawn_statistics() -> Dictionary:
	"""Get spawn system statistics for monitoring"""
	_update_reality_zone_cache()
	
	var stats = {
		"total_reality_zones": reality_zones.size(),
		"total_spawn_points": 0,
		"available_spawn_points": 0,
		"active_players": cached_players.size()
	}
	
	for zone in reality_zones:
		var zone_stats = zone.get_spawn_statistics()
		stats["total_spawn_points"] += zone_stats.get("total_spawn_points", 0)
		stats["available_spawn_points"] += zone_stats.get("available_spawn_points", 0)
	
	return stats

func validate_spawn_system() -> bool:
	"""Validate that the spawn system is properly configured"""
	_update_reality_zone_cache()
	
	if reality_zones.is_empty():
		print("SpawnManager: ERROR - No reality zones found!")
		return false
	
	for zone in reality_zones:
		if not zone.validate_spawn_points():
			print("SpawnManager: WARNING - Zone ", zone.name, " has spawn point issues")
	
	return true