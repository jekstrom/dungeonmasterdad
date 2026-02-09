# Snake Trail Synchronization API Contract

## SnakeTrailContainer Interface

### Public Methods

```gdscript
class_name SnakeTrailContainer extends Node2D

# Initialize container with player configuration
func setup_for_player(player_id: int, max_segments: int = 50) -> void

# Server-only: Update trail positions based on player movement  
func update_trail_positions(head_position: Vector2) -> void

# Server-only: Add new trail segment at current head position
func add_trail_segment() -> void

# Server-only: Remove oldest trail segments beyond limit
func trim_trail_segments(new_max: int) -> void

# Clean up all resources and prepare for destruction
func cleanup() -> void

# Get current trail data for external systems
func get_trail_data() -> Dictionary
```

### Synchronized Properties

```gdscript
# Automatically synchronized by MultiplayerSynchronizer
@export var trail_positions: Array[Vector2] = []      # All segment positions
@export var trail_count: int = 0                      # Active segment count
@export var player_id: int = -1                       # Owner player ID
```

### Signals

```gdscript
# Emitted when trail positions change (client-side)
signal trail_updated(new_positions: Array[Vector2])

# Emitted when trail segments are added/removed
signal trail_segments_changed(segment_count: int)

# Emitted when container is ready for cleanup
signal cleanup_requested(player_id: int)
```

## TrailManager Interface Changes

### New Methods

```gdscript
extends Node  # TrailManager singleton

# Create trail container for player entering snake mode
func create_trail_container(player_id: int) -> SnakeTrailContainer

# Remove trail container for player exiting snake mode  
func remove_trail_container(player_id: int) -> void

# Get existing trail container for player
func get_trail_container(player_id: int) -> SnakeTrailContainer

# Update all trail containers (server-only, called from game loop)
func update_all_trails(delta: float) -> void

# Clean up orphaned containers
func cleanup_orphaned_containers() -> void
```

### Removed Methods

```gdscript
# These RPC-based methods will be removed:
# @rpc func sync_all_player_trails(trail_data: Dictionary) -> void
# func update_player_trail_display(player_id: int, positions: Array[Vector2], sprite_data: Dictionary) -> void
# func broadcast_all_trail_data() -> void
```

## PlayerSnakeState Interface Changes

### Modified Methods

```gdscript
class_name PlayerSnakeState extends PlayerState

# Enter() now creates trail container instead of RPC setup
func Enter() -> void:
    # Server creates trail container
    if multiplayer.is_server():
        trail_container = TrailManager.create_trail_container(player_id)
    # Client waits for synchronization

# Exit() cleans up container instead of RPC cleanup
func Exit() -> void:
    # Server removes trail container
    if multiplayer.is_server():
        TrailManager.remove_trail_container(player_id)
    # Clients automatically receive cleanup via synchronization

# Process() updates container directly instead of RPC calls
func Process(delta: float) -> PlayerState:
    if multiplayer.is_server() and trail_container:
        trail_container.update_trail_positions(player.global_position)
    # No RPC calls needed - synchronizer handles distribution
```

### Removed Methods

```gdscript
# These RPC methods will be removed:
# @rpc func notify_server_snake_mode_entered(pid: int) -> void
# @rpc func notify_server_snake_mode_exited(pid: int) -> void  
# @rpc func notify_server_player_moved(pid: int, position: Vector2) -> void
# func broadcast_all_trail_data() -> void
```

## MultiplayerSynchronizer Configuration

### Replication Setup

```gdscript
# Applied to SnakeTrailContainer's MultiplayerSynchronizer
func configure_replication() -> SceneReplicationConfig:
    var config = SceneReplicationConfig.new()
    
    # High-frequency position updates (unreliable for performance)
    config.add_property(".:trail_positions")
    config.property_set_spawn(".:trail_positions", true)
    config.property_set_sync(".:trail_positions", true)
    config.property_set_replication_mode(
        ".:trail_positions", 
        MultiplayerSynchronizer.REPLICATION_MODE_ON_CHANGE
    )
    
    # Reliable segment count updates
    config.add_property(".:trail_count")
    config.property_set_spawn(".:trail_count", true) 
    config.property_set_sync(".:trail_count", true)
    
    # Player ID only on spawn
    config.add_property(".:player_id")
    config.property_set_spawn(".:player_id", true)
    config.property_set_sync(".:player_id", false)
    
    return config
```

### Authority Configuration

```gdscript
# Server authority for all trail containers
func _ready():
    var sync = $MultiplayerSynchronizer
    sync.set_multiplayer_authority(1)  # Server ID
    sync.replication_config = configure_replication()
```

## Migration Contract

### Phase 1: Container Creation
1. Create `SnakeTrailContainer` scene with MultiplayerSynchronizer
2. Implement container methods for position management
3. Test basic synchronization with single player

### Phase 2: Integration  
1. Modify `PlayerSnakeState` to use containers instead of RPCs
2. Update `TrailManager` to manage containers
3. Test with multiple players

### Phase 3: RPC Removal
1. Remove deprecated RPC methods from snake state
2. Remove deprecated RPC methods from trail manager  
3. Clean up timer-based broadcast system
4. Final testing and performance validation

## Backward Compatibility

### Breaking Changes
- All trail-related RPC methods removed
- `sync_all_player_trails` RPC no longer exists
- Timer-based broadcast system removed
- `server_trail_data` dictionary replaced with containers

### Preserved Functionality
- Collision detection continues to work
- Death system integration maintained
- Visual appearance remains identical
- Performance characteristics improved

## Error Handling

### Container Creation Failures
```gdscript
func create_trail_container(player_id: int) -> SnakeTrailContainer:
    if active_containers.has(player_id):
        push_warning("Trail container already exists for player " + str(player_id))
        return active_containers[player_id]
    
    var container = trail_container_scene.instantiate()
    if not container:
        push_error("Failed to instantiate trail container scene")
        return null
    
    container.setup_for_player(player_id)
    world_node.add_child(container)
    active_containers[player_id] = container
    return container
```

### Synchronization Failures
```gdscript
# Client-side error handling for sync failures
func _on_synchronization_lost():
    push_warning("Trail synchronization lost - requesting resync")
    # Container will be recreated when player re-enters snake mode
```

### Memory Management
```gdscript
# Automatic cleanup on player disconnection
func _on_player_disconnected(player_id: int):
    if active_containers.has(player_id):
        remove_trail_container(player_id)
```