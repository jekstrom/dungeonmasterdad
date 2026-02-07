#!/bin/bash

echo "Starting minimal Dungeon Master Dad server test..."
echo "Pure networking test - port 42069"
echo "Press Ctrl+C to stop"
echo "================================================"

cd /home/james/dungeon-master-dad

# Create a minimal test script on the fly
cat > /tmp/minimal_server_test.gd << 'EOF'
extends Node

const PORT: int = 42069
var peer: ENetMultiplayerPeer

func _ready():
	print("[MINIMAL] Starting server on port %d..." % PORT)
	
	# Wait for autoloads
	await get_tree().process_frame
	
	peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(PORT)
	
	if result == OK:
		multiplayer.multiplayer_peer = peer
		print("[MINIMAL] ✅ Server started successfully!")
		print("[MINIMAL] Waiting for clients to connect...")
		
		# Connect signals
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	else:
		print("[MINIMAL] ❌ Failed to start server: %d" % result)

func _on_peer_connected(id: int):
	print("[MINIMAL] 🟢 Client %d connected!" % id)

func _on_peer_disconnected(id: int):  
	print("[MINIMAL] 🔴 Client %d disconnected" % id)

@rpc("any_peer", "call_local")
func ping(message: String):
	var sender = multiplayer.get_remote_sender_id()
	print("[MINIMAL] 📨 PING from client %d: %s" % [sender, message])
	rpc_id(sender, "pong", "Server received: " + message)

@rpc("authority", "call_local")  
func pong(message: String):
	pass  # Clients will implement this
EOF

# Create a minimal scene
cat > /tmp/minimal_server.tscn << 'EOF'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="/tmp/minimal_server_test.gd" id="1"]

[node name="MinimalServer" type="Node"]
script = ExtResource("1")
EOF

# Run it
godot --path . --headless /tmp/minimal_server.tscn