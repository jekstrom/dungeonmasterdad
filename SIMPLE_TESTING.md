# Simple Network Testing - WORKING VERSION

This guide provides **working** scripts to test the Dungeon Master Dad multiplayer networking with clear console output.

## ✅ **Working Scripts**

### **Minimal Testing (Recommended)**
- **`minimal_server.sh`** - Pure networking test server
- **`minimal_client.sh`** - Pure networking test client

### **Simple Testing (Full Game Context)**
- **`simple_server.sh`** - Server with game systems
- **`simple_client.sh`** - Client with game systems

## 🚀 **Quick Start**

### **Basic Network Test**
```bash
# Terminal 1 - Start minimal server
./minimal_server.sh

# Terminal 2 - Start minimal client  
./minimal_client.sh

# Terminal 3 - Start another client (optional)
./minimal_client.sh
```

## 📋 **What You'll See**

### **Server Output (minimal_server.sh)**
```
[MINIMAL] ✅ Server started successfully!
[MINIMAL] Waiting for clients to connect...
[MINIMAL] 🟢 Client 1234 connected!
[MINIMAL] 📨 PING from client 1234: Hello from client-5678 (msg #1)
[MINIMAL] 🟢 Client 5678 connected!
[MINIMAL] 📨 PING from client 5678: Hello from client-5678 (msg #2)
```

### **Client Output (minimal_client.sh)**
```
[CLIENT-5678] ✅ Connected to server!
[CLIENT-5678] 📤 Sent ping #1
[CLIENT-5678] 📨 PONG: Server received: Hello from client-5678 (msg #1)
[CLIENT-5678] 📤 Sent ping #2
[CLIENT-5678] 📨 PONG: Server received: Hello from client-5678 (msg #2)
```

## 🎯 **Test Scenarios**

### **1. Basic Connectivity**
```bash
./minimal_server.sh    # Start server
./minimal_client.sh    # Start client - should connect
```

### **2. Multiple Clients**
```bash
./minimal_server.sh    # Start server
./minimal_client.sh    # Client 1
./minimal_client.sh    # Client 2  
./minimal_client.sh    # Client 3
```

### **3. Connection Stress**
```bash
# Start server
./minimal_server.sh

# Start multiple clients quickly
for i in {1..5}; do ./minimal_client.sh & done
```

### **4. Disconnect/Reconnect**
```bash
./minimal_server.sh    # Server
./minimal_client.sh    # Client
# Ctrl+C the client, then restart it
./minimal_client.sh    # Should reconnect
```

## 🔧 **Key Features**

### **Minimal Scripts**
- ✅ Pure networking focus
- ✅ No complex game system dependencies
- ✅ Clear, emoji-coded output
- ✅ Automatic ping/pong testing
- ✅ Unique client IDs
- ✅ RPC communication validation

### **Simple Scripts**  
- ✅ Full game context (PlayerManager, etc.)
- ✅ Integration with existing lobby system
- ✅ More comprehensive testing
- ✅ Game-realistic scenarios

## ⚠️ **Expected Warnings**

You may see these warnings (they're normal):
```
SCRIPT ERROR: Trying to assign value of type 'Node' to a variable of type 'Node2D'.
          at: find_world_node (res://_globals/trail_manager.gd:26)
```
This is expected in headless mode - the TrailManager expects a 2D world scene.

## 🐛 **Troubleshooting**

### **"Server failed to start"**
- Check if port 42069 is already in use: `lsof -i :42069`
- Kill existing processes: `pkill -f "godot.*headless"`

### **"Connection failed"**
- Ensure server is running first
- Check server shows "Server started successfully"
- Try connecting from same machine first

### **No output**
- Check that scripts are executable: `chmod +x *.sh`
- Ensure you're in the project directory
- Verify Godot is in your PATH: `godot --version`

## 📊 **Monitoring Tips**

### **Network Activity**
```bash
# Monitor network connections
netstat -an | grep 42069

# Watch active connections in real-time
watch "netstat -an | grep 42069"
```

### **Process Monitoring**
```bash
# See running Godot processes
ps aux | grep godot

# Monitor system resources
htop
```

## 🎮 **Understanding the Output**

### **Connection Events**
- 🟢 **Green**: New client connected
- 🔴 **Red**: Client disconnected
- ✅ **Checkmark**: Successful operation
- ❌ **X**: Failed operation

### **Message Flow**
- 📤 **Outbox**: Client sending message to server
- 📨 **Inbox**: Receiving message (RPC)
- 📡 **PING/PONG**: Network connectivity test

### **Performance Indicators**
- **Message count**: Shows sustained communication
- **Client IDs**: Helps distinguish multiple clients
- **Response times**: Indicates network latency

## 🚀 **Next Steps**

Once basic connectivity works with these scripts, you can:

1. **Scale Testing**: Run more clients simultaneously
2. **Load Testing**: Use the full test harness in `test_harness/`
3. **Game Testing**: Run the actual game with `godot --path .`
4. **Advanced Analysis**: Use the log analyzer for deeper insights

## 📁 **File Summary**

```
/home/james/dungeon-master-dad/
├── minimal_server.sh      ← Simple network server test
├── minimal_client.sh      ← Simple network client test  
├── simple_server.sh       ← Server with game systems
├── simple_client.sh       ← Client with game systems
├── test_harness/         ← Full automated testing suite
└── SIMPLE_TESTING.md     ← This guide
```

The minimal scripts create temporary test files in `/tmp/` and are completely self-contained for easy testing.