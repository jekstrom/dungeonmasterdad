# T002: Wire gremlin DM summon placement

**Story**: US-055  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay  
**Parallel**: with T003 / T004

## Goal

`MultiplayerSpawner.spawn_gremlin` (or equivalent) sets position from T001 before/at add_child. Fail closed without mana spend when picker fails. Does not change US-013 AI.

## Requirements

- FR-001–FR-005, AC1, AC7, AC9

## Acceptance

- **Given** DM summons gremlin away from origin, **When** it appears, **Then** it is near the DM in-band — not default/origin placement.
