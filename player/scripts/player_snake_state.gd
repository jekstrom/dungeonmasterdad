class_name PlayerSnakeState extends PlayerState

@export var move_speed: float = 100.0
@export var trail_interval: float = 16.0  # Distance between trail points
@export var main_sprite: Sprite2D  # Set from scene file
@onready var idle: PlayerState = $"../idle"

# Trail system data structures
var trail_positions: Array[Vector2] = []  # Player's path history
var trail_sprites: Array[Sprite2D] = []   # Visual trail segments
var num_trail_segments: int = 0           # Current number of trail segments
var last_trail_position: Vector2         # Last recorded position for trail
var player_parent: Node2D                # Reference to player's parent for adding sprites



func Enter() -> void:
	player.update_animation("walk")
	
	# Initialize trail system
	num_trail_segments = 1  # Start with 1 trail segment
	trail_positions.clear()
	cleanup_trail_sprites()
	
	# Get player's parent for adding trail sprites to world
	player_parent = get_parent().get_parent()
	last_trail_position = player.global_position
	
	# Record initial position
	record_trail_position(player.global_position)
	
	# Connect to pickup signal for trail growth
	if not SignalBus.on_item_pickup.is_connected(add_trail_segment_handler):
		SignalBus.on_item_pickup.connect(add_trail_segment_handler)
	
	print("🐍 Snake mode entered - starting with ", num_trail_segments, " trail segment")
	print("🐍 Player parent: ", player_parent)
	print("🐍 Initial position: ", player.global_position)
	
func Exit() -> void:
	# Cleanup trail system
	cleanup_trail_sprites()
	trail_positions.clear()
	
	# Disconnect from signals
	if SignalBus.on_item_pickup.is_connected(add_trail_segment_handler):
		SignalBus.on_item_pickup.disconnect(add_trail_segment_handler)
	
	print("Snake mode exited - trail cleaned up")

func add_trail_segment_handler() -> void:
	# Called when player picks up an item - grow the trail
	add_trail_segment.rpc()

@rpc("any_peer", "call_local", "reliable")
func add_trail_segment() -> void:
	num_trail_segments += 1
	print("🐍 Trail growing - now ", num_trail_segments, " segments")
	update_trail_display()

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
	# Add new position to trail history
	trail_positions.push_back(position)
	print("🐍 Recording position: ", position, " (total positions: ", trail_positions.size(), ")")
	
	# Remove old positions if trail is too long
	# Keep extra positions for smooth trail management
	var max_positions = num_trail_segments * 3 + 20
	while trail_positions.size() > max_positions:
		trail_positions.pop_front()

func update_trail_display() -> void:
	# Update trail sprite positions based on trail history
	if !player_parent:
		print("🐍 ERROR: No player parent for trail sprites")
		return
		
	if trail_positions.size() < 2:
		print("🐍 Not enough positions yet: ", trail_positions.size())
		return
	
	print("🐍 Updating trail display - segments needed: ", num_trail_segments, ", sprites: ", trail_sprites.size())
	
	# Ensure we have enough sprites
	while trail_sprites.size() < num_trail_segments:
		var new_sprite = create_trail_sprite()
		new_sprite.name = "trail_segment_" + str(trail_sprites.size())
		player_parent.add_child(new_sprite)
		trail_sprites.append(new_sprite)
		print("🐍 Created trail sprite: ", new_sprite.name)
	
	# Remove excess sprites
	while trail_sprites.size() > num_trail_segments:
		var excess_sprite = trail_sprites.pop_back()
		if excess_sprite and is_instance_valid(excess_sprite):
			print("🐍 Removing excess sprite: ", excess_sprite.name)
			excess_sprite.queue_free()
	
	# Position trail sprites along the recorded path
	for i in range(num_trail_segments):
		if i < trail_sprites.size():
			var segment_index = get_trail_segment_index(i)
			if segment_index >= 0 and segment_index < trail_positions.size():
				trail_sprites[i].global_position = trail_positions[segment_index]
				trail_sprites[i].visible = true
				print("🐍 Positioned sprite ", i, " at ", trail_positions[segment_index])
			else:
				trail_sprites[i].visible = false
				print("🐍 Hiding sprite ", i, " (no position yet)")

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
	
	# Record trail positions at regular intervals
	var current_pos = player.global_position
	if last_trail_position.distance_to(current_pos) >= trail_interval:
		record_trail_position(last_trail_position)
		last_trail_position = current_pos
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
		
	# Test controls:
	if _event is InputEventKey and _event.pressed:
		match _event.keycode:
			KEY_T:
				print("🐍 Manual test: Adding trail segment")
				add_trail_segment()
			KEY_R:
				print("🐍 Manual test: Recording position")
				record_trail_position(player.global_position)
				update_trail_display()
			KEY_D:
				print("🐍 Debug info:")
				print("  - Trail segments: ", num_trail_segments)
				print("  - Trail positions: ", trail_positions.size())
				print("  - Trail sprites: ", trail_sprites.size())
				print("  - Current position: ", player.global_position)
		
	return null
