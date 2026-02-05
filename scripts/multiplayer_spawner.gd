extends MultiplayerSpawner

@export var network_player: PackedScene
@export var dm_player: PackedScene
@export var gremlin: PackedScene
@export var fireball_spell: PackedScene
@export var pickup_scene: PackedScene

func _ready() -> void:
	# Add to group for easy lookup by PlayerManager
	add_to_group("multiplayer_spawner")
	
	multiplayer.connected_to_server.connect(on_connected_ok)

	Lobby.host_started.connect(spawn_host_player)
	
	DmManager.spawn_gremlin_cast.connect(spawn_gremlin)

func on_connected_ok():
	var id = multiplayer.get_unique_id()
	spawn_player.rpc(id, PlayerData.player_name)

@rpc("any_peer", "reliable")
func spawn_player(id: int, player_name: String) -> void:
	if !multiplayer.is_server(): return
	
	await get_tree().process_frame
	
	var player: Node = network_player.instantiate()
	
	if !player_name or player_name.is_empty():
		player_name = "Paper Pusher"
	
	player.name = str(id)
	print("spawning player ", id, " ", player_name)
	player.sync_name = player_name
	
	var name_hash = player_name.hash()
	var rng = RandomNumberGenerator.new()
	rng.seed = name_hash
	var hue = rng.randf() 
	player.sync_color = Color.from_hsv(hue, 0.6, 0.9)
	
	get_node(spawn_path).add_child(player, true)
	player.add_to_group("players")
	PlayerManager.register_player(id, player_name)
	sync_global_state.rpc_id(id, DmManager.fantasy_level)

func spawn_gremlin() -> void:
	if !multiplayer.is_server(): return
	
	print("spawning gremlin")
	
	var new_gremlin: Node = gremlin.instantiate()

	get_node(spawn_path).call_deferred("add_child", new_gremlin, true)
	
func cast_spell(spell_id: String) -> void:
	if !multiplayer.is_server(): return
	
	print("casting spell ", spell_id)
	
	var spell: Node = fireball_spell.instantiate()

	get_node(spawn_path).call_deferred("add_child", spell, true)

func spawn_host_player(player_name: String) -> void:
	if !multiplayer.is_server(): return
	
	print("spawning dm player")
	if !player_name or player_name.is_empty():
		player_name = "DM"
	
	var dm: Node = dm_player.instantiate()
	dm.name = "dm"
	DmManager.dm_player_name = player_name
	
	get_node(spawn_path).call_deferred("add_child", dm)
	dm.add_to_group("players")
	PlayerManager.register_player(1, player_name)

@rpc("authority", "call_local", "reliable")
func sync_global_state(f: int):
	DmManager.fantasy_level = f

# Spawn a pickup item that will be synchronized to all clients
func spawn_pickup_item(item_data: ItemData, position: Vector2, velocity: Vector2 = Vector2.ZERO) -> Node:
	if not multiplayer.is_server():
		print("WARNING: spawn_pickup_item called on non-server")
		return null
	
	if not pickup_scene:
		print("ERROR: pickup_scene not set in MultiplayerSpawner")
		return null
	
	print("SERVER: Spawning pickup for ", item_data.name, " at ", position)
	
	var pickup = pickup_scene.instantiate()
	if not pickup:
		print("ERROR: Failed to instantiate pickup scene")
		return null
	
	# Set pickup properties before adding to scene
	pickup.item_data = item_data
	pickup.global_position = position
	pickup.velocity = velocity
	
	# Add to world through spawner - this should sync to all clients
	# Using the same pattern as other spawn methods in this file
	get_node(spawn_path).call_deferred("add_child", pickup, true)
	
	print("SERVER: Spawned synced pickup for ", item_data.name, " at ", position)
	return pickup
