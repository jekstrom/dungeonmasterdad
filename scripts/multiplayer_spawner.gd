extends MultiplayerSpawner

@export var network_player: PackedScene
@export var dm_player: PackedScene
@export var gremlin: PackedScene
var player_name: String = ""

func _ready() -> void:
	multiplayer.peer_connected.connect(spawn_player)

	# Here we connect to the "host_started" signal in the high_level_network_handler class.
	Lobby.host_started.connect(spawn_host_player)
	
	DmManager.spawn_gremlin_cast.connect(spawn_gremlin)
	
	SignalBus.on_name_changed.connect(on_name_changed)

func on_name_changed(new_name: String) -> void:
	print("setting player name to ", new_name)
	player_name = new_name

func spawn_player(id: int) -> void:
	if !multiplayer.is_server(): return
	
	var player: Node = network_player.instantiate()

	# Node name is synchronized through MultiplayerSpawner, we can use this to set authority to the player.
	player.name = str(id)
	print("spawning player ", id)
	PlayerManager.register_player(id, player_name)

	get_node(spawn_path).call_deferred("add_child", player)
	sync_global_state.rpc_id(id, DmManager.fantasy_level)
	
func spawn_gremlin() -> void:
	if !multiplayer.is_server(): return
	
	print("spawning gremlin")
	
	var new_gremlin: Node = gremlin.instantiate()

	# Node name is synchronized through MultiplayerSpawner, we can use this to set authority to the player.
	# gremlin.name = str(id)

	get_node(spawn_path).call_deferred("add_child", new_gremlin, true)

# In this function, which is connected to the "host_started" signal in the high_level_network_handler
# class, we spawn the server player. Easy right?
func spawn_host_player() -> void:
	if !multiplayer.is_server(): return
	
	print("spawning dm player")
	
	var dm: Node = dm_player.instantiate()
	dm.name = "dm"
	PlayerManager.register_player(1, player_name)
	DmManager.dm_player_name = player_name
	
	get_node(spawn_path).call_deferred("add_child", dm)

@rpc("authority", "call_local", "reliable")
func sync_global_state(f: int):
	DmManager.fantasy_level = f
