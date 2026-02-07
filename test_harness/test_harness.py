#!/usr/bin/env python3
"""
Dungeon Master Dad Test Harness
Orchestrates headless server/client testing for the multiplayer game
"""

import subprocess
import time
import argparse
import os
import signal
import sys
from pathlib import Path
from typing import List, Dict, Optional
import json
import threading
from datetime import datetime


class TestHarness:
    def __init__(self, project_path: str = "/home/james/dungeon-master-dad"):
        self.project_path = Path(project_path)
        self.godot_executable = "godot"  # Assumes godot is in PATH
        self.processes: Dict[str, subprocess.Popen] = {}
        self.log_dir = self.project_path / "test_harness" / "logs"
        self.results_dir = self.project_path / "test_harness" / "results"

        # Create directories
        self.log_dir.mkdir(parents=True, exist_ok=True)
        self.results_dir.mkdir(parents=True, exist_ok=True)

        # Test configuration
        self.server_timeout = 300  # 5 minutes
        self.client_timeout = 180  # 3 minutes
        self.startup_delay = 5  # Wait for server to start before launching clients

        # Signal handler for cleanup
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)

    def signal_handler(self, signum, frame):
        print(f"\nReceived signal {signum}, shutting down test harness...")
        self.cleanup_processes()
        sys.exit(0)

    def run_test_suite(self, num_clients: int = 2, test_duration: int = 120) -> Dict:
        """Run a complete test suite with server and multiple clients"""
        print(
            f"Starting test suite with {num_clients} clients for {test_duration} seconds"
        )

        test_id = datetime.now().strftime("%Y%m%d_%H%M%S")
        test_results = {
            "test_id": test_id,
            "start_time": datetime.now().isoformat(),
            "config": {
                "num_clients": num_clients,
                "test_duration": test_duration,
                "server_timeout": self.server_timeout,
                "client_timeout": self.client_timeout,
            },
            "processes": {},
            "status": "running",
        }

        try:
            # Start server
            print("Starting headless server...")
            server_process = self.start_server(test_id)
            if not server_process:
                test_results["status"] = "failed"
                test_results["error"] = "Failed to start server"
                return test_results

            test_results["processes"]["server"] = {
                "pid": server_process.pid,
                "status": "running",
                "start_time": datetime.now().isoformat(),
            }

            # Wait for server to initialize
            print(f"Waiting {self.startup_delay} seconds for server to initialize...")
            time.sleep(self.startup_delay)

            # Start clients
            client_processes = []
            for i in range(num_clients):
                print(f"Starting client {i + 1}/{num_clients}...")
                client_process = self.start_client(test_id, i + 1)
                if client_process:
                    client_processes.append(client_process)
                    test_results["processes"][f"client_{i + 1}"] = {
                        "pid": client_process.pid,
                        "status": "running",
                        "start_time": datetime.now().isoformat(),
                    }
                else:
                    print(f"Warning: Failed to start client {i + 1}")

                # Small delay between client starts
                time.sleep(1)

            print(f"Test running... waiting {test_duration} seconds")
            print("Press Ctrl+C to stop the test early")

            # Monitor test for the specified duration
            start_time = time.time()
            while time.time() - start_time < test_duration:
                # Check if processes are still running
                if not self.is_process_running("server"):
                    print("Server process died unexpectedly!")
                    test_results["status"] = "server_crashed"
                    break

                # Count active clients
                active_clients = sum(
                    1
                    for i in range(len(client_processes))
                    if self.is_process_running(f"client_{i + 1}")
                )

                if active_clients == 0:
                    print("All clients disconnected!")
                    break

                time.sleep(10)  # Check every 10 seconds

            print("Test completed, shutting down processes...")
            test_results["end_time"] = datetime.now().isoformat()
            test_results["actual_duration"] = time.time() - start_time

        except KeyboardInterrupt:
            print("Test interrupted by user")
            test_results["status"] = "interrupted"
            test_results["end_time"] = datetime.now().isoformat()
        except Exception as e:
            print(f"Test failed with error: {e}")
            test_results["status"] = "error"
            test_results["error"] = str(e)
            test_results["end_time"] = datetime.now().isoformat()
        finally:
            # Cleanup all processes
            self.cleanup_processes()

            # Update process statuses
            for proc_name in test_results["processes"]:
                test_results["processes"][proc_name]["status"] = "terminated"
                test_results["processes"][proc_name]["end_time"] = (
                    datetime.now().isoformat()
                )

            # Save test results
            self.save_test_results(test_results)

            # Analyze logs
            self.analyze_test_logs(test_id)

        if test_results["status"] == "running":
            test_results["status"] = "completed"

        return test_results

    def start_server(self, test_id: str) -> Optional[subprocess.Popen]:
        """Start the headless server process"""
        server_scene = self.project_path / "test_harness" / "server_test_scene.tscn"
        log_file = self.log_dir / f"server_{test_id}.log"

        # Create the server test scene if it doesn't exist
        self.create_server_test_scene()

        cmd = [
            self.godot_executable,
            "--path",
            str(self.project_path),
            "--headless",
            str(server_scene),
        ]

        try:
            with open(log_file, "w") as f:
                process = subprocess.Popen(
                    cmd, stdout=f, stderr=subprocess.STDOUT, cwd=str(self.project_path)
                )

            self.processes["server"] = process
            print(f"Server started with PID {process.pid}, logging to {log_file}")
            return process

        except Exception as e:
            print(f"Failed to start server: {e}")
            return None

    def start_client(self, test_id: str, client_num: int) -> Optional[subprocess.Popen]:
        """Start a headless client process"""
        client_scene = self.project_path / "test_harness" / "client_test_scene.tscn"
        log_file = self.log_dir / f"client_{client_num}_{test_id}.log"

        # Create the client test scene if it doesn't exist
        self.create_client_test_scene()

        cmd = [
            self.godot_executable,
            "--path",
            str(self.project_path),
            "--headless",
            str(client_scene),
        ]

        try:
            with open(log_file, "w") as f:
                process = subprocess.Popen(
                    cmd, stdout=f, stderr=subprocess.STDOUT, cwd=str(self.project_path)
                )

            process_name = f"client_{client_num}"
            self.processes[process_name] = process
            print(
                f"Client {client_num} started with PID {process.pid}, logging to {log_file}"
            )
            return process

        except Exception as e:
            print(f"Failed to start client {client_num}: {e}")
            return None

    def is_process_running(self, process_name: str) -> bool:
        """Check if a process is still running"""
        if process_name not in self.processes:
            return False

        process = self.processes[process_name]
        return process.poll() is None

    def cleanup_processes(self):
        """Terminate all running processes"""
        print("Cleaning up processes...")

        for name, process in self.processes.items():
            if process.poll() is None:  # Process is still running
                print(f"Terminating {name} (PID {process.pid})")
                try:
                    process.terminate()
                    # Give it a chance to terminate gracefully
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    print(f"Force killing {name}")
                    process.kill()
                except Exception as e:
                    print(f"Error terminating {name}: {e}")

        self.processes.clear()

    def create_server_test_scene(self):
        """Create the server test scene file"""
        scene_path = self.project_path / "test_harness" / "server_test_scene.tscn"

        scene_content = """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test_harness/headless_server_test.gd" id="1"]

[node name="ServerTest" type="Node"]
script = ExtResource("1")
"""

        with open(scene_path, "w") as f:
            f.write(scene_content)

    def create_client_test_scene(self):
        """Create the client test scene file"""
        scene_path = self.project_path / "test_harness" / "client_test_scene.tscn"

        scene_content = """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test_harness/headless_client_test.gd" id="1"]

[node name="ClientTest" type="Node"]
script = ExtResource("1")
"""

        with open(scene_path, "w") as f:
            f.write(scene_content)

    def save_test_results(self, results: Dict):
        """Save test results to JSON file"""
        results_file = self.results_dir / f"test_results_{results['test_id']}.json"

        with open(results_file, "w") as f:
            json.dump(results, f, indent=2)

        print(f"Test results saved to {results_file}")

    def analyze_test_logs(self, test_id: str):
        """Run log analysis on the test results"""
        print("Analyzing test logs...")

        # Create a Godot script to run the log analysis
        analysis_script = self.project_path / "test_harness" / "run_analysis.gd"
        analysis_content = f"""extends SceneTree

func _init():
    var log_dir = "res://test_harness/logs/"
    LogAnalyzer.run_analysis(log_dir)
    quit()
"""

        with open(analysis_script, "w") as f:
            f.write(analysis_content)

        # Run the analysis
        cmd = [
            self.godot_executable,
            "--path",
            str(self.project_path),
            "--script",
            str(analysis_script),
        ]

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
            print("Log Analysis Output:")
            print(result.stdout)
            if result.stderr:
                print("Analysis Errors:")
                print(result.stderr)
        except Exception as e:
            print(f"Failed to run log analysis: {e}")

    def run_stress_test(self, max_clients: int = 10, ramp_up_time: int = 60):
        """Run a stress test with gradually increasing client count"""
        print(
            f"Starting stress test - ramping up to {max_clients} clients over {ramp_up_time} seconds"
        )

        test_id = f"stress_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

        # Start server
        server_process = self.start_server(test_id)
        if not server_process:
            print("Failed to start server for stress test")
            return

        time.sleep(self.startup_delay)

        client_processes = []
        interval = ramp_up_time / max_clients

        try:
            for i in range(max_clients):
                print(f"Starting client {i + 1}/{max_clients}")
                client_process = self.start_client(test_id, i + 1)
                if client_process:
                    client_processes.append(client_process)

                time.sleep(interval)

                # Check server health
                if not self.is_process_running("server"):
                    print("Server crashed during stress test!")
                    break

            print(f"All clients started. Running for additional 60 seconds...")
            time.sleep(60)

        except KeyboardInterrupt:
            print("Stress test interrupted")
        finally:
            self.cleanup_processes()
            print("Stress test completed")


def main():
    parser = argparse.ArgumentParser(description="Dungeon Master Dad Test Harness")
    parser.add_argument(
        "--project-path",
        default="/home/james/dungeon-master-dad",
        help="Path to the Godot project",
    )
    parser.add_argument(
        "--clients", type=int, default=2, help="Number of clients to spawn"
    )
    parser.add_argument(
        "--duration", type=int, default=120, help="Test duration in seconds"
    )
    parser.add_argument(
        "--stress-test",
        action="store_true",
        help="Run stress test instead of regular test",
    )
    parser.add_argument(
        "--max-clients", type=int, default=10, help="Maximum clients for stress test"
    )
    parser.add_argument(
        "--analyze-only", type=str, help="Only analyze logs from specified test ID"
    )

    args = parser.parse_args()

    harness = TestHarness(args.project_path)

    if args.analyze_only:
        harness.analyze_test_logs(args.analyze_only)
        return

    if args.stress_test:
        harness.run_stress_test(args.max_clients)
    else:
        results = harness.run_test_suite(args.clients, args.duration)
        print(f"\nTest completed with status: {results['status']}")

        if results["status"] == "completed":
            print("✅ Test passed successfully")
        else:
            print("❌ Test had issues")
            if "error" in results:
                print(f"Error: {results['error']}")


if __name__ == "__main__":
    main()
