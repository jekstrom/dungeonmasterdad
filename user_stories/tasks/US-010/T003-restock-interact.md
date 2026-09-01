# T003: Restock interact (1 iron → 10 staples)

**Story**: US-010  
**Status**: Todo  
**Owner**: Gameplay  
**Depends on**: T002, US-005 T001  
**Parallel**: no

## Goal

Each successful interact with an **enabled** Office Max in range costs **exactly 1 iron** and grants **10 staples**, or `magazine_max - current` if fewer than 10 slots remain. Instant or short channel (suggested ≤1s). Does **not** consume paper, wood, or smoke. Does **not** fill the whole magazine in one press for a multi-iron `ceil` cost.

## Files

- `buildings/buildables/office_max.gd` — interact / use
- `player/player.gd` — `staple_count` / `staple_magazine_max`
- Player iron inventory / US-007 spend path (host)

## Requirements

- FR-002, FR-003, FR-004, FR-005, AC1
- Per press: spend 1 iron; add `min(10, magazine_max - current)` staples.
- Examples: empty 20-mag → first press 10 staples / 1 iron; second press 10 / 1 iron. Mag at 17/20 → one press grants 3 staples / 1 iron.
- Host spends iron and adds staples atomically. Reject path is T004.
- Only the interacting player's magazine and iron. Never restock another player's mag from this interact.
- No staple item in inventory; ammo stays on the weapon (US-005).
- Placement iron (T002) is separate from this restock spend.

## Acceptance

- **Given** a Paper Pusher in range with a non-full magazine and ≥1 iron, **When** they restock once, **Then** iron drops by exactly 1 and staples rise by `min(10, room_in_mag)`.
- **Given** an empty mag of max 20, **When** they restock twice with enough iron, **Then** the mag is full and 2 iron were spent (not one press for 2 iron).
- **Given** that restock, **When** costs are checked, **Then** no paper/wood/smoke was spent for the refill.
- **Given** player A restocks, **When** player B's magazine and iron are read, **Then** B is unchanged.

## Notes

Not enough iron / out of range / full / ghost are T004.
