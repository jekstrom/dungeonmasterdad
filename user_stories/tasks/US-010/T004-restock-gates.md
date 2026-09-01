# T004: Restock gates

**Story**: US-010  
**Status**: Todo  
**Owner**: Gameplay  
**Depends on**: T003  
**Parallel**: no

## Goal

Restock does **nothing** when out of range, when the magazine is already full, or when the target is only a ghost/preview. No other full-restock source from this story.

## Files

- Office Max interact from T003
- Optional "already full" feedback (local HUD / audio); no-op is enough

## Requirements

- AC2, AC3, AC4, edge: ghost, dying
- Out of range: magazine unchanged.
- Already full: no-op or "already full" feedback; magazine stays max.
- Ghost/preview: not restockable.
- No alternate full-restock path in this story (no ground staple piles, no inventory reload).
- Dying: if interact completes before death, magazine is full on respawn; if not, stays empty.

## Acceptance

- **Given** the magazine is already full, **When** they restock, **Then** nothing changes (no error required beyond no-op / already-full feedback).
- **Given** the player is not in range of Office Max, **When** they press restock / interact, **Then** the magazine does not change.
- **Given** only a placement ghost, **When** they try to restock, **Then** the magazine does not change.

## Notes

Destroyed building is T005. Uniqueness is T002 / T006.
