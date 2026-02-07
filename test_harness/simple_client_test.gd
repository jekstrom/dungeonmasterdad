extends Node
# Simple Client Test Script  
# Minimal headless client for network testing

const PORT: int = 42069
const SERVER_IP: String = "localhost"

var peer: ENetMultiplayerPeer
var client_id: String
var player_name: String
var start_time: float
var connected: bool = false
var message_count: int = 0

func _ready():
	# Generate unique client ID
	client_id = "client_" + str(randi() % 10000)
	player_name = "TestPlayer_" + client_id
	start_time = Time.get_unix_time_from_system()
	
	print("[SIMPLE_CLIENT] Starting client %s..." % client_id)
	
	# Connect multiplayer signals
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	# Set player name if PlayerData exists
	if has_node("/root/PlayerData"):
		get_node("/root/PlayerData").player_name = player_name
		print("[SIMPLE_CLIENT] Set player name: %s" % player_name)
	
	# Wait a frame then connect
	await get_tree().process_frame
	connect_to_server()
	
	# Set up periodic message sending
	var timer = Timer.new()
	timer.wait_time = 5.0  # Send message every 5 seconds
	timer.timeout.connect(send_test_message)
	add_child(timer)
	timer.start()

func connect_to_server():
	peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(SERVER_IP, PORT)
	
	if result == OK:
		multiplayer.multiplayer_peer = peer
		print("[SIMPLE_CLIENT] Connecting to %s:%d..." % [SERVER_IP, PORT])
	else:
		print("[SIMPLE_CLIENT] Failed to create client. Error: %d" % result)

func _on_connected_to_server():
	connected = true
	var connect_time = Time.get_unix_time_from_system() - start_time
	print("[SIMPLE_CLIENT] Connected to server! (Connection time: %.1fs)" % connect_time)
	
	# Start lobby client if available
	if has_node("/root/Lobby"):
		get_node("/root/Lobby").start_client()
		print("[SIMPLE_CLIENT] Lobby client started")

func _on_connection_failed():
	print("[SIMPLE_CLIENT] Failed to connect to server")

func _on_server_disconnected():
	connected = false
	print("[SIMPLE_CLIENT] Disconnected from server")

func send_test_message():
	if connected:
		message_count += 1
		var uptime = Time.get_unix_time_from_system() - start_time
		var message = "Hello from %s - Message #%d (uptime: %.1fs)" % [client_id, message_count, uptime]
		rpc_id(1, "test_message", message)  # Send to server (ID 1)
		print("[SIMPLE_CLIENT] Sent message #%d" % message_count)

func _process(_delta):
	# Status update every 30 seconds
	var uptime = Time.get_unix_time_from_system() - start_time
	if int(uptime) % 30 == 0 and int(uptime) > 0:
		var status = "connected" if connected else "disconnected"
		print("[SIMPLE_CLIENT] Status: %s, messages sent: %d, uptime: %.1fs" % [status, message_count, uptime])