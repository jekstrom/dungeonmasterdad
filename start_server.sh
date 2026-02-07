#!/bin/bash

echo "Starting Dungeon Master Dad headless server..."
echo "Server will start on port 42069"
echo "Press Ctrl+C to stop"
echo "================================================"

cd /home/james/dungeon-master-dad

# Create the server test scene if it doesn't exist
if [ ! -f "test_harness/server_test_scene.tscn" ]; then
    mkdir -p test_harness
    cat > test_harness/server_test_scene.tscn << 'EOF'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test_harness/headless_server_test.gd" id="1"]

[node name="ServerTest" type="Node"]
script = ExtResource("1")
EOF
    echo "Created server test scene"
fi

# Start the headless server
godot --path . --headless test_harness/server_test_scene.tscn