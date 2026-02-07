# Research: Object Pooling System for Pickup Spawner

**Date**: 2026-02-06  
**Feature**: 003-object-pooling-system

## 1. Object Pooling Fundamentals

**Decision**: Use object pooling for frequently spawned/destroyed items like pickups, projectiles, and temporary effects

**Rationale**: 
- Current game calls `queue_free()` on pickups after collection, causing potential memory fragmentation
- Frequent spawning of items in multiplayer environments creates GC pressure  
- Existing `active_pickups` dictionary in `PickupSpawner` shows object tracking already exists - can be enhanced into a pool

**Alternatives considered**:
- Direct instantiation/destruction (current approach) - causes fragmentation over time
- Godot's built-in object recycling - not sufficient for multiplayer synchronization needs
- Custom memory management - too complex for 300 line requirement

## 2. Godot-Specific Object Pooling

**Decision**: Implement pool using disabled nodes with `set_process(false)` and scene tree manipulation

**Rationale**:
- Godot's node system allows for elegant enable/disable patterns
- Existing `_disable_pickup()` method shows familiarity with this approach
- Better than destroying/recreating nodes for GDScript performance

**Alternatives considered**:
- Array-based generic pools - less Godot-idiomatic
- Resource-based pooling - doesn't handle node-specific features
- PackedScene instantiation caching - still triggers scene tree changes

**Implementation notes**:
```gdscript
# Pool management pattern for Godot
func get_pooled_object():
    for obj in inactive_objects:
        if not obj.is_processing():
            obj.reset_state()
            obj.set_process(true)
            obj.visible = true
            return obj
    return create_new_object()

func return_to_pool(obj):
    obj.set_process(false)
    obj.set_physics_process(false) 
    obj.visible = false
    obj.position = Vector2(-10000, -10000)  # Off-screen
```

## 3. Multiplayer Object Pooling Patterns

**Decision**: Server-authoritative pool with RPC state sync for critical objects

**Rationale**:
- Current multiplayer architecture shows server authority pattern (`multiplayer.is_server()` checks)
- Existing `PickupSpawner` extends `MultiplayerSpawner` - can enhance this pattern
- Client prediction unnecessary for pickups (not real-time critical)

**Alternatives considered**:
- Client-side pools with validation - increases complexity
- Fully synchronized pools - unnecessary network overhead  
- Per-client pools - breaks authority model

**Implementation notes**:
```gdscript
# Server manages pool, clients receive updates
@rpc("authority", "call_remote", "reliable")
func sync_pool_object(obj_id: String, state: Dictionary):
    var obj = get_pooled_object(obj_id)
    if obj:
        obj.apply_state(state)

# Server-side pool allocation
func allocate_from_pool() -> PickupObject:
    if not multiplayer.is_server(): return null
    var obj = pool.get_available()
    if obj:
        sync_pool_object.rpc(obj.unique_id, obj.get_state())
    return obj
```

## 4. Implementation Patterns  

**Decision**: Singleton pool managers with pre-allocation strategy

**Rationale**:
- Fits existing architecture (SignalBus, PlayerManager, ItemDatabase singletons)
- Pre-allocation prevents mid-game frame drops
- Singleton access pattern simplifies integration with existing spawners

**Alternatives considered**:
- Instance-based pools per spawner - increases memory usage
- Dynamic pool expansion - causes unpredictable performance
- Lazy allocation - can cause frame hitches

**Implementation notes**:
```gdscript
# PickupPool singleton (autoload)
class_name PickupPool extends Node

const POOL_SIZE = 50
var available_pickups: Array[ItemPickup] = []
var active_pickups: Dictionary = {}

func _ready():
    for i in POOL_SIZE:
        var pickup = preload("res://pickups/item_pickup.tscn").instantiate()
        pickup.set_process(false)
        pickup.visible = false
        available_pickups.append(pickup)
        add_child(pickup)

func get_pickup() -> ItemPickup:
    if available_pickups.is_empty():
        print("Warning: Pickup pool exhausted")
        return create_overflow_pickup()
    
    var pickup = available_pickups.pop_back()
    return pickup

func return_pickup(pickup: ItemPickup):
    pickup.reset_state()
    pickup.set_process(false)
    pickup.visible = false
    available_pickups.append(pickup)
```

## 5. Godot MultiplayerSpawner Integration

**Decision**: Extend MultiplayerSpawner with pool-aware spawn functions

**Rationale**:
- Current `PickupSpawner` already extends `MultiplayerSpawner` with `_custom_spawn`
- Pool allocation can happen in spawn function before network sync
- Maintains existing multiplayer synchronization guarantees

**Alternatives considered**:
- Separate pool system - breaks existing spawn patterns
- Replace MultiplayerSpawner entirely - too disruptive  
- Pool objects outside MultiplayerSpawner - sync complexity

**Implementation notes**:
```gdscript
# Enhanced PickupSpawner with pooling
func _custom_spawn(data: Dictionary) -> Node2D:
    # Try to get from pool first
    var pickup = PickupPool.get_pickup()
    if not pickup:
        # Fallback to instantiation
        pickup = pickup_scene.instantiate()
        
    pickup.configure_from_data(data)
    active_pickups[pickup.name] = pickup
    return pickup

# Override despawn to return to pool
func _custom_despawn(node: Node):
    if node is ItemPickup:
        PickupPool.return_pickup(node)
        active_pickups.erase(node.name)
```

## Key Implementation Recommendations

1. **Start with PickupPool singleton** - Replace `queue_free()` calls in `item_pickup.gd:302`
2. **Maintain existing architecture** - Enhance rather than replace current systems  
3. **Server-authoritative** - Pool allocation only on server, clients receive updates
4. **Pre-allocate** - Create pools during scene load, not runtime
5. **Graceful degradation** - Handle pool exhaustion with overflow objects
6. **Monitor performance** - Add pool utilization metrics for tuning
7. **State reset is critical** - Ensure objects are completely reinitialized

## Integration Points

- `PickupSpawner._custom_spawn()` - get from pool instead of instantiate
- `ItemPickup._server_cleanup()` - return to pool instead of queue_free()
- `ItemPickup.handle_pickup()` - disable and return to pool
- New `PickupPool` singleton - manage pool lifecycle

## Risk Mitigation

- **Pool exhaustion**: Fallback to MultiplayerSpawner instantiation
- **State pollution**: Comprehensive reset_state() method
- **Network desync**: Server-authoritative pool with RPC validation
- **Memory leaks**: Proper cleanup in _exit_tree() for pool nodes