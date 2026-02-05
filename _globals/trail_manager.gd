extends Node

# Trail data structure: { player_id: { "sprites": [Sprite2D], "collision_bodies": [StaticBody2D] } }
var all_player_trails: Dictionary = {}
var world_node: Node2D
var trail_color: Color = Color(0.3, 0.3, 0.3, 0.7)

# Collision layer for trail collision bodies (layer 32 = bit 5)
const TRAIL_COLLISION_LAYER: int = 32
const TRAIL_COLLISION_RADIUS: float = 6.0  # Smaller, more forgiving collision

func _ready() -> void:
	call_deferred("find_world_node")
	
	# Set up periodic cleanup timer (every 60 seconds, less aggressive now that logic is fixed)
	var cleanup_timer = Timer.new()
	cleanup_timer.name = "OrphanedTrailCleanupTimer"
	cleanup_timer.wait_time = 60.0
	cleanup_timer.autostart = true
	cleanup_timer.timeout.connect(cleanup_orphaned_trails)
	add_child(cleanup_timer)
	
	# Connect to death signals for immediate cleanup
	SignalBus.player_died.connect(_on_player_died)

# Handle player death signal
func _on_player_died(player_id: int, death_position: Vector2) -> void:
	print("TrailManager: Received death signal for player ", player_id)
	# Cleanup happens in cleanup_player_trail_on_death, but this ensures it

func find_world_node() -> void:
	var root = get_tree().current_scene
	if root:
		world_node = root
	else:
		print("TrailManager: WARNING - Could not find world node")

@rpc("authority", "call_local", "unreliable_ordered")
func sync_all_player_trails(trail_data: Dictionary) -> void:
	for player_id in trail_data.keys():
		var data = trail_data[player_id]
		update_player_trail_display(player_id, data.get("positions", []), data.get("sprite_data", {}))
	
	cleanup_removed_players(trail_data.keys())

func update_player_trail_display(player_id: int, positions: Array[Vector2], sprite_data: Dictionary) -> void:
	if not world_node:
		return
	
	if not all_player_trails.has(player_id):
		all_player_trails[player_id] = {
			"sprites": [],
			"collision_bodies": []
		}
	
	var player_trail_data = all_player_trails[player_id]
	var player_trail_sprites = player_trail_data["sprites"]
	var player_trail_collision_bodies = player_trail_data["collision_bodies"]
	
	# Add new trail segments (both sprite and collision)
	while player_trail_sprites.size() < positions.size():
		var segment_index = player_trail_sprites.size()
		
		# Create visual sprite
		var new_sprite = create_trail_sprite(player_id, segment_index, sprite_data)
		world_node.add_child(new_sprite)
		player_trail_sprites.append(new_sprite)
		
		# Create collision body
		var new_collision_body = create_trail_collision_body(player_id, segment_index)
		world_node.add_child(new_collision_body)
		player_trail_collision_bodies.append(new_collision_body)
	
	# Remove excess trail segments (both sprite and collision)
	while player_trail_sprites.size() > positions.size():
		var excess_sprite = player_trail_sprites.pop_back()
		if excess_sprite and is_instance_valid(excess_sprite):
			excess_sprite.queue_free()
		
		var excess_collision = player_trail_collision_bodies.pop_back()
		if excess_collision and is_instance_valid(excess_collision):
			excess_collision.queue_free()
	
	# Update positions for both sprites and collision bodies
	for i in range(positions.size()):
		if i < player_trail_sprites.size():
			if player_trail_sprites[i] and is_instance_valid(player_trail_sprites[i]):
				player_trail_sprites[i].global_position = positions[i]
				player_trail_sprites[i].visible = true
			
			if player_trail_collision_bodies[i] and is_instance_valid(player_trail_collision_bodies[i]):
				player_trail_collision_bodies[i].global_position = positions[i]

func create_trail_sprite(player_id: int, segment_index: int, sprite_data: Dictionary) -> Sprite2D:
	var trail_sprite = Sprite2D.new()
	trail_sprite.name = "trail_" + str(player_id) + "_" + str(segment_index)
	
	if sprite_data.has("texture_path"):
		trail_sprite.texture = load(sprite_data["texture_path"])
	if sprite_data.has("hframes"):
		trail_sprite.hframes = sprite_data["hframes"]
	if sprite_data.has("vframes"):
		trail_sprite.vframes = sprite_data["vframes"]
	if sprite_data.has("frame"):
		trail_sprite.frame = sprite_data["frame"]
	if sprite_data.has("scale"):
		trail_sprite.scale = Vector2(sprite_data["scale"]["x"], sprite_data["scale"]["y"])
	if sprite_data.has("texture_filter"):
		trail_sprite.texture_filter = sprite_data["texture_filter"]
	
	trail_sprite.modulate = trail_color
	trail_sprite.z_index = -1
	
	return trail_sprite

func create_trail_collision_body(player_id: int, segment_index: int) -> StaticBody2D:
	var collision_body = StaticBody2D.new()
	collision_body.name = "trail_collision_" + str(player_id) + "_" + str(segment_index)
	
	# Create collision shape
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = TRAIL_COLLISION_RADIUS
	collision_shape.shape = circle_shape
	
	# Set collision properties
	collision_body.collision_layer = TRAIL_COLLISION_LAYER
	collision_body.collision_mask = 0  # Trails don't need to detect anything
	
	# Add collision shape as child
	collision_body.add_child(collision_shape)
	
	# Set metadata to identify trail owner
	collision_body.set_meta("trail_owner_id", player_id)
	collision_body.set_meta("trail_segment_index", segment_index)
	
	return collision_body

func cleanup_removed_players(active_player_ids: Array) -> void:
	var players_to_remove = []
	for player_id in all_player_trails.keys():
		if player_id not in active_player_ids:
			players_to_remove.append(player_id)
	
	for player_id in players_to_remove:
		cleanup_player_trail(player_id)

func cleanup_player_trail(player_id: int) -> void:
	if not all_player_trails.has(player_id):
		return
	
	var player_trail_data = all_player_trails[player_id]
	
	# Clean up sprites
	if player_trail_data.has("sprites"):
		var player_trail_sprites = player_trail_data["sprites"]
		for sprite in player_trail_sprites:
			if sprite and is_instance_valid(sprite):
				sprite.queue_free()
	
	# Clean up collision bodies
	if player_trail_data.has("collision_bodies"):
		var player_trail_collision_bodies = player_trail_data["collision_bodies"]
		for collision_body in player_trail_collision_bodies:
			if collision_body and is_instance_valid(collision_body):
				collision_body.queue_free()
	
	all_player_trails.erase(player_id)

func get_active_trail_players() -> Array:
	return all_player_trails.keys()

func has_trail_for_player(player_id: int) -> bool:
	if not all_player_trails.has(player_id):
		return false
	
	var player_trail_data = all_player_trails[player_id]
	if not player_trail_data.has("sprites"):
		return false
	
	return player_trail_data["sprites"].size() > 0

func cleanup_all_trails() -> void:
	for player_id in all_player_trails.keys():
		cleanup_player_trail(player_id)

# Advanced cleanup: Remove any orphaned trail collision bodies in the world
func cleanup_orphaned_trails() -> void:
	if not world_node:
		return
		
	print("TrailManager: Performing orphaned trail cleanup")
	var orphaned_count = 0
	
	# Get list of active trail players from our internal tracking
	var active_trail_players = all_player_trails.keys()
	
	# Find all trail collision bodies in the world
	var all_children = world_node.get_children()
	for child in all_children:
		if is_trail_collision_body(child):
			var owner_id = get_trail_owner_from_collision_body(child)
			
			# Check if this trail owner is in our active tracking
			if owner_id not in active_trail_players:
				print("Removing truly orphaned trail collision body: ", child.name, " (owner ", owner_id, " not in active list)")
				child.queue_free()
				orphaned_count += 1
	
	if orphaned_count > 0:
		print("TrailManager: Cleaned up ", orphaned_count, " truly orphaned trail collision bodies")
	else:
		print("TrailManager: No orphaned trails found")

# Get all collision bodies for a specific player's trail
func get_trail_collision_bodies(player_id: int) -> Array:
	if not all_player_trails.has(player_id):
		return []
	
	var player_trail_data = all_player_trails[player_id]
	if not player_trail_data.has("collision_bodies"):
		return []
	
	return player_trail_data["collision_bodies"]

# Get the owner player ID from a trail collision body
func get_trail_owner_from_collision_body(collision_body: StaticBody2D) -> int:
	if collision_body and collision_body.has_meta("trail_owner_id"):
		return collision_body.get_meta("trail_owner_id")
	return -1

# Check if a collision body belongs to a trail
func is_trail_collision_body(collision_body: Node) -> bool:
	return collision_body is StaticBody2D and collision_body.name.begins_with("trail_collision_")

# Clean up trail immediately on player death (server-side)
func cleanup_player_trail_on_death(player_id: int) -> void:
	if not multiplayer.is_server():
		return
	
	print("TrailManager: Cleaning up trails for dead player ", player_id)
	cleanup_player_trail(player_id)
	
	# Force immediate broadcast to all clients to remove trails
	var empty_trail_data = {}
	for pid in all_player_trails.keys():
		if pid != player_id:  # Keep alive players' trails
			var player_trail_data = all_player_trails[pid]
			if player_trail_data.has("sprites") and player_trail_data["sprites"].size() > 0:
				# Get current positions for alive players
				var positions: Array[Vector2] = []
				for sprite in player_trail_data["sprites"]:
					if sprite and is_instance_valid(sprite):
						positions.append(sprite.global_position)
				
				if positions.size() > 0:
					empty_trail_data[pid] = {
						"positions": positions,
						"segments": positions.size(),
						"sprite_data": get_cached_sprite_data(pid)
					}
	
	# Broadcast updated trail data (without dead player)
	sync_all_player_trails.rpc(empty_trail_data)

# Cache sprite data for a player to avoid repeated lookups
func get_cached_sprite_data(player_id: int) -> Dictionary:
	var player_trail_data = all_player_trails.get(player_id, {})
	if player_trail_data.has("sprites") and player_trail_data["sprites"].size() > 0:
		var sprite = player_trail_data["sprites"][0]
		if sprite and is_instance_valid(sprite) and sprite.texture:
			return {
				"texture_path": sprite.texture.resource_path,
				"hframes": sprite.hframes,
				"vframes": sprite.vframes,
				"frame": sprite.frame,
				"scale": {"x": sprite.scale.x, "y": sprite.scale.y},
				"texture_filter": sprite.texture_filter
			}
	return {}