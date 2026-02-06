# Quickstart: Snake-Mode Death Item Synchronization Fix

**Date**: February 5, 2026  
**Estimated Implementation Time**: 30 minutes  
**Complexity**: Low (2-line change + testing)

## Problem Summary

Items dropped by players dying in snake-mode only appear on the server, not for other connected clients. This breaks multiplayer gameplay by preventing other players from collecting dropped items.

## Root Cause

Snake-mode death uses legacy `PlayerManager.drop_all_inventory()` which creates items locally without RPC synchronization, instead of the modern `DeathSystem` which properly broadcasts item spawns to all clients.

## Solution Overview  

Route snake-mode deaths through the existing `DeathSystem` instead of `PlayerManager` to leverage established multiplayer synchronization.

## Prerequisites

- Godot 4.5 project with existing multiplayer infrastructure
- ENet multiplayer configured on port 42069  
- SignalBus singleton available for cross-system communication
- Existing player state machine architecture
- Reality zone boundaries defined in game world

## Quick Implementation Steps

### 1. Core System Setup (30 minutes)

**A. Create Death System Singleton**
```gdscript
# scripts/multiplayer/DeathSystem.gd
extends Node

const RESPAWN_DELAY = 3.0  # seconds
var active_death_timers: Dictionary = {}  # player_id -> Timer

@rpc("any_peer", "call_remote", "reliable")
func request_player_death(death_position: Vector2, cause: String = ""):
    if not multiplayer.is_server():
        return
    
    var player_id = multiplayer.get_remote_sender_id()
    _handle_player_death(player_id, death_position, cause)
```

**B. Add to AutoLoad**
- Open Project Settings → AutoLoad
- Add `DeathSystem` with path: `scripts/multiplayer/DeathSystem.gd`

### 2. Enhance Player Death State (20 minutes)

```gdscript  
# player/states/PlayerDeathState.gd - add to existing Enter() method
func Enter() -> void:
    # Existing death state logic...
    
    # NEW: Drop items and notify server  
    if multiplayer.is_server():
        _drop_player_items()
    else:
        # Client requests death processing
        DeathSystem.request_player_death(player.global_position)
```

### 3. Create Dropped Item System (45 minutes)

**A. Create DroppedItem Scene**
- New scene: `pickups/DroppedItem.tscn`
- Root: `CharacterBody2D` with `Pickup.gd` script
- Add: `Sprite2D`, `CollisionShape2D`, `Area2D` for pickup detection

**B. Add Item Synchronization**
```gdscript
# In DeathSystem.gd
@rpc("authority", "call_local", "reliable")  
func notify_items_dropped(items_data: Array, spawn_position: Vector2):
    for item_data in items_data:
        var dropped_item = preload("res://pickups/DroppedItem.tscn").instantiate()
        dropped_item.setup_from_data(item_data, spawn_position)
        get_tree().current_scene.add_child(dropped_item)
```

### 4. Implement Reality Zone Respawn (25 minutes)

```gdscript
# zones/RealityZone.gd - add spawn point management
var spawn_points: Array[Vector2] = []  # Define spawn positions
var last_used_spawn: int = 0

func get_next_spawn_point() -> Vector2:
    if spawn_points.is_empty():
        return global_position  # Fallback to zone center
    
    last_used_spawn = (last_used_spawn + 1) % spawn_points.size()  
    return spawn_points[last_used_spawn]
```

### 5. Add Respawn Delay Timer (15 minutes)

```gdscript
# In DeathSystem.gd - add respawn delay handling
func _handle_player_death(player_id: int, position: Vector2, cause: String):
    # Drop items (implementation details in full docs)
    _drop_items_for_player(player_id, position)
    
    # Start respawn delay
    var delay_timer = Timer.new()
    delay_timer.wait_time = RESPAWN_DELAY
    delay_timer.one_shot = true
    delay_timer.timeout.connect(_respawn_player.bind(player_id))
    add_child(delay_timer)
    delay_timer.start()
    
    active_death_timers[player_id] = delay_timer
```

## Testing Your Implementation

### Quick Test (10 minutes)
1. Launch server instance: `godot --path . --headless`
2. Launch 2 client instances in separate terminals
3. Have one player die while other observes
4. Verify: items appear for both players, death player respawns in reality zone after delay

### Verification Checklist
- [ ] Items dropped by dying player appear for all connected clients
- [ ] Items can be picked up by surviving players  
- [ ] Dead player respawns in reality zone (not at death location)
- [ ] Respawn delay prevents immediate return (3-5 second delay)
- [ ] Multiple simultaneous deaths work correctly
- [ ] System maintains 60 fps during death events

## Common Issues & Fixes

### Issue: Items Don't Appear for All Players
**Cause**: RPC not reaching all clients  
**Fix**: Verify RPC uses `"call_local"` and `"reliable"` parameters

### Issue: Player Respawns at Death Location  
**Cause**: Client-side respawn logic overriding server  
**Fix**: Ensure respawn position comes from server RPC only

### Issue: Respawn Delay Too Short/Long
**Cause**: Timer not configured correctly  
**Fix**: Check `RESPAWN_DELAY` constant and Timer.wait_time setting

### Issue: Performance Drops During Death
**Cause**: Too many item drops or missing object pooling  
**Fix**: Limit max items per death (e.g., 10) and implement DroppedItem pooling

## File Structure After Implementation

```
_globals/
├── SignalBus.gd          # Enhanced with death event signals  
└── DeathSystem.gd        # NEW: Central death coordination

player/
├── Player.gd             # Enhanced with death RPC calls
└── states/
    ├── PlayerDeathState.gd    # Enhanced with item dropping
    └── PlayerRespawnWaitState.gd  # NEW: Respawn delay state

pickups/
├── DroppedItem.tscn      # NEW: Networked dropped item scene
├── DroppedItem.gd        # NEW: Dropped item behavior script  
└── Pickup.gd             # Enhanced for multiplayer pickup

zones/  
└── RealityZone.gd        # Enhanced with spawn point management

scripts/multiplayer/
├── DeathSystem.gd        # NEW: Main death system logic
└── SpawnManager.gd       # NEW: Advanced spawn point management (optional)
```

## Next Steps

1. **Performance Tuning**: Implement object pooling for DroppedItems if experiencing performance issues
2. **Advanced Features**: Add item expiration timers, spawn point cooldowns, death cause tracking
3. **UI Enhancements**: Create respawn countdown UI, death notifications, item pickup feedback
4. **Edge Case Handling**: Handle player disconnects during respawn delay, reality zone spawn point exhaustion

## Support & Documentation

- **Full Implementation Details**: See `data-model.md` and `contracts/rpc-interface.md`
- **Architecture Guidelines**: Reference `/AGENTS.md` for Godot best practices
- **Testing Protocol**: Detailed test cases available in feature specification
- **Performance Benchmarks**: Target metrics defined in success criteria

This quickstart gets the core functionality working in ~2 hours. Refer to the complete documentation for production-ready implementation with full error handling and edge case management.