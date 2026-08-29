# T001: Trigger once at 50% HP

**Story**: US-029  
**Status**: Todo  
**Depends on**: US-017 T003  
**Parallel**: no

## Goal

Sugar Rush starts **once** when HP first reaches **50%**. It does not re-trigger. A killing blow at 50% dies instead of frenzy.

## Files

- `monsters/baja_boss.gd` HP / die path
- Flag: rush used this match

## Requirements

- FR-001, AC1, AC5, edge: kill at 50%
- Cross from above 50% to ≤50% exactly once.
- If the same hit also reaches 0 HP, die wins.

## Acceptance

- **Given** the boss first drops to 50% HP and is still alive, **When** the host resolves, **Then** Sugar Rush starts.
- **Given** a later hit while below 50%, **When** HP changes, **Then** Sugar Rush does not start again.
- **Given** a hit that crosses 50% and 0, **When** resolved, **Then** the boss dies and does not frenzy.

## Notes

Buff numbers are T002. VFX is T003.
