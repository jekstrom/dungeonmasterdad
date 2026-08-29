class_name RealityZone extends Zone

# Spawn point management for player respawning
@export var spawn_points: Array[Vector2] = []
@export var spawn_point_spacing: float = 50.0  # Minimum distance between spawn points
@export var cooldown_duration: float = 10.0   # Seconds before spawn point can be reused

# Internal tracking
var spawn_point_data: Array[Dictionary] = []  # Detailed spawn point info
var last_used_spawn_index: int = 0
var next_spawn_point_id: int = 0

const DEFAULT_POCKET_DURATION := 8.0
const POCKET_OVERLAY_PATH := "res://sprites/reality_pocket_overlay.png"

var claim: RealityClaim = RealityClaim.new()
var _pocket_overlay_root: Node2D = null
var _pocket_overlay_texture: Texture2D = null

func _ready() -> void:
	super._ready()
	_sync_claim_home()
	_initialize_spawn_points()
	if not SignalBus.respawn_location_selected.is_connected(_on_respawn_location_selected):
		SignalBus.respawn_location_selected.connect(_on_respawn_location_selected)
	if not SignalBus.reality_pocket_requested.is_connected(_on_reality_pocket_requested):
		SignalBus.reality_pocket_requested.connect(_on_reality_pocket_requested)
	if not SignalBus.reality_claim_changed.is_connected(cull_banned_skeletons):
		SignalBus.reality_claim_changed.connect(cull_banned_skeletons)
	if not multiplayer.peer_connected.is_connected(_on_claim_peer_connected):
		multiplayer.peer_connected.connect(_on_claim_peer_connected)
	_rebuild_west_strip_spawns()
	_rebuild_home_overlay()

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
	var spawn_radius = float(base_radius if radius == null else radius) * 0.7
	
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
	"""Check if a world position is Reality-claimed (home or live pocket)."""
	return is_claimed_world(pos)

func contains_world_position(world: Vector2) -> bool:
	_sync_claim_home()
	return claim.is_claimed_world(world)

func contains_world_rect(rect: Rect2) -> bool:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return false
	var inset := 0.001
	var corners: Array[Vector2] = [
		rect.position,
		Vector2(rect.end.x - inset, rect.position.y),
		Vector2(rect.end.x - inset, rect.end.y - inset),
		Vector2(rect.position.x, rect.end.y - inset),
	]
	for corner in corners:
		if not is_claimed_world(corner):
			return false
	return true

func is_claimed_cell(cell: Vector2i) -> bool:
	_sync_claim_home()
	return claim.is_claimed_cell(cell)

func is_claimed_world(world: Vector2) -> bool:
	_sync_claim_home()
	return claim.is_claimed_world(world)

func overlay_kind_for_cell(cell: Vector2i) -> String:
	_sync_claim_home()
	return claim.overlay_kind_for_cell(cell)

func winning_pocket_id(cell: Vector2i) -> int:
	_sync_claim_home()
	return claim.winning_pocket_id(cell)

func get_pocket(pocket_id: int) -> Dictionary:
	for pocket in claim.pockets:
		if int(pocket["id"]) == pocket_id:
			return pocket
	return {}

func spawn_pocket(origin: Vector2i, size: Vector2i, duration: float = DEFAULT_POCKET_DURATION) -> int:
	if not _is_claim_host():
		_rpc_request_spawn_pocket.rpc_id(1, origin, size, duration)
		return -1
	_sync_claim_home()
	var clipped: Rect2i = clip_pocket_rect(Rect2i(origin, size))
	var pocket: Dictionary = claim.add_pocket(clipped, duration, _claim_now())
	if pocket.is_empty():
		return -1
	var pocket_id: int = int(pocket["id"])
	var tree := get_tree()
	if tree:
		var timer: SceneTreeTimer = tree.create_timer(duration)
		timer.timeout.connect(_on_pocket_timeout.bind(pocket_id))
	SignalBus.reality_pocket_created.emit(pocket_id, clipped, duration)
	SignalBus.reality_claim_changed.emit()
	_rebuild_home_overlay()
	_broadcast_claim()
	return pocket_id

func expire_pocket(pocket_id: int) -> bool:
	if not _is_claim_host():
		return false
	if not claim.expire_pocket(pocket_id):
		return false
	SignalBus.reality_pocket_expired.emit(pocket_id)
	SignalBus.reality_claim_changed.emit()
	_rebuild_home_overlay()
	_broadcast_claim()
	return true

func _on_pocket_timeout(pocket_id: int) -> void:
	expire_pocket(pocket_id)

func _on_reality_pocket_requested(origin: Vector2i, size: Vector2i, duration: float) -> void:
	spawn_pocket(origin, size, duration)

func _sync_claim_home() -> void:
	claim.home_rect = home_rect

func _claim_now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0

func _rebuild_home_overlay() -> void:
	_sync_claim_home()
	_ensure_home_overlay_root()
	_ensure_pocket_overlay_root()
	_clear_overlay_children(_home_overlay_root)
	_clear_overlay_children(_pocket_overlay_root)
	if _home_overlay_texture == null:
		_home_overlay_texture = load(HOME_OVERLAY_PATH) as Texture2D
	if _pocket_overlay_texture == null:
		_pocket_overlay_texture = load(POCKET_OVERLAY_PATH) as Texture2D
	if home_rect.size.x > 0 and home_rect.size.y > 0 and _home_overlay_texture:
		for y in range(home_rect.position.y, home_rect.end.y):
			for x in range(home_rect.position.x, home_rect.end.x):
				var cell := Vector2i(x, y)
				if claim.overlay_kind_for_cell(cell) == "home":
					_place_overlay_sprite(_home_overlay_root, _home_overlay_texture, cell, 0)
	if _pocket_overlay_texture:
		for cell in claim.pocket_cells():
			if claim.overlay_kind_for_cell(cell) == "pocket":
				_place_overlay_sprite(_pocket_overlay_root, _pocket_overlay_texture, cell, 1)

func _ensure_pocket_overlay_root() -> void:
	if _pocket_overlay_root != null and is_instance_valid(_pocket_overlay_root):
		return
	_pocket_overlay_root = get_node_or_null("PocketOverlay") as Node2D
	if _pocket_overlay_root == null:
		_pocket_overlay_root = Node2D.new()
		_pocket_overlay_root.name = "PocketOverlay"
		add_child(_pocket_overlay_root)

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

func _on_map_bounds_cleared() -> void:
	super._on_map_bounds_cleared()
	claim.clear_pockets()
	_rebuild_home_overlay()
	SignalBus.reality_claim_changed.emit()
	_broadcast_claim()

func _on_map_bounds_committed(interior: Rect2i) -> void:
	super._on_map_bounds_committed(interior)
	_sync_claim_home()
	_clip_live_pockets()
	_rebuild_west_strip_spawns()
	SignalBus.reality_home_changed.emit(home_rect)
	SignalBus.reality_claim_changed.emit()
	_broadcast_claim()

func _clip_live_pockets() -> void:
	var expired: Array[int] = []
	for pocket in claim.pockets:
		var clipped: Rect2i = clip_pocket_rect(pocket["rect"])
		pocket["rect"] = clipped
		if clipped.size.x <= 0 or clipped.size.y <= 0:
			expired.append(int(pocket["id"]))
	for pocket_id in expired:
		expire_pocket(pocket_id)

func _rebuild_west_strip_spawns() -> void:
	var level: Node = get_tree().get_first_node_in_group("level_manager") if get_tree() else null
	if level == null or not level.has_method("west_spawn_cells"):
		return
	if not level.has_method("has_map_bounds") or not level.has_map_bounds():
		return
	var cells: Array[Vector2i] = level.west_spawn_cells()
	if cells.is_empty():
		return
	spawn_points.clear()
	for cell in cells:
		var world: Vector2 = DungeonGrid.to_world(cell) + Vector2(DungeonGrid.CELL_PX * 0.5, DungeonGrid.CELL_PX * 0.5)
		spawn_points.append(world - global_position)
	_initialize_spawn_points()

func _on_respawn_location_selected(player_id: int, pos: Vector2) -> void:
	"""Handle respawn location selection events"""
	# Could add logic here to track which players are assigned to which spawn points
	print("RealityZone: Player ", player_id, " assigned spawn position ", pos)

# =============================================================================
# DEBUG AND VISUALIZATION
# =============================================================================

func _draw() -> void:
	super._draw()  # Reality home overlay is in Zone; spawn dots only here
	
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
		if not contains_world_position(global_position + spawn_pos):
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

func on_level_changed(new_level: int) -> void:
	super.on_level_changed(new_level)
	_sync_claim_home()
	SignalBus.reality_home_changed.emit(home_rect)
	SignalBus.reality_claim_changed.emit()
	_broadcast_claim()

func cull_banned_skeletons(_unused = null) -> void:
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	RealityClaim.cull_skeletons_in_tree(get_tree())

func _is_claim_host() -> bool:
	if multiplayer.multiplayer_peer == null:
		return true
	return multiplayer.is_server()

func build_claim_sync_payload() -> Dictionary:
	_sync_claim_home()
	var payload: Dictionary = claim.to_sync_dict(_claim_now())
	payload["reality_level"] = int(PlayerManager.reality_level)
	return payload

func apply_claim_sync_payload(payload: Dictionary) -> void:
	claim.apply_sync_dict(payload, _claim_now())
	home_rect = claim.home_rect
	if payload.has("reality_level") and not _is_claim_host():
		PlayerManager.reality_level = int(payload["reality_level"])
	if home_rect.size.x > 0 and home_rect.size.y > 0:
		var world_origin: Vector2 = DungeonGrid.to_world(home_rect.position)
		var world_size: Vector2 = Vector2(home_rect.size) * DungeonGrid.CELL_PX
		global_position = world_origin + world_size * 0.5
		_apply_rect_collision(world_size)
	_rebuild_home_overlay()
	SignalBus.reality_claim_changed.emit()

func _broadcast_claim() -> void:
	if not Lobby.is_network_server():
		return
	_rpc_apply_claim.rpc(build_claim_sync_payload())

func _on_claim_peer_connected(peer_id: int) -> void:
	if not Lobby.is_network_server():
		return
	_rpc_apply_claim.rpc_id(peer_id, build_claim_sync_payload())

@rpc("authority", "reliable")
func _rpc_apply_claim(payload: Dictionary) -> void:
	if Lobby.is_network_server():
		return
	apply_claim_sync_payload(payload)

@rpc("any_peer", "reliable")
func _rpc_request_spawn_pocket(origin: Vector2i, size: Vector2i, duration: float) -> void:
	if not _is_claim_host():
		return
	spawn_pocket(origin, size, duration)

