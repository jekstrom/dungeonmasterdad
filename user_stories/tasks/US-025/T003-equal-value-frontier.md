# T003: Equal-value stable frontier

**Story**: US-025  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T002

## Goal

When zone values are **equal**, neither home advances into the other. The frontier stays put. Confirm: older stories implied something else, and this task replaces that.

## Files

- Same resolve as T002 (`zone.gd` / claim helpers)
- `scripts/procedural_dungeon/zone_drift_claim.gd` — today: overlapping homes + equal levels → `CLAIM_NONE` while **both rects still cover the cell** (ties keep current art)

## Requirements

- FR-003, AC3
- **What the stories already said (replaced for home geometry):**
  - US-001 FR-010 / US-003 FR-010: homes **may overlap**; Fantasy exclusion and Reality skeleton ban both apply on those cells.
  - US-002 FR-007 / US-004 T004: overlapping homes; higher covering level wins **claim**; **ties keep current art** until a winner exists.
- **This story:** equal value is a **stable frontier**, not dual-cover with frozen art. Neither home grows into cells the other currently occupies.
- If they already overlap at equal value: both retract from the intersection. Tile-snap the split. Odd-width contested band: leftover middle cell is unclaimed by either home. Dual-claim is not allowed.
- Adjacent (no shared cell) is the success state.
- Paper Pusher exclusion named in that old FR-010 was later **revoked** (US-003 T011). This task is home geometry only; do not shove players when the frontier moves.

## Acceptance

- **Given** equal zone values and a home that would grow into the other, **When** rebuild runs, **Then** that growth is clipped and no new cell is dual-covered.
- **Given** equal zone values and an existing overlap, **When** resolve runs, **Then** the intersection is gone; at most one leftover unclaimed frontier cell remains if the band width is odd.
- **Given** equal zone values and homes that already abut, **When** time passes, **Then** neither rect advances into the other.

## Notes

Do not keep “ties keep current art” as a claim rule for overlapping homes; those homes must not overlap. Drift presentation is T005. Do not displace Paper Pushers (US-003 T011).
