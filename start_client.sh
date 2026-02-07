#!/bin/bash

echo "Starting Dungeon Master Dad headless client..."
echo "Client will connect to localhost:42069"
echo "Press Ctrl+C to stop"
echo "================================================"

cd /home/james/dungeon-master-dad

# Create the client test scene if it doesn't exist
if [ ! -f "test_harness/client_test_scene.tscn" ]; then
    mkdir -p test_harness
    cat > test_harness/client_test_scene.tscn << 'EOF'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test_harness/headless_client_test.gd" id="1"]

[node name="ClientTest" type="Node"]
script = ExtResource("1")
EOF
    echo "Created client test scene"
fi

# Start the headless client
godot --path . --headless test_harness/client_test_scene.tscn