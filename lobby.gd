extends Node

signal host_started()

const PORT: int = 42069 # Below 65535 (16-bit unsigned max value)

var peer: ENetMultiplayerPeer

func start_server() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer


func start_client() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = peer


# To create a server+player, or host player, we create a new function "start_host()".
# This function then starts the server like normal, but also calls a signal "host_started".
# Since this is an autoloaded class, other functions can connect to this signal, like I did
# in the "high_level_player_spawner". More comments there.
func start_host() -> void:
	start_server()
	host_started.emit()
