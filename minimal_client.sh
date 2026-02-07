#!/bin/bash

echo "Starting minimal Dungeon Master Dad client test..."  
echo "Connecting to localhost:42069"
echo "Press Ctrl+C to stop"
echo "================================================"

cd /home/james/dungeon-master-dad

CLIENT_ID=$(shuf -i 1000-9999 -n 1)

# Create a minimal client script on the fly
cat > /tmp/minimal_client_test.gd << EOF
extends Node

const PORT: int = 42069
const SERVER_IP: String = "localhost" 
var peer: ENetMultiplayerPeer
var client_id: int = $CLIENT_ID
var message_count: int = 0

func _ready():
	print("[CLIENT-%d] Starting client..." % client_id)
	
	# Wait for autoloads
	await get_tree().process_frame
	
	peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(SERVER_IP, PORT)
	
	if result == OK:
		multiplayer.multiplayer_peer = peer
		print("[CLIENT-%d] Connecting to %s:%d..." % [client_id, SERVER_IP, PORT])
		
		# Connect signals
		multiplayer.connected_to_server.connect(_on_connected)
		multiplayer.connection_failed.connect(_on_connection_failed) 
		multiplayer.server_disconnected.connect(_on_disconnected)
		
		# Set up ping timer
		var timer = Timer.new()
		timer.wait_time = 3.0
		timer.timeout.connect(send_ping)
		add_child(timer)
		timer.start()
	else:
		print("[CLIENT-%d] ❌ Failed to create client: %d" % [client_id, result])

func _on_connected():
	print("[CLIENT-%d] ✅ Connected to server!" % client_id)

func _on_connection_failed():
	print("[CLIENT-%d] ❌ Connection failed!" % client_id)

func _on_disconnected():
	print("[CLIENT-%d] 🔴 Disconnected from server" % client_id)

func send_ping():
	if multiplayer.has_multiplayer_peer():
		message_count += 1
		var message = "Hello from client-%d (msg #%d)" % [client_id, message_count]
		rpc_id(1, "ping", message)
		print("[CLIENT-%d] 📤 Sent ping #%d" % [client_id, message_count])

@rpc("authority", "call_local")
func pong(message: String):
	print("[CLIENT-%d] 📨 PONG: %s" % [client_id, message])
EOF

# Create a minimal scene  
cat > /tmp/minimal_client.tscn << 'EOF'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="/tmp/minimal_client_test.gd" id="1"]

[node name="MinimalClient" type="Node"]
script = ExtResource("1")
EOF

# Run it
godot --path . --headless /tmp/minimal_client.tscn