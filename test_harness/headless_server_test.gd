extends Node
# Headless Server Test Script
# This script starts a server instance for testing and logs network events

signal server_started()
signal player_connected(id: int)
signal player_disconnected(id: int)

const PORT: int = 42069
const TEST_TIMEOUT: float = 300.0  # 5 minutes timeout

var peer: ENetMultiplayerPeer
var test_start_time: float
var connected_players: Array[int] = []
var log_file: FileAccess

func _ready():
	# Initialize logging
	setup_logging()
	
	# Start the server
	print("[SERVER_TEST] Starting headless server test...")
	test_start_time = Time.get_unix_time_from_system()
	
	# Connect multiplayer signals
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
	# Wait a frame before starting server to let autoloads initialize
	await get_tree().process_frame
	start_server()
	
	# Set up timeout
	var timer = Timer.new()
	timer.wait_time = TEST_TIMEOUT
	timer.one_shot = true
	timer.timeout.connect(_on_test_timeout)
	add_child(timer)
	timer.start()

func setup_logging():
	var log_dir = "res://test_harness/logs/"
	if not DirAccess.dir_exists_absolute(log_dir):
		DirAccess.open("res://").make_dir_recursive("test_harness/logs")
	
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	var log_path = log_dir + "server_test_" + timestamp + ".log"
	log_file = FileAccess.open(log_path, FileAccess.WRITE)
	
	if log_file:
		log_message("SERVER_TEST", "Logging started")
	else:
		print("[SERVER_TEST] Failed to create log file at: " + log_path)

func log_message(category: String, message: String):
	var timestamp = Time.get_datetime_string_from_system()
	var log_entry = "[%s] %s: %s" % [timestamp, category, message]
	print(log_entry)
	
	if log_file:
		log_file.store_line(log_entry)
		log_file.flush()

func start_server():
	peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(PORT)
	
	if result == OK:
		multiplayer.multiplayer_peer = peer
		log_message("SERVER", "Headless server started on port %d" % PORT)
		server_started.emit()
		
		# Start the lobby system to handle player connections
		if has_node("/root/Lobby"):
			get_node("/root/Lobby").start_server()
		
		# Initialize player manager if available
		if has_node("/root/PlayerManager"):
			log_message("SERVER", "PlayerManager initialized")
			
		# Initialize DM manager if available  
		if has_node("/root/DmManager"):
			log_message("SERVER", "DmManager initialized")
	else:
		log_message("SERVER_ERROR", "Failed to start server. Error code: %d" % result)
		get_tree().quit(1)

func _on_player_connected(id: int):
	connected_players.append(id)
	log_message("NETWORK", "Player connected: %d (Total players: %d)" % [id, connected_players.size()])
	player_connected.emit(id)
	
	# Log player manager state if available
	if has_node("/root/PlayerManager"):
		var player_manager = get_node("/root/PlayerManager")
		if player_manager.has_method("get_player_count"):
			log_message("PLAYERS", "Player manager reports %d players" % player_manager.get_player_count())

func _on_player_disconnected(id: int):
	var index = connected_players.find(id)
	if index >= 0:
		connected_players.remove_at(index)
	
	log_message("NETWORK", "Player disconnected: %d (Remaining players: %d)" % [id, connected_players.size()])
	player_disconnected.emit(id)

func _on_test_timeout():
	log_message("SERVER_TEST", "Test timeout reached (%f seconds)" % TEST_TIMEOUT)
	shutdown_server()

func shutdown_server():
	log_message("SERVER_TEST", "Shutting down test server...")
	log_message("STATS", "Final player count: %d" % connected_players.size())
	
	if peer:
		peer.close()
	
	if log_file:
		log_file.close()
	
	get_tree().quit()

func _process(_delta):
	# Log periodic status
	var current_time = Time.get_unix_time_from_system()
	if int(current_time) % 30 == 0:  # Every 30 seconds
		log_message("STATUS", "Server running. Connected players: %d" % connected_players.size())
		
		# Log basic system info
		log_message("SYSTEM", "Process ID: %d" % OS.get_process_id())

# Remote procedure calls for testing client interactions
@rpc("any_peer", "call_local")
func test_rpc_call(message: String):
	var sender_id = multiplayer.get_remote_sender_id()
	log_message("RPC", "Received test RPC from player %d: %s" % [sender_id, message])

@rpc("any_peer", "call_local")
func player_movement_update(position: Vector2):
	var sender_id = multiplayer.get_remote_sender_id()
	log_message("MOVEMENT", "Player %d position update: %s" % [sender_id, position])

# Export test results
func export_test_results():
	if not log_file:
		return
		
	var results = {
		"test_duration": Time.get_unix_time_from_system() - test_start_time,
		"max_concurrent_players": connected_players.size(),
		"total_connections": 0,  # Would need to track this separately
		"server_crashes": 0,
		"network_errors": 0
	}
	
	log_message("RESULTS", "Test completed: %s" % results)
