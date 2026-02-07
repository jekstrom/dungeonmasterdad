# Data Model: Object Pooling System

**Date**: 2026-02-06  
**Feature**: 003-object-pooling-system

## Entity Overview

The object pooling system introduces a new data management layer for pickup items, transitioning from immediate destruction to reusable object lifecycle management.

## Core Entities

### PickupPool (Singleton)

**Purpose**: Global manager for pooled pickup item instances

**Fields**:
- `pool_size: int = 50` - Maximum number of pooled items per type
- `available_pickups: Array[ItemPickup]` - Available items for reuse
- `active_pickups: Dictionary` - Currently spawned items (name -> node)
- `pool_stats: Dictionary` - Performance tracking data

**Methods**:
- `get_pickup(item_type: String) -> ItemPickup?` - Retrieve from pool or create new
- `return_pickup(pickup: ItemPickup)` - Return item to pool and reset state
- `pre_allocate_pool(size: int)` - Initialize pool with inactive items
- `get_pool_utilization() -> float` - Return pool usage percentage

**State Transitions**:
```
[Pool Initialization] → [Ready]
[Ready] → [Get Request] → [Return Available Item] → [Ready]
[Ready] → [Get Request] → [Create New Item] → [Ready] (when pool empty)
[Ready] → [Return Request] → [Reset and Store] → [Ready]
```

**Validation Rules**:
- Pool size must be positive integer
- Cannot return items already in pool
- Must validate item type before pooling
- Server authority required for pool operations

### ItemPickup (Enhanced)

**Purpose**: Extended pickup item with pool lifecycle support

**Existing Fields** (preserved):
- `item_data: ItemData` - Item properties from database
- `drop_player_id: int` - Player who dropped the item
- `grace_period: float` - Time before pickup is allowed
- `pickup_audio: AudioStreamPlayer2D` - Sound effect

**New Fields**:
- `pool_state: PoolState` - Current lifecycle state
- `reset_required: bool` - Flag indicating state reset needed
- `pool_id: String` - Unique identifier for pool tracking

**Pool States**:
```gdscript
enum PoolState {
    ACTIVE,    # Currently in game world
    POOLED,    # Stored in pool, inactive
    RESETTING  # Transitioning between states
}
```

**Enhanced Methods**:
- `reset_state()` - Reset all properties for reuse
- `configure_from_data(data: Dictionary)` - Apply spawn configuration
- `return_to_pool()` - Replace queue_free() calls
- `validate_pool_state() -> bool` - Ensure item is ready for reuse

**State Transitions**:
```
[Created] → [ACTIVE] → [Collected] → [RESETTING] → [POOLED]
[POOLED] → [Requested] → [RESETTING] → [ACTIVE]
```

**Validation Rules**:
- Must reset all dynamic state before pooling
- Grace period timer must be cleared
- Audio must be stopped before pooling
- Position must be reset to prevent visual glitches
- Collision must be re-enabled for reuse

### PickupSpawner (Enhanced)

**Purpose**: Extended MultiplayerSpawner with pool integration

**Existing Fields** (preserved):
- `pickup_scene: PackedScene` - Template for new instances
- `active_pickups: Dictionary` - Currently spawned pickups
- `spawn_position: Vector2` - Location for spawn

**Enhanced Fields**:
- `use_pooling: bool = true` - Enable/disable pool usage
- `fallback_to_instantiate: bool = true` - Create new when pool empty
- `pool_performance_logging: bool = false` - Track pool efficiency

**Enhanced Methods**:
- `_custom_spawn(data: Dictionary) -> Node2D` - Pool-aware spawning
- `_custom_despawn(node: Node)` - Pool-aware cleanup
- `request_pooled_pickup(item_type: String) -> ItemPickup?` - Pool integration
- `handle_pool_exhaustion(item_type: String) -> ItemPickup` - Fallback logic

## Relationships

### PickupPool ↔ ItemPickup
- **One-to-many**: PickupPool manages multiple ItemPickup instances
- **Ownership**: PickupPool owns pooled instances, releases for active use
- **Lifecycle**: Pool controls item creation, reuse, and final cleanup

### PickupSpawner ↔ PickupPool
- **Dependency**: PickupSpawner depends on PickupPool for item allocation
- **Fallback**: PickupSpawner can create items when pool is exhausted
- **Coordination**: Both maintain active item tracking

### ItemPickup ↔ Player (Existing)
- **Interaction**: Players trigger pickup collection
- **Authority**: Server validates pickup requests
- **State Change**: Collection triggers return to pool instead of destruction

## Data Flow

### Item Spawn Flow
```
1. SignalBus.on_item_drop.emit(spawn_data)
2. PickupSpawner._custom_spawn(spawn_data)
3. PickupSpawner.request_pooled_pickup(item_type)
4. PickupPool.get_pickup(item_type)
5. [Pool Available] → Return existing item → Configure and activate
6. [Pool Empty] → Create new item → Add to active tracking
```

### Item Collection Flow
```
1. Player enters pickup area
2. Client sends pick_up_request.rpc_id(1, item_path)
3. Server validates collection
4. ItemPickup.handle_pickup() → Add to inventory
5. ItemPickup.return_to_pool() [NEW - replaces queue_free()]
6. PickupPool.return_pickup(item) → Reset state and store
```

### Pool Lifecycle
```
[Game Start] → Pre-allocate pool with inactive items
[Runtime] → Cycle items: Pool → Active → Pool
[Game End] → Clean up all pooled instances
```

## Performance Considerations

### Memory Management
- Pool maintains persistent memory allocation
- Eliminates frequent allocation/deallocation cycles
- Trade-off: Higher baseline memory for better runtime performance

### Network Efficiency
- Pooled items reuse network identifiers where possible
- Reduced MultiplayerSpawner overhead for common items
- RPC patterns remain unchanged for client synchronization

### Godot-Specific Optimization
- Use `set_process(false)` for pooled items to prevent unnecessary updates
- Maintain items as scene tree children for proper cleanup
- Leverage existing `@onready var` patterns for node references

## Migration Strategy

### Backward Compatibility
- All existing pickup functionality preserved
- `queue_free()` calls replaced with `return_to_pool()` calls
- Existing spawn data format unchanged
- MultiplayerSpawner integration maintained

### Rollback Plan
- Pool usage can be disabled via `use_pooling = false`
- Fallback to original instantiation when pool exhausted
- No changes to item data structures or networking protocols