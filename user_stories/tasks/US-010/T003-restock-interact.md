# T003: Restock interact (iron cost)

**Story**: US-010  
**Status**: Todo  
**Owner**: Gameplay  
**Depends on**: T002, US-005 T001  
**Parallel**: no

## Goal

Interacting with an **enabled** Office Max in range sets the **interacting** Paper Pusher's staple magazine to **max** when they can pay **1 iron per 10 staples refilled**. Instant or short channel (suggested ≤1s). Does **not** consume paper, wood, or smoke.

## Files

- `buildings/buildables/office_max.gd` — interact / use
- `player/player.gd` — `staple_count` / `staple_magazine_max`
- Player iron inventory / US-007 spend path (host)

## Requirements

- FR-002, FR-003, FR-004, FR-005, AC1
- Staples refilled = `magazine_max - current`. Iron cost = `ceil(staples_refilled / 10)`.
- Examples: 1–10 staples → 1 iron; 11–20 → 2 iron.
- Host spends iron and sets magazine atomically. Reject path is T004.
- Only the interacting player's magazine and iron. Never refill another player's mag from this interact.
- No staple item in inventory; ammo stays on the weapon (US-005).
- Placement iron (T002) is separate from this restock spend.

## Acceptance

- **Given** a Paper Pusher in range with a non-full magazine and enough iron, **When** they restock, **Then** their magazine is max and iron drops by `ceil(staples_refilled / 10)`.
- **Given** that restock, **When** costs are checked, **Then** no paper/wood/smoke was spent for the refill.
- **Given** player A restocks, **When** player B's magazine and iron are read, **Then** B is unchanged.

## Notes

Not enough iron / out of range / full / ghost are T004.
