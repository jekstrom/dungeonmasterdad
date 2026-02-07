#!/usr/bin/env python3
"""
Simple script to start a headless client for manual observation
Outputs all console logs directly to stdout for easy monitoring
"""

import subprocess
import sys
from pathlib import Path


def main():
    project_path = Path("/home/james/dungeon-master-dad")
    client_scene = project_path / "test_harness" / "client_test_scene.tscn"

    print("Starting Dungeon Master Dad headless client...")
    print("This client will attempt to connect to localhost:42069")
    print("Press Ctrl+C to stop the client")
    print("=" * 50)

    # Ensure the client test scene exists
    if not client_scene.exists():
        scene_content = """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test_harness/headless_client_test.gd" id="1"]

[node name="ClientTest" type="Node"]
script = ExtResource("1")
"""
        with open(client_scene, "w") as f:
            f.write(scene_content)
        print(f"Created client test scene: {client_scene}")

    # Start the client process with direct stdout output
    cmd = ["godot", "--path", str(project_path), "--headless", str(client_scene)]

    try:
        # Run with direct output to console
        process = subprocess.run(cmd, cwd=str(project_path))
        return process.returncode
    except KeyboardInterrupt:
        print("\nClient stopped by user")
        return 0
    except FileNotFoundError:
        print("Error: 'godot' command not found in PATH")
        print("Please install Godot or add it to your PATH")
        return 1
    except Exception as e:
        print(f"Error starting client: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
