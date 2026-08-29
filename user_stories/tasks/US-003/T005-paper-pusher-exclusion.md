# T005: Paper Pusher exclusion

**Story**: US-003  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T006

## Goal

Paper Pushers cannot enter Fantasy-claimed space. If they are already inside (home grew, pocket appeared, spawn glitch, knockback), the **host** pushes them to the nearest walkable cell that is not Fantasy-claimed (or a Reality spawn if none exists). They stay alive.

## Files

- Player movement / physics (`player/`)
- Fantasy claim API from T001
- Reality spawn strip (US-001 / US-024 west spawn) as fallback
- Host occupancy pass each physics update

## Requirements

- FR-005, FR-009, FR-010, AC1, AC2, AC6
- Stop at the boundary when walking in.
- Displacement is host-authoritative, lands on walkable non-Fantasy, does not kill by itself.
- Tight corridor / no legal cell: Reality spawn point (US-001).
- Several Paper Pushers under a new pocket: each displaced independently in the same tick; no two need the same cell.
- Homes overlap with no pocket: Fantasy exclusion still wins for players (FR-010).

## Acceptance

- **Given** a Paper Pusher outside Fantasy-claimed area, **When** they try to move into it, **Then** they stop at the boundary.
- **Given** a Paper Pusher already inside Fantasy, **When** the next physics update runs on the server, **Then** they are pushed to the nearest non-Fantasy walkable (or Reality spawn) and remain alive.
- **Given** Fantasy does not claim a walkable overworld cell, **When** a Paper Pusher moves there, **Then** this story does not block them.

## Notes

Do not define combat reach (US-005). Do not apply blizzard slow (US-017). DM occupancy is T006.
