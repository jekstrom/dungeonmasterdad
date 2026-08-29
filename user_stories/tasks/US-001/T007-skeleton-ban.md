# T007: Skeleton ban in Reality

**Story**: US-001  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: no

## Goal

Skeletons cannot exist in Reality-claimed space: walking in, being pushed in, spawning in, or a home/pocket covering them. Host despawns. Goblins, knightlings, and gremlins are **not** banned.

## Files

- Skeleton scene / `Enemy` spawn path (`monsters/skeleton/`)
- `scripts/procedural_dungeon/monster_spawn_planner.gd` and/or `scripts/multiplayer_spawner.gd` — reject skeleton spawns on claimed cells (overworld; dungeon claim is still Reality-occupancy if a pocket covers it)
- Host occupancy pass: any living skeleton whose position is claimed is removed the same frame it crosses or is covered

## Requirements

- FR-008, FR-009, AC5, AC6, AC7
- Removal is host-authoritative; all peers see it gone (replication details in T008).
- Home growth covering a skeleton = same as walk-in.
- Pocket appearing over a skeleton = same as walk-in.

## Acceptance

- **Given** a living skeleton, **When** its position is inside Reality (home or pocket), **Then** it is destroyed or despawned on the server.
- **Given** a skeleton would spawn inside Reality, **When** the spawn is evaluated, **Then** the spawn is rejected.
- **Given** the Reality home grows, **When** an existing skeleton is newly covered, **Then** that skeleton is removed.
- **Given** a goblin, knightling, or gremlin in Reality, **When** occupancy runs, **Then** they are not removed by this story.

## Notes

Do not retune combat. Dungeon-generated skeletons inside the dungeon remain unless a Reality pocket covers that cell.
