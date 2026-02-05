@tool
class_name ItemPickup extends CharacterBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var area_2d: Area2D = $Area2D

@export var item_data: ItemData: set = _set_item_data

func _ready() -> void:
	update_texture()
	if Engine.is_editor_hint():
		return
	area_2d.body_entered.connect(on_body_entered)
	if item_data:
		audio_stream_player_2d.stream = item_data.pickup_sound

func _physics_process(delta: float) -> void:
	var collision_info = move_and_collide(velocity * delta)
	if collision_info:
		velocity = velocity.bounce(collision_info.get_normal())
	velocity -= velocity * delta * 4

func on_body_entered(_body) -> void:
	if _body is DM and item_data != null and (item_data.pickup_char.is_empty() or item_data.pickup_char == "dm_only"):
		handle_pickup(1, item_data)
		area_2d.body_entered.disconnect(on_body_entered)
	if _body is Player and item_data != null and (item_data.pickup_char.is_empty() or item_data.pickup_char == "player_only"):
		try_pick_up(item_data)
		area_2d.body_entered.disconnect(on_body_entered)

func try_pick_up(picked_up_item_data: ItemData):
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
		# Send a request to the server with the item's unique name or ID
		pick_up_request.rpc_id(1, picked_up_item_data.get_path())

@rpc("any_peer", "call_remote", "reliable")
func pick_up_request(item_path: String) -> void:
	if not multiplayer.is_server(): return
	
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
	if picked_up_item_data.auto_use:
		picked_up_item_data.use()
	else:
		PlayerManager.add_item_to_inventory(sender_id, picked_up_item_data)
	AudioManager.play_private_sound(sender_id, item_data.pickup_sound.resource_path, Vector2(0.6, 1.0))
	
	# Now that pickups are properly synchronized, use RPC to remove on all clients
	update_client.rpc()
	print("SERVER: Pickup handled for player ", sender_id, " - notified all clients to remove")

# RPC to remove pickup on all clients after successful pickup
@rpc("any_peer", "call_local", "reliable")
func update_client():
	print("CLIENT: Removing picked up item at ", global_position)
	visible = false
	queue_free()

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
