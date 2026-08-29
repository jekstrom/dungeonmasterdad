# T002: 10s speed and fragility buff

**Story**: US-029  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T003

## Goal

For **10s**, move speed and attack speed are up, and damage taken is **+15%**. Then baseline. Not a forever second phase.

## Files

- `monsters/baja_boss.gd` move / attack cooldown / incoming damage
- Configurable duration (default 10s) and speed multipliers (suggested 1.3–1.5×)

## Requirements

- FR-002, FR-003, FR-004, AC2, AC3, AC5
- Timed buff only. After 10s, multipliers end even if HP is still low.
- Jet may still fire during the rush. The US-028 fountain is not a boss clip.

## Acceptance

- **Given** Sugar Rush is active, **When** the boss moves and attacks, **Then** those speeds are increased.
- **Given** Sugar Rush is active, **When** it takes a hit, **Then** damage taken is +15%.
- **Given** 10s elapsed, **When** the buff ends, **Then** speeds and damage taken are baseline.

## Notes

Vibrate/bubbles are T003. Host replicate is T004.
