class_name PlayerSnakeState extends PlayerState

@export var move_speed: float = 100.0
@export var trail_interval: float = 16.0  # Distance between trail points
@export var main_sprite: Sprite2D  # Set from scene file
@onready var idle: PlayerState = $"../idle"

# Trail system data structures
var trail_positions: Array[Vector2] = []  # Player's path history (SERVER ONLY)
var trail_sprites: Array[Sprite2D] = []   # Visual trail segments (ALL CLIENTS)
var num_trail_segments: int = 0           # Current number of trail segments
var last_trail_position: Vector2         # Last recorded position for trail
var player_parent: Node2D                # Reference to player's parent for adding sprites

# Multiplayer synchronization
var player_id: int = -1                   # ID of the player this trail belongs to



func Enter() -> void:
	player.update_animation("walk")
	
	# Get player ID for multiplayer synchronization
	player_id = int(player.name)
	
	# Get player's parent for adding trail sprites to world
	player_parent = get_parent().get_parent()
	
	# Initialize trail system - SERVER ONLY manages trail data
	if multiplayer.is_server():
		num_trail_segments = 1  # Start with 1 trail segment
		trail_positions.clear()
		last_trail_position = player.global_position
		
		# Record initial trail positions
		# First position: where the player currently is
		record_trail_position(player.global_position)
		
		# Second position: slightly behind the player to create the first trail segment
		var behind_direction = Vector2.DOWN if player.prev_direction == Vector2.ZERO else player.prev_direction
		var initial_trail_pos = player.global_position - behind_direction * trail_interval
		record_trail_position(initial_trail_pos)
		
		# Connect to pickup signal for trail growth
		if not SignalBus.on_item_pickup.is_connected(add_trail_segment_handler):
			SignalBus.on_item_pickup.connect(add_trail_segment_handler)
		
		# Initialize trail on all clients and show initial segment
		if multiplayer.has_multiplayer_peer():
			initialize_trail_on_clients.rpc(player_id, num_trail_segments)
		else:
			# Single player mode - call directly
			initialize_trail_on_clients(player_id, num_trail_segments)
		
		# Immediately show the initial trail segment
		update_trail_display()
		
		print("🐍 Snake mode entered for player ", player_id)
	else:
		# Clients clean up any existing sprites and wait for server initialization
		cleanup_trail_sprites()
	
func Exit() -> void:
	# SERVER: Clean up trail data and notify clients
	if multiplayer.is_server():
		trail_positions.clear()
		
		# Disconnect from signals
		if SignalBus.on_item_pickup.is_connected(add_trail_segment_handler):
			SignalBus.on_item_pickup.disconnect(add_trail_segment_handler)
		
		# Tell all clients to clean up this player's trail
		cleanup_trail_on_clients.rpc(player_id)
	
	# ALL CLIENTS: Clean up visual sprites
	cleanup_trail_sprites()

func add_trail_segment_handler() -> void:
	# Only server processes trail growth
	if multiplayer.is_server():
		grow_trail_segment()

func grow_trail_segment() -> void:
	if not multiplayer.is_server():
		return
		
	num_trail_segments += 1
	print("🐍 Trail growing for player ", player_id, " - now ", num_trail_segments, " segments")
	
	# Update trail display on server and notify clients
	update_trail_display()
	sync_trail_growth.rpc(player_id, num_trail_segments)

# RPC: Initialize trail on all clients when snake mode starts
@rpc("authority", "call_local", "reliable")
func initialize_trail_on_clients(pid: int, segments: int) -> void:
	if pid == player_id:
		num_trail_segments = segments
		cleanup_trail_sprites()

# RPC: Sync trail growth to all clients
@rpc("authority", "call_local", "reliable") 
func sync_trail_growth(pid: int, segments: int) -> void:
	if pid == player_id:
		num_trail_segments = segments

# RPC: Update trail sprite positions on all clients (sent only on changes)
@rpc("authority", "call_local", "unreliable_ordered")
func sync_trail_positions(pid: int, positions: Array[Vector2]) -> void:
	if pid == player_id:
		# Update visual trail sprites based on server positions
		update_client_trail_display(positions)

# RPC: Clean up trail on all clients when snake mode exits
@rpc("authority", "call_local", "reliable")
func cleanup_trail_on_clients(pid: int) -> void:
	if pid == player_id:
		cleanup_trail_sprites()

func create_trail_sprite() -> Sprite2D:
	# Create a new trail sprite with player sprite properties
	var trail_sprite = Sprite2D.new()
	
	if main_sprite:
		trail_sprite.texture = main_sprite.texture
		trail_sprite.hframes = main_sprite.hframes
		trail_sprite.vframes = main_sprite.vframes
		trail_sprite.frame = main_sprite.frame
		trail_sprite.scale = main_sprite.scale
		trail_sprite.texture_filter = main_sprite.texture_filter
	else:
		print("Warning: main_sprite not set for snake state")
	
	# Apply dark/transparent appearance for trail effect
	trail_sprite.modulate = Color(0.3, 0.3, 0.3, 0.7)
	
	return trail_sprite

func cleanup_trail_sprites() -> void:
	# Remove all existing trail sprites
	for sprite in trail_sprites:
		if sprite and is_instance_valid(sprite):
			sprite.queue_free()
	trail_sprites.clear()

func record_trail_position(position: Vector2) -> void:
	# SERVER ONLY: Add new position to trail history
	if not multiplayer.is_server():
		return
		
	trail_positions.push_back(position)
	
	# Remove old positions if trail is too long
	# Keep extra positions for smooth trail management
	var max_positions = num_trail_segments * 3 + 20
	while trail_positions.size() > max_positions:
		trail_positions.pop_front()

func update_trail_display() -> void:
	# SERVER ONLY: Calculate trail positions and sync to clients
	if not multiplayer.is_server():
		return
		
	if trail_positions.size() == 0:
		return
	
	# Calculate current trail sprite positions
	var current_positions: Array[Vector2] = []
	
	if trail_positions.size() == 1:
		# Special case: only one position recorded, show trail segment at that position
		current_positions.append(trail_positions[0])
	else:
		# Normal case: calculate trail segments based on distance
		for i in range(num_trail_segments):
			var segment_index = get_trail_segment_index(i)
			if segment_index >= 0 and segment_index < trail_positions.size():
				current_positions.append(trail_positions[segment_index])
			elif trail_positions.size() > 0:
				# Fallback: use the oldest position we have
				current_positions.append(trail_positions[0])
	
	# Send positions to all clients (only if we have positions to show)
	if current_positions.size() > 0:
		if multiplayer.has_multiplayer_peer():
			sync_trail_positions.rpc(player_id, current_positions)
		else:
			# Single player mode - call directly
			sync_trail_positions(player_id, current_positions)

func update_client_trail_display(positions: Array[Vector2]) -> void:
	# CLIENT: Update visual sprites based on server positions
	if !player_parent:
		return
	
	# Ensure we have the right number of sprites
	while trail_sprites.size() < positions.size():
		var new_sprite = create_trail_sprite()
		new_sprite.name = "trail_" + str(player_id) + "_" + str(trail_sprites.size())
		player_parent.add_child(new_sprite)
		trail_sprites.append(new_sprite)
	
	# Remove excess sprites
	while trail_sprites.size() > positions.size():
		var excess_sprite = trail_sprites.pop_back()
		if excess_sprite and is_instance_valid(excess_sprite):
			excess_sprite.queue_free()
	
	# Position sprites at server-calculated positions
	for i in range(positions.size()):
		if i < trail_sprites.size():
			trail_sprites[i].global_position = positions[i]
			trail_sprites[i].visible = true
	
	# Hide any remaining sprites
	for i in range(positions.size(), trail_sprites.size()):
		if i < trail_sprites.size():
			trail_sprites[i].visible = false

func get_trail_segment_index(segment_num: int) -> int:
	# Calculate which trail position corresponds to this segment
	# Segments are spaced at trail_interval distances
	var target_distance = (segment_num + 1) * trail_interval
	var current_distance = 0.0
	
	# Walk backwards through trail positions to find the right distance
	for i in range(trail_positions.size() - 1, 0, -1):
		var segment_distance = trail_positions[i].distance_to(trail_positions[i - 1])
		current_distance += segment_distance
		
		if current_distance >= target_distance:
			return i
	
	return -1  # Not enough trail history yet

func Process(_delta: float) -> PlayerState:
	if !is_multiplayer_authority(): 
		return null
	
	# Move player at constant speed
	player.velocity = player.prev_direction * move_speed
	
	# SERVER ONLY: Record trail positions at regular intervals
	if multiplayer.is_server():
		var current_pos = player.global_position
		if last_trail_position.distance_to(current_pos) >= trail_interval:
			record_trail_position(last_trail_position)
			last_trail_position = current_pos
			# Only sync to clients when trail actually changes
			update_trail_display()
	
	# Update player animation based on direction changes
	if player.set_direction():
		player.update_animation("walk")
	
	player.move_and_slide()
	
	return null
	
func Physics(_delta: float) -> PlayerState:
	return null
	
func HandleInput(_event: InputEvent) -> PlayerState:
	if !is_multiplayer_authority(): 
		return null
	
	if _event.is_action_pressed("attack"):
		return null
		#return attack
	if _event.is_action_pressed("interact"):
		PlayerManager.interact_pressed.emit()
		

		
	return null
