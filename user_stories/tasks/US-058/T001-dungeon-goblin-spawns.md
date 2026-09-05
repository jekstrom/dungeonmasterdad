# T001: Random dungeon goblin spawns

**Story**: US-058  
**Status**: Todo  
**Depends on**: existing `MonsterSpawnPlanner` / catalog  
**Owner**: Gameplay

## Goal

Generation MUST place **2–5 goblins** (seeded; scale loosely with mid count) on walkable dungeon cells: **mid rooms and/or hallways**. Exclude **start room** and **exit room**. Additive to skeletons and the Baja boss.

## Files

- `scripts/procedural_dungeon/monster_spawn_planner.gd`
- `scripts/procedural_dungeon/monster_catalog.gd` (already lists `goblin`)
- Headless spawn dump / contract dictionary `monsterSpawns`

## Requirements

- FR-001, FR-002, FR-008, AC1, AC7

## Acceptance

- **Given** a valid generate, **When** `monsterSpawns` is read, **Then** at least one `goblin` exists, none sit in start- or exit-room cells, and skeleton/boss spawns still appear when those knobs are on.
