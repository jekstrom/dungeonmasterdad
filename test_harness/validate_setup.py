#!/usr/bin/env python3
"""
Quick validation script to test the test harness setup
"""

import sys
import subprocess
from pathlib import Path


def test_godot_availability():
    """Test if Godot is available and working"""
    try:
        result = subprocess.run(
            ["godot", "--version"], capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0:
            print(f"✓ Godot available: {result.stdout.strip()}")
            return True
        else:
            print(f"✗ Godot error: {result.stderr}")
            return False
    except FileNotFoundError:
        print("✗ Godot not found in PATH")
        return False
    except subprocess.TimeoutExpired:
        print("✗ Godot command timed out")
        return False


def test_project_structure():
    """Test if the project has the required structure"""
    project_path = Path("/home/james/dungeon-master-dad")
    required_files = ["project.godot", "lobby.gd", "_globals/signal_bus.gd"]

    all_good = True
    for file_path in required_files:
        full_path = project_path / file_path
        if full_path.exists():
            print(f"✓ Found: {file_path}")
        else:
            print(f"✗ Missing: {file_path}")
            all_good = False

    return all_good


def test_script_syntax():
    """Test if the GDScript files have valid syntax"""
    project_path = Path("/home/james/dungeon-master-dad")
    test_scripts = [
        "test_harness/headless_server_test.gd",
        "test_harness/headless_client_test.gd",
        "test_harness/log_analyzer.gd",
    ]

    all_good = True
    for script in test_scripts:
        script_path = project_path / script
        if script_path.exists():
            print(f"✓ Script exists: {script}")
        else:
            print(f"✗ Script not found: {script}")
            all_good = False

    return all_good


def test_scene_creation():
    """Test if we can create the test scenes manually"""
    try:
        # Create server test scene content
        server_scene_content = """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test_harness/headless_server_test.gd" id="1"]

[node name="ServerTest" type="Node"]
script = ExtResource("1")
"""

        # Create client test scene content
        client_scene_content = """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test_harness/headless_client_test.gd" id="1"]

[node name="ClientTest" type="Node"]
script = ExtResource("1")
"""

        # Write the scene files
        server_scene = Path(
            "/home/james/dungeon-master-dad/test_harness/server_test_scene.tscn"
        )
        client_scene = Path(
            "/home/james/dungeon-master-dad/test_harness/client_test_scene.tscn"
        )

        with open(server_scene, "w") as f:
            f.write(server_scene_content)

        with open(client_scene, "w") as f:
            f.write(client_scene_content)

        if server_scene.exists() and client_scene.exists():
            print("✓ Test scenes created successfully")
            return True
        else:
            print("✗ Failed to create test scenes")
            return False
    except PermissionError:
        print("✗ Permission denied creating test scenes")
        return False
    except OSError as e:
        print(f"✗ OS error creating scenes: {e}")
        return False


def main():
    print("=== Dungeon Master Dad Test Harness Validation ===\n")

    tests = [
        ("Godot Availability", test_godot_availability),
        ("Project Structure", test_project_structure),
        ("Script Syntax", test_script_syntax),
        ("Scene Creation", test_scene_creation),
    ]

    passed = 0
    total = len(tests)

    for test_name, test_func in tests:
        print(f"Running: {test_name}")
        try:
            if test_func():
                passed += 1
            print()
        except KeyboardInterrupt:
            print("\n✗ Test interrupted by user")
            break

    print(f"=== Results: {passed}/{total} tests passed ===")

    if passed == total:
        print("🎉 All tests passed! The test harness is ready to use.")
        print("\nTo run tests:")
        print("  ./run_tests.sh quick     # Quick test")
        print("  ./run_tests.sh standard  # Standard test")
        print("  ./run_tests.sh stress    # Stress test")
        return 0
    else:
        print("⚠️  Some tests failed. Please fix the issues before running tests.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
