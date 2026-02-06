# DeathSystem RPC Contract Specification
# File: /specs/001-fix-snake-death/contracts/death-system-rpc.gd
# Purpose: Define the RPC interface for multiplayer death event handling

# =============================================================================
# CLIENT → SERVER RPCs (Death Request)
# =============================================================================

# Request player death from client to server
# Used when player dies in snake-mode from trail collision
@rpc("any_peer", "call_remote", "reliable")
func request_player_death(death_position: Vector2, cause: String = "") -> void:
	"""
	Client requests death processing from server
	
	Parameters:
	- death_position: Vector2 - World coordinates where death occurred
	- cause: String - Optional death cause ("snake_trail_collision", etc.)
	
	Authority: Client → Server only
	Reliability: Must be reliable to ensure death events are processed
	Validation: Server validates player_id, death_position, and rate limiting
	
	Response: Server calls _handle_player_death() if validation passes
	"""
	pass

# =============================================================================
# SERVER → CLIENT RPCs (Death Event Broadcasting)  
# =============================================================================

# Notify all clients that a player has died
@rpc("authority", "call_local", "reliable")
func notify_player_death(player_id: int, death_position: Vector2, death_time: float) -> void:
	"""
	Server broadcasts death event to all connected clients
	
	Parameters:
	- player_id: int - Network ID of the deceased player
	- death_position: Vector2 - World coordinates of death
	- death_time: float - Server timestamp of death event
	
	Authority: Server → All Clients
	Reliability: Must be reliable to ensure consistent game state
	Side Effects: Emits SignalBus.player_death_processed signal
	"""
	pass

# Notify all clients of item drops from death
@rpc("authority", "call_local", "reliable") 
func notify_items_dropped(items_data: Array, spawn_position: Vector2) -> void:
	"""
	Server synchronizes dropped items across all clients
	
	Parameters:
	- items_data: Array[ItemData] - List of items to spawn as pickups
	- spawn_position: Vector2 - Base position for item scattering
	
	Authority: Server → All Clients (including server with call_local)
	Reliability: Must be reliable to ensure items appear for all players
	Side Effects: 
	- Spawns pickup items on all clients
	- Items scattered randomly around spawn_position
	- Emits SignalBus.items_dropped_at_location signal
	"""
	pass

# Notify specific client about respawn delay start
@rpc("authority", "call_remote", "reliable")
func notify_player_respawn_delay(delay_duration: float, spawn_position: Vector2) -> void:
	"""
	Server informs dead player about respawn delay and location
	
	Parameters:
	- delay_duration: float - Total delay time in seconds (typically 3.0)
	- spawn_position: Vector2 - Where player will respawn after delay
	
	Authority: Server → Specific Client (dead player only)
	Reliability: Must be reliable to ensure player knows respawn status
	Side Effects: Emits SignalBus.player_respawn_delay_started signal
	Target: Sent only to the player_id who died
	"""
	pass

# Notify all clients when player respawns
@rpc("authority", "call_local", "reliable")
func notify_player_respawned(player_id: int, respawn_position: Vector2, respawn_time: float) -> void:
	"""
	Server broadcasts player respawn completion to all clients
	
	Parameters:
	- player_id: int - Network ID of respawning player
	- respawn_position: Vector2 - World coordinates of respawn location  
	- respawn_time: float - Server timestamp of respawn event
	
	Authority: Server → All Clients
	Reliability: Must be reliable to ensure all players see respawn
	Side Effects:
	- Emits SignalBus.player_respawn_completed signal
	- Cleans up death timers and reservations
	- Updates player position on all clients
	"""
	pass

# Send respawn countdown updates to waiting player
@rpc("authority", "call_remote", "unreliable")
func notify_respawn_countdown_update(remaining_time: float) -> void:
	"""
	Server sends periodic countdown updates during respawn delay
	
	Parameters:
	- remaining_time: float - Seconds remaining until respawn
	
	Authority: Server → Specific Client (dead player only) 
	Reliability: Unreliable OK since this is frequent non-critical UI feedback
	Frequency: Every 0.5 seconds during respawn delay
	Side Effects: Updates client UI countdown display
	"""
	pass

# =============================================================================
# RPC CONTRACT VALIDATION RULES
# =============================================================================

"""
AUTHORITY MODEL:
- Server has authority over all death processing and item spawning
- Clients can request death but cannot directly modify game state
- All game-changing operations must be validated server-side

RATE LIMITING:
- request_player_death() limited to MAX_DEATH_REQUESTS_PER_SECOND (0.2/sec)
- Server validates death cooldowns per player
- Prevents spam and griefing

RELIABILITY REQUIREMENTS:
- Critical events (death, items, respawn) use reliable RPCs
- Non-critical updates (countdown) use unreliable RPCs for performance
- Failed reliable RPCs should be logged for debugging

ERROR HANDLING:
- Invalid player_id → ignored with warning
- Out-of-bounds death_position → clamped to valid area  
- Missing item data → skipped with error log
- Disconnected player during respawn → cleanup timers and reservations

SYNCHRONIZATION GUARANTEES:
- All clients receive identical item drop notifications
- Item spawn positions consistent across clients (same random seed)
- Respawn location selected server-side for consistency
- State changes broadcast before client predictions allowed
"""

# =============================================================================
# INTEGRATION WITH EXISTING SYSTEMS
# =============================================================================

"""
PlayerSnakeState.gd Integration:
- Replace PlayerManager.drop_all_inventory() call
- Replace PlayerManager.respawn_player() call  
- Use request_player_death.rpc() on clients
- Use _handle_player_death() directly on server

PlayerManager.gd Integration:
- DeathSystem extracts inventory via _extract_player_inventory()
- PlayerManager inventory cleared after extraction
- update_client_inventory.rpc() called to sync empty inventory
- PlayerManager death methods become deprecated

SignalBus.gd Integration:
- SignalBus.player_death_processed signal emitted
- SignalBus.player_respawn_delay_started signal emitted  
- SignalBus.player_respawn_completed signal emitted
- SignalBus.items_dropped_at_location signal emitted

Pickup System Integration:
- notify_items_dropped() spawns regular pickup.tscn instances
- Pickup items behave identically to other dropped items
- No changes required to existing pickup interaction logic
"""