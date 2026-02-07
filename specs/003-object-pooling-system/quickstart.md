# Quick Start: Object Pooling System Implementation

**Date**: 2026-02-06  
**Feature**: 003-object-pooling-system

## Overview

This guide provides step-by-step implementation and testing procedures for the object pooling system in Dungeon Master Dad. The system replaces pickup item destruction with reusable object management.

## Implementation Steps

### Phase 1: Create PickupPool Singleton

**File**: `/scripts/pickup_pool.gd`

```gdscript
class_name PickupPool extends Node

const POOL_SIZE = 50
var available_pickups: Array[ItemPickup] = []
var active_pickups: Dictionary = {}
var pool_stats = {"requests": 0, "hits": 0, "misses": 0}

func _ready():
    for i in POOL_SIZE:
        var pickup = preload("res://pickups/pickup.tscn").instantiate()
        pickup.set_process(false)
        pickup.set_physics_process(false)
        pickup.visible = false
        pickup.position = Vector2(-10000, -10000)
        available_pickups.append(pickup)
        add_child(pickup)

func get_pickup() -> ItemPickup:
    pool_stats.requests += 1
    if available_pickups.is_empty():
        pool_stats.misses += 1
        return null
    
    var pickup = available_pickups.pop_back()
    pool_stats.hits += 1
    return pickup

func return_pickup(pickup: ItemPickup):
    pickup.reset_state()
    available_pickups.append(pickup)
```

**Setup**: Add to `project.godot` autoload:
```ini
[autoload]
PickupPool="*res://scripts/pickup_pool.gd"
```

### Phase 2: Enhance ItemPickup

**File**: `/pickups/scripts/item_pickup.gd` (modify existing)

**Add to class**:
```gdscript
enum PoolState { ACTIVE, POOLED, RESETTING }
var pool_state: PoolState = PoolState.ACTIVE
var pool_id: String = ""

func reset_state():
    pool_state = PoolState.RESETTING
    velocity = Vector2.ZERO
    grace_period = 1.0
    drop_player_id = -1
    set_process(false)
    set_physics_process(false)
    visible = false
    position = Vector2(-10000, -10000)
    pool_state = PoolState.POOLED

func return_to_pool():
    PickupPool.return_pickup(self)
```

**Replace queue_free() calls** in `_server_cleanup()` and `_safe_queue_free()`:
```gdscript
# OLD: queue_free()
# NEW: return_to_pool()
```

### Phase 3: Enhance PickupSpawner

**File**: `/scripts/pickup_spawner.gd` (modify existing)

**Modify `_custom_spawn()` method**:
```gdscript
func _custom_spawn(data: Dictionary) -> Node2D:
    if not multiplayer.is_server():
        return null
    
    # Try pool first
    var pickup = PickupPool.get_pickup()
    if not pickup:
        # Fallback to instantiation
        pickup = pickup_scene.instantiate()
    
    # Configure pickup
    pickup.configure_from_data(data)
    pickup.set_process(true)
    pickup.set_physics_process(true)
    pickup.visible = true
    pickup.pool_state = ItemPickup.PoolState.ACTIVE
    
    active_pickups[pickup.name] = pickup
    return pickup
```

## Testing Procedures

### Manual Testing Setup

**Environment**: Use `playground.tscn` for all testing

**Required Setup**:
1. Launch server: `godot --headless`
2. Launch 2+ clients: `godot --path /path/to/project`
3. Connect all clients to server

### Test Case 1: Basic Pooling

**Objective**: Verify items are reused from pool

**Steps**:
1. Drop 5 items in game world
2. Collect all 5 items
3. Drop 5 more items
4. Verify: Items appear instantly (pool reuse)
5. Check pool stats: Should show hits > 0

**Expected Result**: Second drop uses pooled items, no instantiation delay

### Test Case 2: Pool Exhaustion

**Objective**: Verify fallback to instantiation

**Steps**:
1. Drop 60 items (more than POOL_SIZE=50)
2. Verify: All items appear correctly
3. Check pool stats: Should show misses > 0

**Expected Result**: First 50 use pool, remaining 10 use instantiation

### Test Case 3: Multiplayer Sync

**Objective**: Verify pool operations sync across clients

**Steps**:
1. Server drops item, client A collects it
2. Server drops another item in same location
3. Verify: Client B sees item appear correctly
4. Client B collects item
5. Verify: All clients see item disappear

**Expected Result**: Pool operations maintain multiplayer sync

### Test Case 4: Player Death Recovery

**Objective**: Verify death items use pooling

**Steps**:
1. Player dies with 5 items in inventory
2. Verify: 5 items drop immediately (pool speed)
3. Another player collects all items
4. First player dies again with same 5 items
5. Verify: Items reappear instantly

**Expected Result**: Death recovery uses pooled items efficiently

### Test Case 5: Performance Validation

**Objective**: Verify 60 fps maintained with many pickups

**Steps**:
1. Drop 100+ items in cluster
2. Monitor frame rate during drops
3. Collect all items rapidly
4. Monitor frame rate during collection
5. Verify: Consistent 60 fps throughout

**Expected Result**: No frame drops during pool operations

### Debug Commands

**Add to PickupPool for testing**:
```gdscript
func print_pool_stats():
    print("Pool Stats:")
    print("- Available: ", available_pickups.size())
    print("- Requests: ", pool_stats.requests)
    print("- Hit Ratio: ", float(pool_stats.hits) / pool_stats.requests * 100, "%")

func _input(event):
    if event.is_action_pressed("debug_pool"):
        print_pool_stats()
```

## Performance Monitoring

### Key Metrics

**Pool Utilization**:
- Hit ratio should be > 80% in normal gameplay
- Pool exhaustion should be rare (< 5% of requests)

**Memory Usage**:
- Baseline increase: ~50 pickup instances * ~1KB each = ~50KB
- Runtime stability: No memory growth over time

**Frame Rate**:
- Maintain 60 fps with 100+ active pickups
- Pool operations should be < 1ms each

### Optimization Tuning

**If pool hit ratio is low**:
- Increase `POOL_SIZE` constant
- Check item reset efficiency

**If memory usage is high**:
- Reduce `POOL_SIZE` for fewer pooled items
- Add cleanup timer for old pooled items

**If frame rate drops**:
- Profile pool allocation/return operations
- Check for inefficient state reset code

## Rollback Plan

**If pooling causes issues**:

1. Set `use_pooling = false` in PickupSpawner
2. Restore original `queue_free()` calls in ItemPickup
3. Comment out PickupPool autoload in project.godot

**All existing functionality will work unchanged with pooling disabled.**

## Implementation Checklist

- [ ] PickupPool singleton created and configured
- [ ] ItemPickup enhanced with pool lifecycle methods  
- [ ] PickupSpawner modified to use pool-first spawning
- [ ] queue_free() calls replaced with return_to_pool()
- [ ] Autoload configuration added to project.godot
- [ ] Basic pooling test passes
- [ ] Pool exhaustion test passes
- [ ] Multiplayer sync test passes
- [ ] Performance validation passes
- [ ] Debug monitoring tools functional

## Line Count Target

**Current Implementation**: ~150 lines across 3 files
- PickupPool: ~60 lines
- ItemPickup additions: ~40 lines  
- PickupSpawner modifications: ~50 lines

**Remaining Budget**: 150 lines for optimizations and monitoring