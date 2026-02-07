#!/usr/bin/env python3
"""
Simple script to start a headless server for manual observation
Outputs all console logs directly to stdout for easy monitoring
"""

import subprocess
import sys
from pathlib import Path


def main():
    project_path = Path("/home/james/dungeon-master-dad")
    server_scene = project_path / "test_harness" / "server_test_scene.tscn"

    print("Starting Dungeon Master Dad headless server...")
    print("Press Ctrl+C to stop the server")
    print("=" * 50)

    # Ensure the server test scene exists
    if not server_scene.exists():
        scene_content = """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test_harness/headless_server_test.gd" id="1"]

[node name="ServerTest" type="Node"]
script = ExtResource("1")
"""
        with open(server_scene, "w") as f:
            f.write(scene_content)
        print(f"Created server test scene: {server_scene}")

    # Start the server process with direct stdout output
    cmd = ["godot", "--path", str(project_path), "--headless", str(server_scene)]

    try:
        # Run with direct output to console
        process = subprocess.run(cmd, cwd=str(project_path))
        return process.returncode
    except KeyboardInterrupt:
        print("\nServer stopped by user")
        return 0
    except FileNotFoundError:
        print("Error: 'godot' command not found in PATH")
        print("Please install Godot or add it to your PATH")
        return 1
    except Exception as e:
        print(f"Error starting server: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
