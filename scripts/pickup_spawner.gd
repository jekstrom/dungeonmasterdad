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
	
	print("PickupSpawner: Spawning pickup with data: ", data)
	var p: Node2D = pickup_scene.instantiate()
	p.item_data = item_data
	p.position = data.position
	if data.has("velocity"):
		p.velocity = data.velocity
	
	pickup_counter += 1
	p.name = "pickup_" + str(pickup_counter)
	
	# Track active pickups for cleanup management
	active_pickups[p.name] = p
	
	return p

func spawn_pickup(data: Dictionary):
	if !multiplayer.is_server(): 
		print("PickupSpawner: spawn_pickup called on client, ignoring")
		return
	
	# Validate spawning conditions
	if not is_inside_tree():
		print("PickupSpawner: Cannot spawn pickup, spawner not in scene tree")
		return
	
	var pickup_result = ItemPickupPool.get_pickup(data.item_type, data.position, data.get("velocity", Vector2.ZERO))
	if !pickup_result.is_pooled:
		var spawned_node = spawn(data)
		if spawned_node == null:
			print("PickupSpawner: Failed to spawn pickup with data: ", data)

func on_item_drop(pickup_data: Dictionary) -> void:
	if !multiplayer.is_server(): 
		print("PickupSpawner: on_item_drop called on client, ignoring")
		return
		
	if not pickup_data.has("item_type") or not pickup_data.has("position"):
		print("PickupSpawner: Invalid pickup data, missing required fields: ", pickup_data)
		return
	
	spawn_pickup(pickup_data)
