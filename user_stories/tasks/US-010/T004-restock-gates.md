# T004: Restock gates

**Story**: US-010  
**Status**: Todo  
**Owner**: Gameplay  
**Depends on**: T003  
**Parallel**: no

## Goal

Restock does **nothing** (no mag change, no iron spend) when out of range, when the magazine is already full, when the target is only a ghost/preview, or when the player **lacks enough iron** for the full `ceil` cost. No other full-restock source from this story.

## Files

- Office Max interact from T003
- Optional feedback: already full / not enough iron (local HUD / audio); reject is enough

## Requirements

- AC2, AC3, AC4, AC5, edge: ghost, dying, ceil bands
- Out of range: magazine and iron unchanged.
- Already full: no-op; no iron spend.
- Not enough iron for full refill to max: reject entire restock; no partial fill.
- Ghost/preview: not restockable.
- No alternate full-restock path in this story.
- Dying: if interact completes before death, mag full + iron spent on respawn; if not, both unchanged.

## Acceptance

- **Given** the magazine is already full, **When** they restock, **Then** nothing changes and no iron is spent.
- **Given** the player is not in range, **When** they press restock / interact, **Then** magazine and iron do not change.
- **Given** not enough iron for `ceil(staples_needed / 10)`, **When** they restock, **Then** the server rejects; magazine and iron are unchanged.
- **Given** only a placement ghost, **When** they try to restock, **Then** magazine and iron do not change.

## Notes

Destroyed building is T005.
