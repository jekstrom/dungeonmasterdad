extends Node
# Simple Server Test Script
# Minimal headless server for network testing

const PORT: int = 42069

var peer: ENetMultiplayerPeer
var connected_players: Array[int] = []
var start_time: float

func _ready():
	print("[SIMPLE_SERVER] Starting simple headless server...")
	start_time = Time.get_unix_time_from_system()
	
	# Connect multiplayer signals
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
	# Wait a frame for autoloads to initialize
	await get_tree().process_frame
	start_server()

func start_server():
	peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(PORT)
	
	if result == OK:
		multiplayer.multiplayer_peer = peer
		print("[SIMPLE_SERVER] Server started on port %d" % PORT)
		
		# Also start the game's lobby system
		if has_node("/root/Lobby"):
			get_node("/root/Lobby").start_server()
			print("[SIMPLE_SERVER] Lobby system started")
		
		print("[SIMPLE_SERVER] Server ready for connections")
	else:
		print("[SIMPLE_SERVER] Failed to start server. Error: %d" % result)

func _on_player_connected(id: int):
	connected_players.append(id)
	var uptime = Time.get_unix_time_from_system() - start_time
	print("[SIMPLE_SERVER] Player %d connected (Total: %d, Uptime: %.1fs)" % [id, connected_players.size(), uptime])

func _on_player_disconnected(id: int):
	var index = connected_players.find(id)
	if index >= 0:
		connected_players.remove_at(index)
	var uptime = Time.get_unix_time_from_system() - start_time
	print("[SIMPLE_SERVER] Player %d disconnected (Remaining: %d, Uptime: %.1fs)" % [id, connected_players.size(), uptime])

# Simple RPC for testing
@rpc("any_peer", "call_local")
func test_message(message: String):
	var sender_id = multiplayer.get_remote_sender_id()
	print("[SIMPLE_SERVER] RPC from player %d: %s" % [sender_id, message])

func _process(_delta):
	# Periodic status update every 30 seconds
	var uptime = Time.get_unix_time_from_system() - start_time
	if int(uptime) % 30 == 0 and int(uptime) > 0:
		print("[SIMPLE_SERVER] Status: %d players connected, uptime: %.1fs" % [connected_players.size(), uptime])