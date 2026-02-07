class_name PlayerDeathState extends PlayerState

@onready var respawn_wait: PlayerState = $"../respawn_wait"

# Death state properties
var death_position: Vector2 = Vector2.ZERO
var death_time: float = 0.0
var items_dropped: bool = false

# Store original collision settings for restoration
var original_collision_layer: int = 0
var original_collision_mask: int = 0
var original_hitbox_layer: int = 0
var original_hitbox_mask: int = 0

func Enter() -> void:
	print("PlayerDeathState: Player ", player.get_multiplayer_authority(), " has died")
	
	# Record death information
	death_position = player.global_position
	death_time = _get_current_time()
	items_dropped = false
	
	# Stop player movement completely
	player.velocity = Vector2.ZERO
	
	# Immediately remove player from the game world
	_remove_player_from_world()
	
	# Handle death based on authority
	if multiplayer.is_server():
		# Server handles death processing directly
		_handle_server_death()
	else:
		# Client requests death processing from server (if not already triggered by DeathSystem)
		_request_death_processing()

func Exit() -> void:
	print("PlayerDeathState: Player ", player.get_multiplayer_authority(), " exiting death state")
	
	# Restore player to the game world
	_restore_player_to_world()
	
	# Clean up death state
	items_dropped = false

func Process(_delta: float) -> PlayerState:
	# Death state processing - player cannot move or act
	player.velocity = Vector2.ZERO
	
	# Stay in death state until server initiates respawn process
	# The transition to respawn_wait will be triggered by DeathSystem
	return null

func Physics(_delta: float) -> PlayerState:
	# No physics processing during death
	player.velocity = Vector2.ZERO
	return null

func HandleInput(_event: InputEvent) -> PlayerState:
	# No input handling during death state
	# Player must wait for respawn delay to complete
	return null

# =============================================================================
# DEATH PROCESSING METHODS
# =============================================================================

func _handle_server_death() -> void:
	"""Server-side death processing"""
	var player_id = player.get_multiplayer_authority()
	
	# Check if death was already processed by DeathSystem to avoid duplication
	if DeathSystem.player_death_cooldowns.has(player_id):
		print("PlayerDeathState: Death already processed by DeathSystem, skipping duplicate processing")
		return
		
	# Trigger death event in DeathSystem (this will handle the full death process)
	DeathSystem._handle_player_death(player_id, death_position)

func _request_death_processing() -> void:
	"""Client requests death processing from server"""
	# Send death request to server via RPC
	DeathSystem.request_player_death.rpc(death_position)

func _extract_inventory_items() -> Array:
	"""Extract items from player inventory for dropping"""
	var items_to_drop: Array = []
	
	# Get player's inventory data
	var inventory_data = _get_player_inventory()
	if inventory_data == null:
		print("PlayerDeathState: No inventory found for player")
		return items_to_drop
	
	# Extract all items from inventory and sync with PlayerManager
	var player_id = player.get_multiplayer_authority()
	if inventory_data.has_method("extract_all_items_for_death_with_manager_sync"):
		items_to_drop = inventory_data.extract_all_items_for_death_with_manager_sync(player_id)
	else:
		items_to_drop = inventory_data.extract_all_items_for_death()
	
	# Add source player information to each item
	for item in items_to_drop:
		item["source_player_id"] = player_id
		item["spawn_time"] = death_time
	
	print("PlayerDeathState: Extracted ", items_to_drop.size(), " items from inventory")
	return items_to_drop

func _get_player_inventory() -> InventoryData:
	"""Get the player's inventory data"""
	var player_id = player.get_multiplayer_authority()
	
	# Get inventory from PlayerManager's players_data dictionary
	if PlayerManager.players_data.has(player_id):
		var player_data = PlayerManager.players_data[player_id]
		if player_data.has("inventory"):
			var inventory_dict = player_data["inventory"]
			
			# Convert PlayerManager inventory format to InventoryData format
			return _convert_manager_inventory_to_data(inventory_dict)
	return null

func _convert_manager_inventory_to_data(inventory_dict: Dictionary) -> InventoryData:
	"""Convert PlayerManager inventory dictionary to InventoryData format"""
	var inventory_data = InventoryData.new()
	inventory_data.slots = []
	inventory_data.slots.resize(PlayerManager.max_inv_slots)  # Use configured slot count
	
	# Fill slots with items from PlayerManager inventory
	var slot_index = 0
	for item_resource_path in inventory_dict.keys():
		if slot_index >= PlayerManager.max_inv_slots:
			break  # Don't exceed available slots
		
		var quantity = inventory_dict[item_resource_path]
		var item_data = ItemDatabase.get_item(item_resource_path)
		
		if item_data and quantity > 0:
			var slot = SlotData.new()
			slot.item_data = item_data
			slot.quantity = quantity
			inventory_data.slots[slot_index] = slot
			slot_index += 1
	
	print("PlayerDeathState: Converted PlayerManager inventory - found ", slot_index, " items")
	return inventory_data

func _get_current_time() -> float:
	"""Get current timestamp"""
	var time_dict = Time.get_time_dict_from_system()
	return float(time_dict.hour * 3600 + time_dict.minute * 60 + time_dict.second)

# =============================================================================
# STATE TRANSITION HELPERS
# =============================================================================

func transition_to_respawn_wait() -> PlayerState:
	"""Transition to respawn wait state (called by external systems)"""
	return respawn_wait

# =============================================================================
# NETWORK INTEGRATION
# =============================================================================

func on_death_processed_by_server() -> void:
	"""Called when server has processed the death event"""
	print("PlayerDeathState: Death processed by server, waiting for respawn delay")
	
	# Could trigger visual/audio feedback here
	# The actual state transition will happen when DeathSystem starts respawn delay

# =============================================================================
# PLAYER REMOVAL AND RESTORATION
# =============================================================================

func _remove_player_from_world() -> void:
	"""Immediately remove player from the game world - hide and disable all collisions"""
	print("PlayerDeathState: Removing player ", player.get_multiplayer_authority(), " from world")
	
	# Store original collision settings for restoration
	original_collision_layer = player.get_collision_layer()
	original_collision_mask = player.get_collision_mask()
	
	var hitbox = player.get_node_or_null("Hitbox")
	if hitbox:
		original_hitbox_layer = hitbox.get_collision_layer()
		original_hitbox_mask = hitbox.get_collision_mask()
	
	# Hide all visual components
	if player.sprite:
		player.sprite.visible = false
	
	# Hide the player label/name
	if player.label:
		player.label.visible = false
	
	# Hide shadow sprite if it exists
	var shadow_sprite = player.get_node_or_null("ShadowSprite")
	if shadow_sprite:
		shadow_sprite.visible = false
	
	# Disable ALL collision shapes - main player collision
	var collision_shape = player.get_node_or_null("CollisionShape2D")
	if collision_shape:
		collision_shape.disabled = true
		print("PlayerDeathState: Disabled main collision shape")
	
	# Disable hitbox collisions
	if hitbox:
		hitbox.set_collision_layer(0)
		hitbox.set_collision_mask(0)
		
		# Also disable the hitbox's collision shape
		var hitbox_collision = hitbox.get_node_or_null("CollisionShape2D")
		if hitbox_collision:
			hitbox_collision.disabled = true
		print("PlayerDeathState: Disabled hitbox collisions")
	
	# Disable the main player's physics layers
	player.set_collision_layer(0)
	player.set_collision_mask(0)
	
	# Disable camera if this is the authority player
	#if player.is_multiplayer_authority() and player.camera_2d:
		#player.camera_2d.enabled = false
		#print("PlayerDeathState: Disabled camera for authority player")
	
	# Stop any ongoing animations
	if player.animation_player:
		player.animation_player.stop()
	
	print("PlayerDeathState: Player completely removed from world")

func _restore_player_to_world() -> void:
	"""Restore player to the game world - show and re-enable all collisions"""
	print("PlayerDeathState: Restoring player ", player.get_multiplayer_authority(), " to world")
	
	# Restore all visual components
	if player.sprite:
		player.sprite.visible = true
	
	# Restore the player label/name
	if player.label:
		player.label.visible = true
	
	# Restore shadow sprite if it was visible before
	var shadow_sprite = player.get_node_or_null("ShadowSprite")
	if shadow_sprite:
		# Only restore if shadow system is active (check if sprite was meant to be visible)
		# For now, keep it hidden unless explicitly needed
		pass
	
	# Re-enable main collision shape
	var collision_shape = player.get_node_or_null("CollisionShape2D")
	if collision_shape:
		collision_shape.disabled = false
		print("PlayerDeathState: Re-enabled main collision shape")
	
	# Re-enable hitbox collisions with original layers
	var hitbox = player.get_node_or_null("Hitbox")
	if hitbox:
		# Restore original collision layers
		hitbox.set_collision_layer(original_hitbox_layer)
		hitbox.set_collision_mask(original_hitbox_mask)
		
		# Re-enable the hitbox's collision shape
		var hitbox_collision = hitbox.get_node_or_null("CollisionShape2D")
		if hitbox_collision:
			hitbox_collision.disabled = false
		print("PlayerDeathState: Re-enabled hitbox collisions")
	
	# Restore the main player's original physics layers
	player.set_collision_layer(original_collision_layer)
	player.set_collision_mask(original_collision_mask)
	
	# Re-enable camera if this is the authority player
	if player.is_multiplayer_authority() and player.camera_2d:
		player.camera_2d.enabled = true
		player.camera_2d.make_current()
		print("PlayerDeathState: Re-enabled camera for authority player")
	
	print("PlayerDeathState: Player fully restored to world")

# =============================================================================
# SIGNAL CONNECTIONS (set up in _ready if needed)
# =============================================================================

func _ready() -> void:
	super._ready()
	
	# Connect to death-related signals if needed
	# SignalBus.player_death_processed.connect(_on_death_processed)
