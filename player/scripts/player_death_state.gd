class_name PlayerDeathState extends PlayerState

@onready var respawn_wait: PlayerState = $"../respawn_wait"

# Death state properties
var death_position: Vector2 = Vector2.ZERO
var death_time: float = 0.0
var items_dropped: bool = false

func Enter() -> void:
	print("PlayerDeathState: Player ", player.get_multiplayer_authority(), " has died")
	
	# Record death information
	death_position = player.global_position
	death_time = _get_current_time()
	items_dropped = false
	
	# Stop player movement
	player.velocity = Vector2.ZERO
	
	# Hide player sprite instead of playing death animation (since death animations don't exist)
	if player.sprite != null:
		player.sprite.visible = false
		print("PlayerDeathState: Player sprite hidden")
	
	# Handle death based on authority
	if multiplayer.is_server():
		# Server handles death processing directly
		_handle_server_death()
	else:
		# Client requests death processing from server
		_request_death_processing()

func Exit() -> void:
	print("PlayerDeathState: Player ", player.get_multiplayer_authority(), " exiting death state")
	
	# Restore player sprite visibility
	if player.sprite != null:
		player.sprite.visible = true
		print("PlayerDeathState: Player sprite restored to visible")
	
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
	
	# Extract inventory items for dropping
	var inventory_items = _extract_inventory_items()
	
	# Drop items at death location
	if not inventory_items.is_empty():
		_drop_items_at_death_location(inventory_items)
		items_dropped = true
	
	# Trigger death event in DeathSystem
	DeathSystem._handle_player_death(player_id, death_position, "snake_mode_death")

func _request_death_processing() -> void:
	"""Client requests death processing from server"""
	# Send death request to server via RPC
	DeathSystem.request_player_death.rpc(death_position, "snake_mode_death")

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
	
	print("PlayerDeathState: No inventory found in PlayerManager for player ", player_id)
	return _create_mock_inventory()

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

func _create_mock_inventory() -> InventoryData:
	"""Create a mock inventory for testing purposes"""
	var mock_inventory = InventoryData.new()
	mock_inventory.slots = []
	mock_inventory.slots.resize(10)  # 10 slot inventory
	
	# Add a test item to slot 0
	var test_slot = SlotData.new()
	test_slot.item_data = ItemDatabase.get_item("res://pickups/d20.tres")
	test_slot.quantity = 1
	mock_inventory.slots[0] = test_slot
	
	return mock_inventory

func _drop_items_at_death_location(items: Array) -> void:
	"""Create dropped item instances at death location"""
	if items.is_empty():
		return
	
	print("PlayerDeathState: Dropping ", items.size(), " items at ", death_position)
	
	# The actual item creation will be handled by DeathSystem
	# This method just prepares the items for dropping
	SignalBus.inventory_dropped.emit(player.get_multiplayer_authority(), death_position)

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
# SIGNAL CONNECTIONS (set up in _ready if needed)
# =============================================================================

func _ready() -> void:
	super._ready()
	
	# Connect to death-related signals if needed
	# SignalBus.player_death_processed.connect(_on_death_processed)