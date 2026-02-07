#!/bin/bash

echo "Starting simple Dungeon Master Dad headless server..."
echo "This is a minimal test server on port 42069"
echo "Press Ctrl+C to stop"
echo "================================================"

cd /home/james/dungeon-master-dad

# Start the simple headless server
godot --path . --headless test_harness/simple_server_scene.tscn