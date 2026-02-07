class_name PickupSpawner extends MultiplayerSpawner

@export var pickup_scene: PackedScene
var pickup_counter: int = 0
var active_pickups: Dictionary = {}  # pickup_name -> pickup_node reference

func _enter_tree():
	# Add to group for easy lookup by DeathSystem
	add_to_group("multiplayer_pickup_spawner")

func _ready():
	# Set up the spawner function
	spawn_function = _custom_spawn
	
	# Connect to signals
	SignalBus.on_item_drop.connect(on_item_drop)
	
	# Set authority when multiplayer is ready
	_setup_authority()

func _setup_authority():
	# Wait for multiplayer to be properly initialized
	if not multiplayer.has_multiplayer_peer():
		# Try again after a frame
		call_deferred("_setup_authority")
		return
	
	# Only set authority on server
	if multiplayer.is_server():
		set_multiplayer_authority(1)
		print("PickupSpawner authority set to server")

func _custom_spawn(data: Dictionary) -> Node2D:
	# Validate required data before spawning
	if not data.has("item_type") or not data.has("position"):
		print("PickupSpawner: Invalid spawn data, missing required fields")
		return null
	
	var item_data = ItemDatabase.get_item(data.item_type)
	if not item_data:
		print("PickupSpawner: Could not load item data for ", data.item_type)
		return null
	
	var p = pickup_scene.instantiate()
	p.item_data = item_data
	p.position = data.position
	
	# Set velocity if provided for physics effect
	if data.has("velocity"):
		p.velocity = data.velocity
	
	# Assign unique name to prevent naming conflicts
	pickup_counter += 1
	p.name = "pickup_" + str(pickup_counter)
	
	# Track active pickups for cleanup management
	active_pickups[p.name] = p
	
	# Connect to pickup's tree_exiting signal for cleanup tracking
	if p.tree_exiting:
		p.tree_exiting.connect(_on_pickup_deleted.bind(p.name))
	
	print("PickupSpawner: Spawning pickup ", p.name, " at ", data.position)
	
	return p

func spawn_pickup(data: Dictionary):
	if !multiplayer.is_server(): 
		print("PickupSpawner: spawn_pickup called on client, ignoring")
		return
	
	# Validate spawning conditions
	if not is_inside_tree():
		print("PickupSpawner: Cannot spawn pickup, spawner not in scene tree")
		return
	
	print("PickupSpawner: Spawning pickup with data: ", data)
	
	# Use try-catch equivalent for safer spawning
	var spawned_node = spawn(data)
	if spawned_node == null:
		print("PickupSpawner: Failed to spawn pickup with data: ", data)

func on_item_drop(pickup_data: Dictionary) -> void:
	if !multiplayer.is_server(): 
		print("PickupSpawner: on_item_drop called on client, ignoring")
		return
	
	print("PickupSpawner: Processing item drop: ", pickup_data)
	
	# Validate pickup data before spawning
	if not pickup_data.has("item_type") or not pickup_data.has("position"):
		print("PickupSpawner: Invalid pickup data, missing required fields: ", pickup_data)
		return
	
	spawn_pickup(pickup_data)

func _on_pickup_deleted(pickup_name: String):
	"""Track when pickups are deleted to clean up references"""
	if active_pickups.has(pickup_name):
		active_pickups.erase(pickup_name)
		print("PickupSpawner: Tracked pickup deletion: ", pickup_name)

func get_active_pickup(pickup_name: String) -> Node:
	"""Get an active pickup by name, returns null if not found or deleted"""
	if active_pickups.has(pickup_name):
		var pickup = active_pickups[pickup_name]
		# Validate the pickup is still valid
		if is_instance_valid(pickup) and pickup.is_inside_tree():
			return pickup
		else:
			# Clean up invalid reference
			active_pickups.erase(pickup_name)
	return null

func cleanup_invalid_pickups():
	"""Clean up any invalid pickup references"""
	var to_remove = []
	for pickup_name in active_pickups.keys():
		var pickup = active_pickups[pickup_name]
		if not is_instance_valid(pickup) or not pickup.is_inside_tree():
			to_remove.append(pickup_name)
	
	for pickup_name in to_remove:
		active_pickups.erase(pickup_name)
		print("PickupSpawner: Cleaned up invalid pickup reference: ", pickup_name)
