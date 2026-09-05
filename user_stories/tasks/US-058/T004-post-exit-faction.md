# T004: Post-exit goblins ignore the DM

**Story**: US-058  
**Status**: Todo  
**Depends on**: T002, T003  
**Owner**: Gameplay

## Goal

After first exit, **every** living goblin and every goblin summoned later MUST aggro Paper Pushers and may raid buildings (US-011). They MUST NOT acquire the DM.

Flip leftover dungeon goblins on the exit event; set the faction on new summons at spawn.

## Files

- `monsters/enemy.gd` / goblin scene
- Exit handler (same as T003)
- `monsters/states/enemy_state_aggro.gd` (raid still goblin-only)

## Requirements

- FR-005, FR-006, AC5, AC6

## Acceptance

- **Given** the DM has exited and stands next to a goblin, **When** aggro runs, **Then** the goblin does not target the DM.
- **Given** a Paper Pusher or raidable factory in range, **When** that goblin has no higher-priority PP, **Then** it chases the PP or raids the building per US-011.
