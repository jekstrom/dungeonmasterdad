# Object Pooling API Contracts

This directory contains GDScript interface definitions for the object pooling system implementation.

## Contract Files

### `pickup-pool-api.gd`
Singleton interface for global pickup item pool management. Defines core operations for getting/returning items from pool, statistics tracking, and debug functionality.

**Key Operations:**
- `get_pickup(item_type)` - Retrieve item from pool or create new
- `return_pickup(pickup)` - Return collected item to pool  
- `get_pool_stats()` - Performance monitoring data
- `initialize_pool()` / `cleanup_pool()` - Lifecycle management

### `item-pickup-api.gd`
Enhanced pickup item interface with pool state management. Extends existing ItemPickup with pooling lifecycle methods.

**Key Enhancements:**
- `PoolState` enum for item lifecycle tracking
- `reset_state()` - Prepare item for reuse from pool
- `return_to_pool()` - Replace queue_free() calls
- `activate_from_pool()` - Initialize item when retrieved

### `pickup-spawner-rpc.gd`
Enhanced MultiplayerSpawner with pool integration. Extends existing PickupSpawner with pool-aware spawning.

**Key Features:**
- Pool-first spawning with MultiplayerSpawner fallback
- RPC methods for pool state synchronization
- Performance monitoring and debug capabilities
- Server-authoritative pool operations

## Usage Notes

These contracts define the **interface** for implementation. They specify:
- Method signatures and parameters
- Assertion requirements for validation
- RPC patterns for multiplayer synchronization
- Expected behavior and constraints

## Implementation Guidelines

1. **Server Authority**: All pool operations must be server-authoritative
2. **Fallback Strategy**: Pool exhaustion must gracefully fallback to instantiation
3. **State Validation**: Items must be properly reset when pooled/activated
4. **RPC Reliability**: Use reliable RPCs for pool state synchronization
5. **Performance Tracking**: Include metrics for pool utilization analysis

## Integration Points

The contracts integrate with existing systems:
- **MultiplayerSpawner**: Enhanced rather than replaced
- **ItemPickup**: Extended with pool lifecycle
- **SignalBus**: Maintains existing event patterns
- **ItemDatabase**: Unchanged item data access

This ensures backward compatibility while adding pool optimization.