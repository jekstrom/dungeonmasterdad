#!/bin/bash

echo "Starting simple Dungeon Master Dad headless client..."
echo "This client will connect to localhost:42069"
echo "Press Ctrl+C to stop"
echo "================================================"

cd /home/james/dungeon-master-dad

# Start the simple headless client
godot --path . --headless test_harness/simple_client_scene.tscn