# US-056 tasks: Monster A* pathfinding

**Story**: [US-056.md](../../US-056.md)  
**Branch**: `056-monster-astar-pathfinding`  
**Status**: Signed — Gameplay T001–T006 implemented

Shared host A\* on the 128px cell grid so monsters walk around walls, cliffs, and solid buildings. Frame-budgeted, not per-tick flood fill. Aggro/raid/gremlin **rules** stay in US-011 / US-012 / US-013; this story only changes **how they locomote**.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-occupancy-grid.md) | Host occupancy grid (walkable vs wall/cliff/void/building) | Gameplay / Systems | Dungeon walkable + MapBounds + buildings | |
| [T002](T002-astar-service.md) | Shared AStarGrid2D service: 4-conn A\*, LOS skip, repath interval, frame budget, cache | Gameplay / Systems | T001 | |
| [T003](T003-chase-and-raid-follow.md) | Waypoint follow; wire `EnemyStateAggro` chase + goblin building approach | Gameplay | T002 | |
| [T004](T004-gremlin-inland.md) | Gremlin pile/flee/wander uses service; cliff-adjacent extra cost (US-013 inland) | Gameplay | T002 | with T003 |
| [T005](T005-wander-and-boss-chase.md) | Wander blocked-step reject; Baja boss chase (not jet) | Gameplay | T002 | with T003 |
| [T006](T006-verification-harness.md) | Around-wall, no-path, LOS skip, budget cap, occupancy dirty | QA / Gameplay | T003–T005 | |

## Out of scope

- Player/DM pathfinding; projectiles; unit-as-solid crowding; navmesh bake; generation `PathValidator` replacement; AI targeting/damage.
