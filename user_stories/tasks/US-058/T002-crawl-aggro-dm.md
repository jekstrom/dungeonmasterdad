# T002: Pre-exit goblins hunt the DM

**Story**: US-058  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay

## Goal

Until the first successful dungeon exit, goblins MUST use DM aggro (`AggroFaction.DM` or equivalent): acquire the DM in range, path (US-056), melee. They MUST NOT treat the DM as an ally during the crawl.

Dungeon-spawned goblins should spawn already on that faction (do not wait for a global flag if the DM has not exited).

## Files

- `monsters/goblin.tscn` / `monsters/goblin.gd` / `monsters/enemy.gd` (`aggro_faction`)
- Spawn populator / scene builder if faction is set at instantiate

## Requirements

- FR-003, AC2

## Acceptance

- **Given** the DM has not exited and a dungeon goblin is in range, **When** aggro runs on the host, **Then** the goblin’s target is the DM and it can damage him.
- **Given** the same pre-exit goblin, **When** a Paper Pusher is in the overworld, **Then** the goblin does not leave the dungeon to hunt that PP.
