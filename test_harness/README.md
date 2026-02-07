# Dungeon Master Dad Test Harness

A comprehensive testing framework for analyzing the multiplayer functionality of the Dungeon Master Dad game through headless client/server testing.

## Overview

This test harness provides automated testing capabilities for:
- Server stability under load
- Client connection/disconnection handling
- Network synchronization
- RPC communication
- Performance monitoring
- Console output analysis

## Components

### Core Scripts

- **`test_harness.py`** - Main orchestration script (Python)
- **`headless_server_test.gd`** - Headless server test implementation (GDScript)
- **`headless_client_test.gd`** - Headless client test implementation (GDScript)
- **`log_analyzer.gd`** - Log analysis and pattern detection (GDScript)
- **`run_tests.sh`** - Convenient shell script for running tests

### Generated Files

- **`server_test_scene.tscn`** - Auto-generated server test scene
- **`client_test_scene.tscn`** - Auto-generated client test scene
- **`run_analysis.gd`** - Auto-generated analysis runner

## Quick Start

### Prerequisites

1. Godot 4.5 installed and available in PATH as `godot`
2. Python 3.x installed
3. The Dungeon Master Dad project properly configured

### Running Tests

```bash
# Navigate to the test harness directory
cd /home/james/dungeon-master-dad/test_harness

# Run a quick test (2 clients, 60 seconds)
./run_tests.sh quick

# Run standard test (4 clients, 120 seconds)
./run_tests.sh standard

# Run stress test (ramping up to 10 clients)
./run_tests.sh stress

# Run extended test (6 clients, 300 seconds)  
./run_tests.sh extended
```

### Manual Test Control

```bash
# Custom test configuration
python3 test_harness.py --clients 8 --duration 180

# Stress test with custom max clients
python3 test_harness.py --stress-test --max-clients 15

# Analyze specific test logs
python3 test_harness.py --analyze-only 20240206_143022
```

## Test Types

### Standard Test
- Spawns multiple headless clients
- Connects to headless server
- Simulates player movement and interactions
- Monitors network stability
- Duration: Configurable (default 120 seconds)

### Stress Test
- Gradually ramps up client connections
- Tests server capacity limits
- Monitors performance degradation
- Identifies breaking points

### Quick Test
- Fast validation test
- Suitable for development workflow
- Basic connectivity and functionality check

### Extended Test
- Long-running stability test
- Detects memory leaks and performance issues
- Comprehensive multiplayer scenario testing

## Monitoring and Analysis

### Real-time Monitoring

During test execution, the harness provides:
- Process status updates
- Connection event notifications
- Error detection and reporting
- Performance metrics

### Log Analysis

After tests complete, automated analysis includes:
- Error and warning categorization
- Network event timeline
- RPC call frequency analysis
- Performance metric extraction
- Pattern detection for recurring issues

### Output Files

**Logs Directory (`logs/`)**
- `server_TESTID.log` - Server console output
- `client_N_TESTID.log` - Individual client console outputs

**Results Directory (`results/`)**
- `test_results_TESTID.json` - Structured test results and metrics
- Analysis summaries and comparative reports

## Test Scenarios

### Simulated Player Behaviors

The client test script simulates realistic player actions:
- **Movement simulation** - Continuous position updates with direction changes
- **RPC communication** - Regular server communication testing
- **Inventory interactions** - Simulated item management
- **Spell casting** - Magic system testing
- **Building interactions** - Construction system validation

### Network Stress Patterns

- Connection/disconnection cycles
- High-frequency RPC calls during stress phases
- Concurrent client actions
- Server authority validation

## Configuration

### Test Parameters

Key configurable parameters in `test_harness.py`:
```python
self.server_timeout = 300      # Server max runtime (seconds)
self.client_timeout = 180      # Client max runtime (seconds) 
self.startup_delay = 5         # Server initialization wait
```

### Game-Specific Settings

The test scripts automatically adapt to the game's:
- Port configuration (42069)
- Autoloaded singletons (SignalBus, PlayerManager, etc.)
- RPC functions and networking patterns
- State machine architecture

## Troubleshooting

### Common Issues

**"godot command not found"**
- Ensure Godot is installed and in your system PATH
- Or modify `godot_executable` in `test_harness.py`

**Server fails to start**
- Check port 42069 availability
- Verify project.godot configuration
- Review autoload dependencies

**Clients fail to connect**
- Ensure server is fully initialized (check startup_delay)
- Verify network configuration
- Check firewall settings

**Log analysis fails**
- Ensure GDScript files are properly located
- Check file permissions in logs directory
- Verify Godot can execute analysis scripts

### Debug Mode

Enable verbose logging by modifying the log level in test scripts:
```gdscript
# In headless_server_test.gd or headless_client_test.gd
func log_message(category: String, message: String, level: int = 0):
    if level <= DEBUG_LEVEL:  # Add this line for filtering
        # existing logging code
```

## Extending the Test Harness

### Adding New Test Scenarios

1. Create new test functions in the client/server scripts
2. Add scheduling in `schedule_test_actions()`
3. Update the analysis patterns in `log_analyzer.gd`

### Custom Metrics

Add new performance metrics by:
1. Adding data collection in the test scripts
2. Extending the `AnalysisResult` class in `log_analyzer.gd`
3. Including new patterns in the analysis functions

### Integration with CI/CD

The test harness can be integrated into continuous integration:
```bash
# In your CI script
cd test_harness
./run_tests.sh quick
if [ $? -eq 0 ]; then
    echo "Tests passed"
else
    echo "Tests failed"
    exit 1
fi
```

## Performance Expectations

### Typical Results
- **2-4 clients**: Should run smoothly with minimal issues
- **5-8 clients**: May show occasional network delays
- **10+ clients**: Stress test territory, expect some connection issues

### Warning Signs
- Frequent disconnections
- RPC call failures
- Memory growth over time
- Server crashes or freezes

## Support and Development

This test harness is designed to evolve with the game. Key areas for enhancement:
- More sophisticated AI client behaviors
- Database interaction testing
- Save/load system validation
- Performance profiling integration
- Automated regression detection

For issues or enhancements, modify the scripts according to the game's development needs and architecture patterns established in AGENTS.md.
