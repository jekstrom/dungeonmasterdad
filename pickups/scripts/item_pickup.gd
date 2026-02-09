@tool
class_name ItemPickup extends CharacterBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var area_2d: Area2D = $Area2D

@export var item_data: ItemData: set = _set_item_data

const friction: float = 75.0
@export var stop_threshold: float = 5.0

# Grace period to prevent immediate pickup after spawning
const PICKUP_GRACE_PERIOD: float = 1.0  # 1 second grace period
var grace_time_remaining: float = 0.0
var can_be_picked_up: bool = false
var debug = false

func _ready() -> void:
	update_texture()
	if Engine.is_editor_hint():
		can_be_picked_up = true  # Skip grace period in editor
		return
	
	# Initialize grace period with delta-based timing
	grace_time_remaining = PICKUP_GRACE_PERIOD
	can_be_picked_up = false
	
	if not area_2d.body_entered.is_connected(on_body_entered):
		area_2d.body_entered.connect(on_body_entered)
	if item_data:
		audio_stream_player_2d.stream = item_data.pickup_sound
	
	# Set up visual indication for grace period
	_indicate_grace_period_active()

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	if velocity.is_zero_approx(): return
		
	var collision_info = move_and_collide(velocity * _delta)
	if collision_info:
		velocity = velocity.bounce(collision_info.get_normal())
	var current_friction = friction
	if velocity.length() > 100:
		current_friction *= 19.0
		
	if velocity.length() > 0:
		velocity = velocity.move_toward(Vector2.ZERO, current_friction * _delta)
	
	if velocity.length() < stop_threshold:
		velocity = Vector2.ZERO
	
func _process(delta: float) -> void:
	# Handle grace period countdown (only when grace period is active)
	if not can_be_picked_up and grace_time_remaining > 0.0:
		grace_time_remaining -= delta
		if grace_time_remaining <= 0.0:
			grace_time_remaining = 0.0  # Ensure it doesn't go negative
			_on_grace_period_ended()
	if debug and not area_2d.body_entered.is_connected(on_body_entered):
		self.sprite_2d.modulate = Color.MAGENTA

func on_body_entered(_body) -> void:
	# Prevent pickup processing if node is being deleted or already processed
	if not is_inside_tree() or is_queued_for_deletion() or not visible:
		return
	
	# Check grace period - prevent pickup during grace period
	if not can_be_picked_up:
		return
	
	if _body is DM and item_data != null and (item_data.pickup_char.is_empty() or item_data.pickup_char == "dm_only"):
		handle_pickup(1, item_data)
	elif _body is Player and item_data != null and (item_data.pickup_char.is_empty() or item_data.pickup_char == "player_only"):
		try_pick_up(item_data)

func try_pick_up(picked_up_item_data: ItemData):
	# Check if pickup is still valid before processing
	if not is_inside_tree() or is_queued_for_deletion() or not visible:
		return
	
	# Respect grace period
	if not can_be_picked_up:
		return
	
	# If this is the server, handle pickup directly
	if multiplayer.is_server():
		# Find the player who actually triggered this pickup
		var player_node = _find_nearest_player()
		if player_node:
			var player_id = player_node.get_multiplayer_authority()
			var d = player_node.global_position.distance_to(self.global_position)
			if d < 30.0:
				handle_pickup(player_id, picked_up_item_data)
		else:
			print("ItemPickup: No valid player found near pickup on server")
	else:
		# Send a request to the server with the item's unique name or ID
		if picked_up_item_data and picked_up_item_data.get_path():
			pick_up_request.rpc_id(1, picked_up_item_data.get_path())
		else:
			print("ItemPickup: Invalid item data for pickup request")

@rpc("any_peer", "call_remote", "reliable")
func pick_up_request(item_path: String) -> void:
	if not multiplayer.is_server(): return
	
	# Check if this pickup node is still valid and not queued for deletion
	if not is_inside_tree() or is_queued_for_deletion():
		return
	
	# Check grace period on server side
	if not can_be_picked_up:
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	var player_node = _find_player_by_id(sender_id)
	var picked_up_item_data: ItemData = ItemDatabase.get_item(item_path)
	
	if player_node:
		var d = player_node.global_position.distance_to(self.global_position)
		if d < 30.0:
			handle_pickup(sender_id, picked_up_item_data)
	else:
		print("ERROR: Could not find player node for ID ", sender_id)

func handle_pickup(sender_id: int, picked_up_item_data: ItemData) -> void:
	# Double-check node validity before processing pickup
	if not is_inside_tree() or is_queued_for_deletion():
		return
	
	if picked_up_item_data.auto_use:
		picked_up_item_data.use()
	else:
		PlayerManager.add_item_to_inventory(sender_id, picked_up_item_data)
	AudioManager.play_private_sound(sender_id, item_data.pickup_sound.resource_path, Vector2(0.6, 1.0))
	
	# Disable the pickup immediately to prevent further interactions
	_disable_pickup()
	
	# Send RPC to remove on all clients (but not server due to call_remote)
	update_client.rpc()
	
	# Server handles its own cleanup separately with a small delay to ensure RPC delivery
	call_deferred("_server_cleanup")

# RPC to remove pickup on all clients after successful pickup  
@rpc("authority", "call_remote", "reliable")
func update_client():
	# Check if this pickup node is still valid - this prevents the RPC error
	if not is_inside_tree() or is_queued_for_deletion():
		return
	
	# Double-check we're not already processed
	if not visible:
		return
	
	# Use the same disable function as server for consistency
	_disable_pickup()
	
	# Use call_deferred to ensure RPC processing completes before deletion
	call_deferred("_safe_queue_free")

func update_texture() -> void:
	if item_data != null and sprite_2d != null:
		sprite_2d.texture = item_data.texture

func _set_item_data(_value: ItemData) -> void:
	item_data = _value
	update_texture()

# =============================================================================
# PLAYER FINDING UTILITIES (Server-side safe)
# =============================================================================

func _find_player_by_id(player_id: int) -> Node:
	"""Find a player node by their multiplayer authority ID"""
	var scene_tree = get_tree()
	if not scene_tree:
		return null
	
	var current_scene = scene_tree.current_scene
	if not current_scene:
		return null
	
	# Try direct path first (fastest)
	var direct_player = current_scene.get_node_or_null(str(player_id))
	if direct_player and (direct_player is Player or direct_player is DM):
		return direct_player
	
	# Search all players in the scene
	var players = current_scene.find_children("*", "Player", true, false)
	for player in players:
		if player.get_multiplayer_authority() == player_id:
			return player
	
	# Also check for DM nodes
	var dms = current_scene.find_children("*", "DM", true, false)
	for dm in dms:
		if dm.get_multiplayer_authority() == player_id:
			return dm
	
	return null

func _find_nearest_player() -> Node:
	"""Find the nearest player to this pickup (for server-side pickup detection)"""
	var scene_tree = get_tree()
	if not scene_tree:
		return null
	
	var current_scene = scene_tree.current_scene
	if not current_scene:
		return null
	
	var nearest_player = null
	var nearest_distance = INF
	
	# Check all players
	var players = current_scene.find_children("*", "Player", true, false)
	for player in players:
		var distance = player.global_position.distance_to(self.global_position)
		if distance < nearest_distance and distance < 30.0:  # Within pickup range
			nearest_distance = distance
			nearest_player = player
	
	# Also check DM nodes
	var dms = current_scene.find_children("*", "DM", true, false)
	for dm in dms:
		var distance = dm.global_position.distance_to(self.global_position)
		if distance < nearest_distance and distance < 30.0:  # Within pickup range
			nearest_distance = distance
			nearest_player = dm
	
	return nearest_player

func _safe_queue_free():
	if is_inside_tree() and not is_queued_for_deletion():
		ItemPickupPool.return_to_pool(self)
	else:
		print("ItemPickup: _safe_queue_free called but node already invalid")

func _on_grace_period_ended() -> void:
	"""Called when the grace period expires - enables pickup"""
	can_be_picked_up = true
	grace_time_remaining = 0.0  # Ensure it's exactly zero
	# Add a subtle visual indicator that pickup is now available
	_indicate_pickup_available()

func _indicate_pickup_available() -> void:
	"""Visual indication that pickup is now available"""
	if sprite_2d:
		# Stop the grace period pulsing effect
		if has_meta("grace_period_tween"):
			var grace_tween = get_meta("grace_period_tween")
			if grace_tween and is_instance_valid(grace_tween):
				grace_tween.kill()
			remove_meta("grace_period_tween")
		
		# Restore full opacity and create a bounce effect to indicate pickup is ready
		sprite_2d.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Full opacity
		
		var tween = create_tween()
		tween.tween_property(sprite_2d, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(sprite_2d, "scale", Vector2(1.0, 1.0), 0.2)

func get_grace_time_remaining() -> float:
	"""Get remaining grace period time"""
	return max(0.0, grace_time_remaining)

func is_grace_period_active() -> bool:
	"""Check if grace period is still active"""
	return not can_be_picked_up

func _indicate_grace_period_active() -> void:
	"""Visual indication that pickup is in grace period (not yet available)"""
	if sprite_2d:
		# Make the pickup slightly transparent during grace period
		sprite_2d.modulate = Color(1.0, 1.0, 1.0, 0.6)  # 60% opacity
		
		# Optional: Add a gentle pulsing effect during grace period
		var tween = create_tween()
		tween.set_loops()  # Loop indefinitely
		tween.tween_property(sprite_2d, "modulate:a", 0.4, 0.5)
		tween.tween_property(sprite_2d, "modulate:a", 0.6, 0.5)
		
		# Store tween reference to stop it later
		set_meta("grace_period_tween", tween)

func _disable_pickup():
	"""Immediately disable pickup interactions without deleting the node"""
	# Disconnect signals immediately to prevent further interactions
	if area_2d and area_2d.body_entered.is_connected(on_body_entered):
		area_2d.body_entered.disconnect(on_body_entered)
	
	# Hide immediately and disable collision
	visible = false
	set_collision_layer(0)
	set_collision_mask(0)
	
	# Disable the area collision as well
	if area_2d:
		area_2d.set_collision_layer(0)
		area_2d.set_collision_mask(0)

func _server_cleanup():
	if multiplayer.is_server() and is_inside_tree() and not is_queued_for_deletion():
		ItemPickupPool.return_to_pool(self)
