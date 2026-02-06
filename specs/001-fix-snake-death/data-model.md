# Data Model: Snake-Mode Death System Fix

**Date**: February 5, 2026  
**Feature**: Fix item drop synchronization in multiplayer snake-mode deaths

## Entity Overview

This fix involves modifying the interaction between existing entities rather than creating new data structures. The core entities in the death system are:

## Core Entities

### PlayerDeathEvent
**Purpose**: Represents a player death occurrence in snake-mode

**Attributes**:
- `player_id: int` - Network ID of the deceased player
- `death_position: Vector2` - World coordinates where death occurred  
- `death_time: float` - Server timestamp of death event
- `snake_mode: bool` - Whether player was in snake-mode (always true for this feature)
- `cause: String` - Death cause identifier (optional, for future expansion)

**State Transitions**:
1. **Created** → When player death is detected
2. **Processing** → Server validates death conditions
3. **Broadcast** → Death event sent to all clients
4. **Completed** → All clients acknowledge death event

**Validation Rules**:
- `player_id` must be valid connected player
- `death_position` must be within valid game world bounds  
- `death_time` must be current server time ± tolerance
- Only server can create PlayerDeathEvent instances

### DroppedItem
**Purpose**: Individual inventory item that appears at death location

**Attributes**:
- `network_id: String` - Unique identifier for multiplayer synchronization
- `item_type: String` - Type identifier from ItemDatabase
- `item_data: Dictionary` - Serialized item properties (quantity, durability, etc.)
- `world_position: Vector2` - Ground location where item appears
- `spawn_time: float` - Server timestamp when item was dropped
- `source_player_id: int` - ID of player who dropped the item
- `is_pickable: bool` - Whether item can currently be picked up

**State Transitions**:
1. **Spawned** → Item appears in world at death location
2. **Available** → Item can be picked up by any player
3. **Reserved** → Player is attempting to pick up (prevents conflicts)
4. **Collected** → Item has been picked up and should be removed
5. **Expired** → Item times out and should be cleaned up

**Validation Rules**:
- `network_id` must be unique across all active DroppedItems
- `item_type` must exist in ItemDatabase
- `world_position` must be accessible to players
- Only server can change item state
- `is_pickable` only true when state is Available

**Relationships**:
- Belongs to one PlayerDeathEvent (source)
- Can be collected by any Player (but only once)

### RealityZoneSpawnPoint  
**Purpose**: Designated respawn location within reality zone

**Attributes**:
- `zone_id: String` - Identifier for the reality zone
- `spawn_position: Vector2` - Exact world coordinates for respawn
- `is_available: bool` - Whether spawn point is currently free
- `priority: int` - Preference order for spawn point selection (lower = higher priority)
- `last_used_time: float` - Server timestamp of last player spawn
- `cooldown_duration: float` - Minimum time before reuse (prevents clustering)

**State Transitions**:
1. **Available** → Spawn point is free for use
2. **Reserved** → Spawn point selected for incoming respawn
3. **Occupied** → Player has spawned here (temporary state)
4. **Cooldown** → Spawn point temporarily unavailable after use

**Validation Rules**:
- `spawn_position` must be within RealityZone boundaries
- `is_available` controlled by server-side spawn management
- `priority` must be positive integer
- Only server can reserve/release spawn points

**Relationships**:
- Belongs to one RealityZone
- Used by Player respawn events

### RespawnDelayTimer
**Purpose**: Manages timing between death and respawn for individual players

**Attributes**:
- `player_id: int` - ID of player waiting to respawn
- `delay_duration: float` - Total delay time in seconds (e.g., 3.0-5.0)
- `remaining_time: float` - Countdown timer value
- `start_time: float` - Server timestamp when delay started
- `is_active: bool` - Whether timer is currently running
- `target_spawn_point: RealityZoneSpawnPoint` - Pre-selected respawn location

**State Transitions**:
1. **Created** → Timer instantiated for dead player
2. **Active** → Countdown is running
3. **Paused** → Timer temporarily stopped (e.g., server lag compensation)
4. **Expired** → Delay completed, player can respawn
5. **Cancelled** → Timer stopped due to player disconnect or other event

**Validation Rules**:
- `player_id` must be valid and currently dead
- `delay_duration` must be within configured min/max bounds
- Only one active RespawnDelayTimer per player
- `target_spawn_point` must be reserved before timer expiry

**Relationships**:
- Associated with one Player (1:1 during death state)
- References one RealityZoneSpawnPoint (reserved)

## Data Flow Relationships

### Death Event Flow
1. **Player** → triggers death → creates **PlayerDeathEvent**
2. **PlayerDeathEvent** → spawns multiple **DroppedItem** instances
3. **PlayerDeathEvent** → creates **RespawnDelayTimer** for the player
4. **RespawnDelayTimer** → reserves **RealityZoneSpawnPoint** for respawn

### Item Lifecycle Flow  
1. **DroppedItem** spawned at death location (server authoritative)
2. **DroppedItem** synchronized to all clients via RPC
3. Any **Player** can collect **DroppedItem** (first-come-first-served)
4. **DroppedItem** removed from world after collection or timeout

### Respawn Flow
1. **RespawnDelayTimer** counts down after death
2. Server selects available **RealityZoneSpawnPoint**
3. **Player** respawns at **RealityZoneSpawnPoint** location
4. **RealityZoneSpawnPoint** enters cooldown period

## Multiplayer Synchronization

### Server Authority
- Server creates and manages all entity instances
- All state changes must be validated server-side
- Clients receive entity updates via RPC broadcasts

### Client Representation
- Clients maintain visual representations only
- Client-side entities are read-only mirrors of server data
- Client predictions limited to UI feedback (death animations, etc.)

### Network Synchronization Events
- **death_event_broadcast**: Notifies all clients of PlayerDeathEvent
- **item_dropped**: Synchronizes DroppedItem spawn across clients  
- **item_collected**: Notifies all clients when DroppedItem is picked up
- **player_respawn**: Informs clients of player respawn at new location

## Performance Considerations

### Memory Management
- DroppedItems automatically cleaned up after 5 minutes if not collected
- RespawnDelayTimer instances destroyed after completion
- PlayerDeathEvent data cleared after all related items processed

### Network Optimization  
- Batch multiple DroppedItem spawns into single RPC call when possible
- Use compressed item data (type IDs instead of full serialization)
- Limit RPC frequency for non-critical updates

### Scalability Limits
- Maximum 50 DroppedItems active simultaneously (prevent spam)
- Maximum 10 concurrent RespawnDelayTimers (death event throttling)  
- RealityZoneSpawnPoint cooldown prevents spawn point exhaustion