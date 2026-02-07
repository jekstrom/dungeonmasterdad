extends MultiplayerSpawner

@export var network_player: PackedScene
@export var dm_player: PackedScene
@export var gremlin: PackedScene
@export var fireball_spell: PackedScene

func _enter_tree() -> void:
	# Set server authority after multiplayer is ready
	if multiplayer.has_multiplayer_peer():
		set_multiplayer_authority(1)

func _ready() -> void:
	# Add to group for easy lookup by PlayerManager
	add_to_group("multiplayer_spawner")
	
	# Ensure server authority is set when multiplayer is ready
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		set_multiplayer_authority(1)
	
	multiplayer.connected_to_server.connect(on_connected_ok)

	# Only server should handle hosting and spawning
	if multiplayer.is_server():
		Lobby.host_started.connect(spawn_host_player)
		DmManager.spawn_gremlin_cast.connect(spawn_gremlin)

func on_connected_ok():
	var id = multiplayer.get_unique_id()
	spawn_player.rpc(id, PlayerData.player_name)

@rpc("any_peer", "reliable")
func spawn_player(id: int, player_name: String) -> void:
	if !multiplayer.is_server(): return
	
	# Check if player already exists and remove if so
	var existing_player = get_node(spawn_path).get_node_or_null(str(id))
	if existing_player:
		print("Removing existing player ", id, " before spawning new one")
		existing_player.queue_free()
		await existing_player.tree_exited
	
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
	
	for i in range(0, 10):  # Reduced number for testing
		var item_data = {
			"item_type" = "res://pickups/metal.tres",
			"position" = Vector2(i + 1 * 50, i * 30),  # Spread them out more
		}
		SignalBus.on_item_drop.emit(item_data)
		
	var cloak_data = {
		"item_type" = "res://pickups/cloak.tres",
		"position" = Vector2(-50, 15),  # Spread them out more
	}
	SignalBus.on_item_drop.emit(cloak_data)
		
@rpc("authority", "call_local", "reliable")
func sync_global_state(f: int):
	DmManager.fantasy_level = f
