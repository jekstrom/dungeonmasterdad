# ItemPickup API Contract
# Enhanced pickup item interface with pool lifecycle support

class_name ItemPickupAPI extends CharacterBody2D

# ================================================
# ENHANCED ITEM PICKUP INTERFACE
# Extends existing pickup with pool state management
# ================================================

## Pool State Management
enum PoolState {
	ACTIVE,    # Item is active in game world
	POOLED,    # Item is stored in pool, inactive  
	RESETTING  # Item is transitioning between states
}

## Core Properties (Enhanced)

# Existing properties preserved from current implementation
@export var item_data: ItemData
@export var drop_player_id: int = -1
@export var grace_period: float = 1.0

# New pool-specific properties
var pool_state: PoolState = PoolState.ACTIVE
var reset_required: bool = false
var pool_id: String = ""

## Existing Methods (Enhanced)

# Configure item from spawn data dictionary  
# Enhanced to support pool state initialization
func configure_from_data(data: Dictionary) -> void:
	assert(data.has("item_type"), "Spawn data must include item_type")
	assert(data.has("spawn_position"), "Spawn data must include spawn_position")

# Handle pickup collection by player
# Enhanced to return to pool instead of queue_free()
func handle_pickup(player: CharacterBody2D) -> bool:
	assert(player != null, "Player cannot be null")
	return false  # Implementation-specific

## New Pool Lifecycle Methods

# Reset all item state for reuse from pool
# Must clear all dynamic properties
func reset_state() -> void:
	# Reset position, velocity, timers, audio, etc.
	pass

# Return item to pool instead of destroying
# Replaces all queue_free() calls
func return_to_pool() -> void:
	assert(pool_state == PoolState.ACTIVE, "Can only return active items")

# Validate item is ready for pool reuse
# Called before item activation
func validate_pool_state() -> bool:
	return pool_state == PoolState.POOLED

# Initialize item from pool for new spawn
# Replaces scene instantiation setup  
func activate_from_pool() -> void:
	assert(pool_state == PoolState.POOLED, "Can only activate pooled items")

## State Transition Methods

# Transition item to pooled state
func _transition_to_pooled() -> void:
	pool_state = PoolState.RESETTING
	# Disable processing, hide visuals, reset position
	set_process(false)
	set_physics_process(false)
	visible = false
	position = Vector2(-10000, -10000)
	pool_state = PoolState.POOLED

# Transition item to active state  
func _transition_to_active() -> void:
	pool_state = PoolState.RESETTING
	# Enable processing, show visuals, set spawn position
	set_process(true)
	set_physics_process(true)
	visible = true
	pool_state = PoolState.ACTIVE

## RPC Methods (Enhanced)

# Enhanced pickup request with pool validation
@rpc("any_peer", "call_remote", "reliable")
func pick_up_request(item_path: String) -> void:
	assert(multiplayer.get_remote_sender_id() != 1, "Server should not send pickup requests")

# Enhanced client update with pool state sync  
@rpc("authority", "call_remote", "reliable")
func update_client(new_position: Vector2, new_velocity: Vector2) -> void:
	assert(multiplayer.is_server(), "Only server can update clients")

## Debug and Validation Methods

# Get current item state for debugging
func get_debug_state() -> Dictionary:
	return {
		"pool_state": PoolState.keys()[pool_state],
		"item_type": item_data.name if item_data else "none",
		"position": position,
		"is_processing": is_processing(),
		"visible": visible,
		"grace_period_active": grace_period > 0.0
	}

# Validate item integrity for pool usage
func validate_integrity() -> bool:
	# Check all required components exist and are properly configured
	return item_data != null and get_parent() != null