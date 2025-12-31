extends MultiplayerSpawner

@export var network_player: PackedScene

func _ready() -> void:
	multiplayer.peer_connected.connect(spawn_player)

	# Here we connect to the "host_started" signal in the high_level_network_handler class.
	Lobby.host_started.connect(spawn_host_player)


func spawn_player(id: int) -> void:
	if !multiplayer.is_server(): return
	
	print("spawning player")

	var player: Node = network_player.instantiate()

	# Node name is synchronized through MultiplayerSpawner, we can use this to set authority to the player.
	player.name = str(id)

	get_node(spawn_path).call_deferred("add_child", player)


# In this function, which is connected to the "host_started" signal in the high_level_network_handler
# class, we spawn the server player. Easy right?
func spawn_host_player() -> void:
	if !multiplayer.is_server(): return
	
	print("spawning host player")
	
	spawn_player(multiplayer.get_unique_id())
