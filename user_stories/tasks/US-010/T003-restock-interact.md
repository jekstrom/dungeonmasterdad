# T003: Restock interact

**Story**: US-010  
**Status**: Todo  
**Owner**: Gameplay  
**Depends on**: T002, US-005 T001  
**Parallel**: no

## Goal

Interacting with an **enabled** Office Max in range sets the **interacting** Paper Pusher's staple magazine to **max** (US-005). Instant or short channel (suggested ≤1s). Does **not** consume paper, wood, iron, or smoke.

## Files

- `buildings/buildables/office_max.gd` — interact / use
- `player/player.gd` — `staple_count` / `staple_magazine_max` (already shipped)
- Existing building interact pattern (IRS / factories)

## Requirements

- FR-002, FR-003, FR-004, FR-005, AC1
- Only the interacting player's magazine. Never refill another player's mag from this interact.
- Host-authoritative: client cannot set `staple_count` to max without a successful host restock.
- Partial refill not needed: always fill to max when allowed.
- There is no staple item in inventory; ammo stays on the weapon (US-005).

## Acceptance

- **Given** a Paper Pusher in interact range of an enabled Office Max with a non-full magazine, **When** they restock, **Then** their magazine is set to max.
- **Given** that restock, **When** costs are checked, **Then** no paper/wood/iron/smoke was spent for the refill.
- **Given** player A restocks, **When** player B's magazine is read, **Then** B is unchanged.

## Notes

Out-of-range / already-full / ghost gates are T004. Dying mid-channel is an edge in T004.
