extends Node
# Headless Client Test Script
# This script connects to a test server and simulates player behavior

signal client_connected()
signal client_disconnected()
signal connection_failed()

const PORT: int = 42069
const SERVER_IP: String = "localhost"
const TEST_TIMEOUT: float = 180.0  # 3 minutes timeout
const MOVEMENT_INTERVAL: float = 1.0  # Send movement updates every second

var peer: ENetMultiplayerPeer
var test_start_time: float
var log_file: FileAccess
var player_name: String
var client_id: String
var movement_timer: Timer
var test_actions: Array[String] = []

# Simulated player position for movement testing
var simulated_position: Vector2 = Vector2.ZERO
var movement_direction: Vector2 = Vector2.RIGHT

func _ready():
	# Generate a unique client ID for this test instance
	client_id = "client_" + str(randi() % 10000)
	player_name = "TestPlayer_" + client_id
	
	# Initialize logging
	setup_logging()
	
	print("[CLIENT_TEST] Starting headless client test as %s..." % player_name)
	test_start_time = Time.get_unix_time_from_system()
	
	# Connect multiplayer signals
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	# Start connection process
	connect_to_server()
	
	# Set up test timeout
	var timer = Timer.new()
	timer.wait_time = TEST_TIMEOUT
	timer.one_shot = true
	timer.timeout.connect(_on_test_timeout)
	add_child(timer)
	timer.start()
	
	# Set up movement simulation timer
	movement_timer = Timer.new()
	movement_timer.wait_time = MOVEMENT_INTERVAL
	movement_timer.timeout.connect(_on_movement_timer)
	add_child(movement_timer)

func setup_logging():
	var log_dir = "res://test_harness/logs/"
	if not DirAccess.dir_exists_absolute(log_dir):
		DirAccess.open("res://").make_dir_recursive("test_harness/logs")
	
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	var log_path = log_dir + "client_test_" + client_id + "_" + timestamp + ".log"
	log_file = FileAccess.open(log_path, FileAccess.WRITE)
	
	if log_file:
		log_message("CLIENT_TEST", "Logging started for client %s" % client_id)
	else:
		print("[CLIENT_TEST] Failed to create log file at: " + log_path)

func log_message(category: String, message: String):
	var timestamp = Time.get_datetime_string_from_system()
	var log_entry = "[%s] %s (%s): %s" % [timestamp, category, client_id, message]
	print(log_entry)
	
	if log_file:
		log_file.store_line(log_entry)
		log_file.flush()

func connect_to_server():
	peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(SERVER_IP, PORT)
	
	if result == OK:
		multiplayer.multiplayer_peer = peer
		log_message("CLIENT", "Attempting to connect to server at %s:%d" % [SERVER_IP, PORT])
	else:
		log_message("CLIENT_ERROR", "Failed to create client. Error code: %d" % result)
		get_tree().quit(1)

func _on_connected_to_server():
	log_message("NETWORK", "Successfully connected to server")
	client_connected.emit()
	
	# Set player data
	if has_node("/root/PlayerData"):
		var player_data = get_node("/root/PlayerData")
		player_data.player_name = player_name
		log_message("CLIENT", "Set player name to %s" % player_name)
	
	# Start the lobby client if available
	if has_node("/root/Lobby"):
		get_node("/root/Lobby").start_client()
		log_message("CLIENT", "Started lobby client")
	
	# Start movement simulation
	movement_timer.start()
	log_message("CLIENT", "Started movement simulation")
	
	# Schedule test actions
	schedule_test_actions()

func _on_connection_failed():
	log_message("NETWORK_ERROR", "Failed to connect to server")
	connection_failed.emit()
	shutdown_client()

func _on_server_disconnected():
	log_message("NETWORK", "Disconnected from server")
	client_disconnected.emit()
	shutdown_client()

func schedule_test_actions():
	# Schedule various test actions to simulate real player behavior
	var actions = [
		{"delay": 5.0, "action": "send_test_rpc"},
		{"delay": 10.0, "action": "simulate_inventory_action"},
		{"delay": 15.0, "action": "simulate_spell_cast"},
		{"delay": 20.0, "action": "simulate_building_interaction"},
		{"delay": 30.0, "action": "stress_test_movement"}
	]
	
	for action in actions:
		var action_timer = Timer.new()
		action_timer.wait_time = action.delay
		action_timer.one_shot = true
		action_timer.timeout.connect(func(): execute_test_action(action.action))
		add_child(action_timer)
		action_timer.start()
		
		log_message("SCHEDULER", "Scheduled action '%s' for %.1f seconds" % [action.action, action.delay])

func execute_test_action(action: String):
	log_message("ACTION", "Executing test action: %s" % action)
	test_actions.append(action)
	
	match action:
		"send_test_rpc":
			send_test_rpc()
		"simulate_inventory_action":
			simulate_inventory_action()
		"simulate_spell_cast":
			simulate_spell_cast()
		"simulate_building_interaction":
			simulate_building_interaction()
		"stress_test_movement":
			stress_test_movement()

func send_test_rpc():
	if multiplayer.has_multiplayer_peer():
		# Call the server's test RPC function
		var message = "Hello from %s at %s" % [client_id, Time.get_datetime_string_from_system()]
		rpc_id(1, "test_rpc_call", message)  # Call on server (ID 1)
		log_message("RPC", "Sent test RPC to server: %s" % message)

func simulate_inventory_action():
	# Simulate inventory interaction
	log_message("SIMULATION", "Simulating inventory action")
	if has_node("/root/SignalBus"):
		var signal_bus = get_node("/root/SignalBus")
		if signal_bus.has_signal("inventory_updated"):
			signal_bus.inventory_updated.emit()
			log_message("SIMULATION", "Emitted inventory_updated signal")

func simulate_spell_cast():
	# Simulate spell casting
	log_message("SIMULATION", "Simulating spell cast")
	if has_node("/root/SignalBus"):
		var signal_bus = get_node("/root/SignalBus")
		if signal_bus.has_signal("spell_cast"):
			signal_bus.spell_cast.emit("fireball", simulated_position)
			log_message("SIMULATION", "Emitted spell_cast signal")

func simulate_building_interaction():
	# Simulate building interaction
	log_message("SIMULATION", "Simulating building interaction")
	if has_node("/root/BuildingManager"):
		log_message("SIMULATION", "BuildingManager available for interaction")

func stress_test_movement():
	# Increase movement frequency for stress testing
	movement_timer.wait_time = 0.1  # 10 times per second
	log_message("STRESS_TEST", "Increased movement frequency for stress testing")

func _on_movement_timer():
	simulate_movement()

func simulate_movement():
	# Update simulated position
	simulated_position += movement_direction * 10.0
	
	# Change direction occasionally
	if randf() < 0.1:  # 10% chance to change direction
		movement_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		log_message("MOVEMENT", "Changed direction to %s" % movement_direction)
	
	# Send movement update to server if connected
	if multiplayer.has_multiplayer_peer() and multiplayer.get_multiplayer_peer().get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		rpc_id(1, "player_movement_update", simulated_position)
		
		# Log movement less frequently to avoid spam
		if int(Time.get_unix_time_from_system()) % 10 == 0:
			log_message("MOVEMENT", "Position: %s" % simulated_position)

func _on_test_timeout():
	log_message("CLIENT_TEST", "Test timeout reached (%f seconds)" % TEST_TIMEOUT)
	shutdown_client()

func shutdown_client():
	log_message("CLIENT_TEST", "Shutting down test client...")
	log_message("STATS", "Actions completed: %d" % test_actions.size())
	log_message("STATS", "Final position: %s" % simulated_position)
	
	export_test_results()
	
	if peer:
		peer.close()
	
	if log_file:
		log_file.close()
	
	get_tree().quit()

func _process(_delta):
	# Log periodic status
	var current_time = Time.get_unix_time_from_system()
	if int(current_time) % 60 == 0:  # Every minute
		var connection_status = "disconnected"
		if multiplayer.has_multiplayer_peer():
			var status = multiplayer.get_multiplayer_peer().get_connection_status()
			match status:
				MultiplayerPeer.CONNECTION_CONNECTING:
					connection_status = "connecting"
				MultiplayerPeer.CONNECTION_CONNECTED:
					connection_status = "connected"
				MultiplayerPeer.CONNECTION_DISCONNECTED:
					connection_status = "disconnected"
		
		log_message("STATUS", "Client status: %s, Actions: %d" % [connection_status, test_actions.size()])

# RPC handlers for server responses
@rpc("authority", "call_local")
func server_response(message: String):
	log_message("SERVER_RESPONSE", "Received: %s" % message)

# Export test results
func export_test_results():
	if not log_file:
		return
		
	var test_duration = Time.get_unix_time_from_system() - test_start_time
	var results = {
		"client_id": client_id,
		"player_name": player_name,
		"test_duration": test_duration,
		"actions_completed": test_actions.size(),
		"final_position": str(simulated_position),
		"connection_established": multiplayer.has_multiplayer_peer(),
		"successful_rpcs": test_actions.count("send_test_rpc")
	}
	
	log_message("RESULTS", "Test completed: %s" % results)
