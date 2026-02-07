# PickupSpawner RPC Contract
# Enhanced MultiplayerSpawner with pool integration

class_name PickupSpawnerAPI extends MultiplayerSpawner

# ================================================
# ENHANCED PICKUP SPAWNER RPC INTERFACE
# Extends MultiplayerSpawner with pool-aware operations
# ================================================

## Pool Integration Configuration
@export var use_pooling: bool = true
@export var fallback_to_instantiate: bool = true
@export var pool_performance_logging: bool = false

## Enhanced Spawning Interface

# Enhanced custom spawn with pool integration
# Overrides MultiplayerSpawner._custom_spawn()
func _custom_spawn(data: Dictionary) -> Node2D:
	assert(data.has("item_type"), "Spawn data must include item_type")
	assert(data.has("spawn_position"), "Spawn data must include spawn_position")
	assert(multiplayer.is_server(), "Only server can spawn items")
	return null  # Implementation-specific

# Enhanced despawn with pool return
# Overrides MultiplayerSpawner._custom_despawn()  
func _custom_despawn(node: Node) -> void:
	assert(node != null, "Cannot despawn null node")
	assert(multiplayer.is_server(), "Only server can despawn items")

## Pool-Aware Operations

# Request pickup from pool with fallback
# Returns null only on critical failure
func request_pooled_pickup(item_type: String) -> ItemPickup:
	assert(item_type.length() > 0, "Item type required")
	assert(multiplayer.is_server(), "Only server can request from pool")
	return null  # Implementation-specific

# Handle pool exhaustion with graceful fallback
# Creates new item when pool is empty
func handle_pool_exhaustion(item_type: String) -> ItemPickup:
	assert(fallback_to_instantiate, "Pool exhaustion without fallback")
	return null  # Implementation-specific

## RPC Methods for Pool State Sync

# Sync pool item state to all clients
# Used when items transition between pool and active
@rpc("authority", "call_remote", "reliable")  
func sync_pool_item_state(item_id: String, state_data: Dictionary) -> void:
	assert(multiplayer.is_server(), "Only server can sync pool state")
	assert(item_id.length() > 0, "Item ID required")

# Notify clients of pool item activation
# Sent when item moves from pool to active state
@rpc("authority", "call_remote", "reliable")
func notify_item_activated(item_id: String, spawn_data: Dictionary) -> void:
	assert(multiplayer.is_server(), "Only server can notify activation")

# Notify clients of pool item deactivation  
# Sent when item moves from active to pool state
@rpc("authority", "call_remote", "reliable")
func notify_item_deactivated(item_id: String) -> void:
	assert(multiplayer.is_server(), "Only server can notify deactivation")

## Pool Performance Monitoring

# Get spawner-specific pool statistics
func get_spawner_pool_stats() -> Dictionary:
	return {
		"total_spawns": 0,
		"pool_spawns": 0,
		"instantiated_spawns": 0,
		"active_items": 0,
		"pool_hit_ratio": 0.0
	}

# Enable/disable pool performance tracking
func set_pool_logging(enabled: bool) -> void:
	pool_performance_logging = enabled

## Validation and Debug Methods

# Validate all active items are properly tracked
func validate_active_items() -> bool:
	return true  # Implementation-specific

# Get debug information for troubleshooting
func get_debug_info() -> Dictionary:
	return {
		"use_pooling": use_pooling,
		"fallback_enabled": fallback_to_instantiate,
		"active_count": active_pickups.size(),
		"pool_available": PickupPool.get_available_count() if use_pooling else 0
	}

## Signal Definitions for Pool Integration

# Emitted when item is successfully retrieved from pool
signal item_retrieved_from_pool(item: ItemPickup)

# Emitted when item is returned to pool
signal item_returned_to_pool(item: ItemPickup)

# Emitted when pool is exhausted and fallback instantiation occurs
signal pool_exhausted(item_type: String)

# Emitted when pool operation fails
signal pool_operation_failed(operation: String, error: String)