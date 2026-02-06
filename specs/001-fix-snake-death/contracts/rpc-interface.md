# RPC Interface Contracts: Snake-Mode Death System

**Date**: February 5, 2026  
**Feature**: Fix snake-mode death system  
**Protocol**: Godot 4.5 RPC system with ENet multiplayer

## Death Event RPCs

### Client → Server RPCs

#### request_player_death
**Purpose**: Client notifies server of player death in snake-mode
**Authority**: `"any_peer"` - any connected client can call
**Reliability**: `"reliable"` - critical event that must be delivered
**Call Local**: `false` - only server processes this call

```gdscript
@rpc("any_peer", "call_remote", "reliable")
func request_player_death(death_position: Vector2, cause: String = "") -> void
```

**Parameters**:
- `death_position: Vector2` - World coordinates where player died
- `cause: String` - Optional death cause identifier

**Server Validation**:
- Verify calling player is actually in snake-mode
- Validate death_position is within reasonable bounds of player location  
- Check player is not already dead or in respawn delay
- Ensure death conditions are met (health <= 0, valid game state)

**Response**: Server processes death and triggers `notify_player_death` to all clients

---

#### request_item_pickup
**Purpose**: Client requests to pick up a dropped item
**Authority**: `"any_peer"` - any client can attempt pickup
**Reliability**: `"reliable"` - item pickup is critical transaction

```gdscript
@rpc("any_peer", "call_remote", "reliable")
func request_item_pickup(item_network_id: String) -> void
```

**Parameters**:
- `item_network_id: String` - Unique identifier of the DroppedItem to pick up

**Server Validation**:
- Verify item exists and is in Available state
- Check requesting player can reach item location
- Ensure player has inventory space for the item
- Validate item hasn't been picked up by another player concurrently

**Response**: Server processes pickup and triggers `notify_item_collected` to all clients

---

### Server → Client RPCs

#### notify_player_death  
**Purpose**: Server broadcasts player death event to all clients
**Authority**: `"authority"` - only server can call
**Reliability**: `"reliable"` - all clients must receive death notification
**Call Local**: `true` - server also processes locally

```gdscript
@rpc("authority", "call_local", "reliable")
func notify_player_death(player_id: int, death_position: Vector2, death_time: float) -> void
```

**Parameters**:
- `player_id: int` - Network ID of deceased player
- `death_position: Vector2` - World coordinates where death occurred
- `death_time: float` - Server timestamp of death event

**Client Processing**:
- Update visual representation of deceased player
- Trigger death animation if player is visible
- Update UI to reflect player death state
- Prepare to receive dropped item notifications

---

#### notify_items_dropped
**Purpose**: Server informs all clients about items dropped at death location  
**Authority**: `"authority"` - only server can spawn items
**Reliability**: `"reliable"` - items must appear for all players
**Call Local**: `true` - server maintains authoritative item list

```gdscript
@rpc("authority", "call_local", "reliable") 
func notify_items_dropped(items_data: Array[Dictionary], spawn_position: Vector2) -> void
```

**Parameters**:
- `items_data: Array[Dictionary]` - Serialized item information with structure:
  ```gdscript
  {
    "network_id": String,      # Unique identifier for synchronization
    "item_type": String,       # Type from ItemDatabase  
    "quantity": int,           # Stack size if applicable
    "properties": Dictionary   # Custom item properties (durability, etc.)
  }
  ```
- `spawn_position: Vector2` - Base location where items should appear

**Client Processing**:
- Spawn visual DroppedItem scenes at calculated positions around spawn_position
- Add items to client-side tracking for pickup detection
- Display items as interactable objects in game world

---

#### notify_item_collected
**Purpose**: Server notifies all clients that an item was picked up
**Authority**: `"authority"` - only server can confirm pickups
**Reliability**: `"reliable"` - all clients must remove collected items
**Call Local**: `true` - server updates authoritative state

```gdscript
@rpc("authority", "call_local", "reliable")
func notify_item_collected(item_network_id: String, collector_player_id: int) -> void
```

**Parameters**:
- `item_network_id: String` - Unique identifier of collected item
- `collector_player_id: int` - ID of player who picked up the item

**Client Processing**:
- Remove DroppedItem visual representation from world
- Update collector's inventory display if they are local player
- Clean up client-side item tracking data

---

#### notify_player_respawn_delay
**Purpose**: Server informs specific client about respawn delay timer
**Authority**: `"authority"` - only server manages respawn timing
**Reliability**: `"reliable"` - player must know when they can respawn
**Target**: Specific client only (not broadcast)

```gdscript
@rpc("authority", "call_remote", "reliable")
func notify_player_respawn_delay(delay_duration: float, spawn_position: Vector2) -> void
```

**Parameters**:
- `delay_duration: float` - Total time in seconds before respawn (e.g., 3.0)
- `spawn_position: Vector2` - Pre-selected respawn location in reality zone

**Client Processing**:
- Display respawn countdown UI to player
- Show respawn location on minimap/UI if applicable
- Prepare player controls for respawn state

---

#### notify_player_respawned
**Purpose**: Server broadcasts that a player has respawned to all clients
**Authority**: `"authority"` - only server can execute respawns
**Reliability**: `"reliable"` - all clients must see respawned player
**Call Local**: `true` - server updates local state

```gdscript
@rpc("authority", "call_local", "reliable")
func notify_player_respawned(player_id: int, respawn_position: Vector2, respawn_time: float) -> void
```

**Parameters**:
- `player_id: int` - Network ID of respawned player
- `respawn_position: Vector2` - Exact coordinates where player respawned
- `respawn_time: float` - Server timestamp of respawn event

**Client Processing**:
- Move player character to respawn position
- Reset player visual state (health, animations, etc.)
- Update UI to reflect player is alive and active
- Enable normal gameplay controls for respawned player

---

## Signal Integration

### SignalBus Signals  
These signals provide loose coupling between RPC system and game logic:

```gdscript
# Death event signals
signal player_death_requested(player_id: int, position: Vector2)
signal player_death_processed(player_id: int, items: Array[DroppedItem])

# Item system signals  
signal items_dropped_at_location(items: Array[DroppedItem], position: Vector2)
signal item_pickup_requested(item_id: String, player_id: int)
signal item_collected_successfully(item_id: String, collector: int)

# Respawn system signals
signal player_respawn_delay_started(player_id: int, delay: float)
signal respawn_location_selected(player_id: int, position: Vector2)
signal player_respawn_completed(player_id: int, position: Vector2)
```

### Signal Flow Integration
1. RPC received → validate input → emit appropriate signal
2. Game systems listen for signals and execute business logic
3. Game systems emit completion signals back to RPC system
4. RPC system broadcasts results to appropriate clients

## Error Handling & Edge Cases

### RPC Failure Responses
- **Invalid player death**: Send error RPC to requesting client, no broadcast
- **Item pickup conflict**: Send failure notification to requesting client
- **Respawn location unavailable**: Select alternative spawn point, notify client of change

### Network Error Recovery
- **Client disconnect during death**: Server cleans up death timers and reserved spawn points
- **RPC delivery failure**: Client requests resync of dropped items from server
- **Server restart**: Clients reconnect and request current world state including active items

### Rate Limiting
- **Death spam protection**: Maximum 1 death request per player per 5 seconds
- **Pickup spam protection**: Maximum 5 item pickup attempts per player per second
- **Client validation**: Server tracks client request patterns and disconnects abusive clients

## Testing Contracts

### Unit Test Requirements
- Each RPC function must have validation test cases
- Parameter boundary testing (invalid Vector2, negative values, etc.)
- Authority verification tests (client cannot call server-only RPCs)

### Integration Test Requirements  
- End-to-end death flow: client death → item drops → respawn delay → respawn
- Concurrent access tests: multiple players picking up items simultaneously
- Network failure simulation: packet loss, client disconnect, server lag