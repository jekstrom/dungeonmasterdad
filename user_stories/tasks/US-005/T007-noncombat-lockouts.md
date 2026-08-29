# T007: Existing non-combat lockouts

**Story**: US-005  
**Status**: Todo  
**Depends on**: T002, T005  
**Parallel**: no

## Goal

If the player is **dead**, **building**, or in any current state that already blocks attacks, neither staple fire nor pencil melee occurs.

## Files

- `player/player.gd` / `player/scripts/` state machine (`player_respawn_wait_state.gd` and existing attack-block states)
- Building placement lockout already used for melee

## Requirements

- AC7
- Reuse existing non-combat gates. Do not invent a new global “combat disabled” flag unless the current gates are incomplete.
- Empty-click (T003) also does not play if fire is blocked by these lockouts.

## Acceptance

- **Given** the player is dead, building, or in a state that already blocks attacks, **When** they press fire or melee, **Then** neither attack occurs and the magazine does not change.

## Notes

Chainsaw override is US-022, not this lockout list.
