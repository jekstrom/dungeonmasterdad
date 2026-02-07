# Simple Server/Client Testing

This directory contains simple scripts to manually start server and client instances for console output observation.

## Quick Start

### Option 1: Shell Scripts (Recommended)

```bash
# Terminal 1 - Start the server
./start_server.sh

# Terminal 2 - Start a client (in a new terminal)
./start_client.sh

# Terminal 3 - Start another client (optional)
./start_client.sh
```

### Option 2: Python Scripts

```bash
# Terminal 1 - Start the server
python3 start_server.py

# Terminal 2 - Start a client
python3 start_client.py
```

## What You'll See

### Server Output
The server will display:
- Server startup messages
- Player connection/disconnection events
- Network status updates
- RPC call logs
- Performance metrics
- Error messages (if any)

Example server output:
```
Starting Dungeon Master Dad headless server...
[2024-02-06 13:30:15] SERVER: Headless server started on port 42069
[2024-02-06 13:30:20] NETWORK: Player connected: 1234 (Total players: 1)
[2024-02-06 13:30:21] RPC: Received test RPC from player 1234: Hello from client_5678
[2024-02-06 13:30:25] MOVEMENT: Player 1234 position update: (150, 200)
```

### Client Output
Each client will display:
- Connection attempt messages
- Connection success/failure
- Simulated player actions
- Movement updates
- RPC communication
- Disconnection events

Example client output:
```
Starting Dungeon Master Dad headless client...
[2024-02-06 13:30:20] CLIENT: Attempting to connect to server at localhost:42069
[2024-02-06 13:30:20] NETWORK: Successfully connected to server
[2024-02-06 13:30:21] ACTION: Executing test action: send_test_rpc
[2024-02-06 13:30:25] MOVEMENT: Position: (150, 200)
[2024-02-06 13:30:30] SIMULATION: Simulating spell cast
```

## Testing Scenarios

### Basic Connectivity Test
1. Start server: `./start_server.sh`
2. Wait for "server started" message
3. Start client: `./start_client.sh`
4. Watch for successful connection messages

### Multiple Clients Test
1. Start server
2. Start multiple clients in different terminals
3. Observe how the server handles multiple connections
4. Watch for any connection issues or conflicts

### Connection Stress Test
1. Start server
2. Quickly start several clients (5-10)
3. Monitor for any connection failures
4. Check server stability under load

### Disconnect/Reconnect Test
1. Start server and client
2. Stop client (Ctrl+C)
3. Start client again
4. Verify reconnection works properly

## Stopping the Tests

- Press `Ctrl+C` in any terminal to stop that process
- Always stop clients before stopping the server for clean shutdown
- The server will automatically clean up when stopped

## Troubleshooting

### "godot command not found"
- Install Godot 4.5 or add it to your PATH
- On Arch Linux: `sudo pacman -S godot`

### "Connection failed"
- Make sure the server is running first
- Check that port 42069 is not blocked by firewall
- Verify the server shows "server started" before connecting clients

### No output or errors
- Check that the test scripts exist in `test_harness/`
- Ensure you're running from the project root directory
- Verify the project.godot file is present

### Performance Issues
- If you see lag or delays, this is normal with many clients
- Monitor system resources (CPU/memory usage)
- Reduce number of concurrent clients if needed

## Advanced Usage

### Custom Server IP
To connect to a different server, modify the client script:
```bash
# Edit start_client.sh and change localhost to your server IP
```

### Verbose Logging
The scripts use the full test harness logging system, so you'll see detailed output including:
- Timestamps for all events
- Categorized message types
- Performance metrics
- Error tracking

### Log Files
While these simple scripts output to stdout, the full test harness in `test_harness/` can save logs to files for later analysis.

## Next Steps

Once you've validated basic connectivity with these simple scripts, you can use the full test harness for automated testing:

```bash
cd test_harness
./run_tests.sh quick      # Automated test with analysis
./run_tests.sh standard   # Longer automated test
./run_tests.sh stress     # Stress testing
```