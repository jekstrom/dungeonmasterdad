# T008: Skeletons allowed in Fantasy unless Reality-claimed

**Story**: US-003  
**Status**: Todo  
**Depends on**: T001, US-001  
**Parallel**: no

## Goal

Skeletons may exist and act in Fantasy-claimed space **unless** that point is Reality-claimed under US-001 (Reality pocket override, or Reality skeleton ban on home-only overlap).

## Files

- Skeleton occupancy / US-001 T007 ban pass — query both claim APIs
- `scripts/procedural_dungeon/monster_spawn_planner.gd` and/or `scripts/multiplayer_spawner.gd` as needed for overworld spawns

## Requirements

- FR-008, FR-010, AC5
- Fantasy-claimed and **not** Reality-claimed: skeleton allowed.
- Reality pocket covering the point: skeleton banned (US-001 wins).
- Reality and Fantasy homes overlap, no pocket: skeleton still removed (Reality ban wins for skeletons).
- Goblins, knightlings, and gremlins are unchanged by this story.

## Acceptance

- **Given** a skeleton inside Fantasy-claimed area that is not Reality-claimed, **When** occupancy is evaluated, **Then** the skeleton is allowed to exist and act.
- **Given** a Reality pocket over that cell, **When** occupancy is evaluated, **Then** the skeleton is removed per US-001.
- **Given** Reality and Fantasy homes overlap with no pocket, **When** occupancy is evaluated, **Then** the skeleton is still banned.

## Notes

Do not retune combat. Do not invent a Fantasy-only skeleton buff. US-001 T007 remains the despawn implementation; this task is the allow/deny predicate.
