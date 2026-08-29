# T003: Empty magazine feedback

**Story**: US-005  
**Status**: Todo  
**Depends on**: T002  
**Parallel**: no

## Goal

When the magazine is empty, primary fire creates **no projectile** and plays empty-click / jam feedback.

## Files

- `player/player.gd` primary-fire path from T002
- Audio / small HUD jam cue (match existing click-style SFX if one exists; do not block on new audio)

## Requirements

- FR-003, AC2
- Magazine stays 0. No projectile instance.
- Feedback is local to the owning client at minimum.

## Acceptance

- **Given** the magazine is empty, **When** they press primary fire, **Then** no projectile is created and empty-click / jam feedback plays.
- **Given** empty fire, **When** the server magazine is inspected, **Then** it is still 0.

## Notes

Melee still works when empty (T005). Do not restock (US-010).
