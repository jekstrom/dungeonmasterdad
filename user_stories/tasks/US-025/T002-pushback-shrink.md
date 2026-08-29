# T002: Higher value pushback shrink

**Story**: US-025  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T003

## Goal

When the homes would meet or overlap and zone values **differ**, the higher value keeps the contested cells and the **weaker home rect shrinks** so it no longer covers them.

## Files

- `zones/scripts/zone.gd` — home rebuild after level / clip
- `zones/RealityZone.gd`, `zones/FantasyZone.gd`
- `_globals/` Reality Level / Fantasy Level (same values `zone_drift_claim.gd` already reads)
- Suggested: one host resolve after either home rebuild, not a per-physics-frame scan of the map

## Requirements

- FR-002, AC2
- Contested cells = intersection of the two home rects (center-point).
- Winner’s home rect does not give up those cells. Loser’s rect shrinks.
- Keep the loser’s spawn-side anchor: Reality (west) shrinks from the east; Fantasy (east) shrinks from the west. If the overlap is vertical, shrink the overlapping north or south edge too; do not move the west/east anchor.
- Resolve once per home rebuild / level change. Do not scan every outside tile every physics frame.
- Entire-map coverage still only shrinks/clips; do **not** fire game over (FR-007).

## Acceptance

- **Given** overlapping homes and Reality Level > Fantasy Level, **When** resolve runs, **Then** every contested cell is inside the Reality home and outside the Fantasy home.
- **Given** overlapping homes and Fantasy Level > Reality Level, **When** resolve runs, **Then** every contested cell is inside the Fantasy home and outside the Reality home.
- **Given** a weaker home that grew into the stronger, **When** resolve runs, **Then** the weaker rect is smaller on the meeting face and still west- or east-anchored.

## Notes

Equal values are T003. Pockets do not shrink homes (T004). Existing buildings are not auto-destroyed if the weaker home pulls off them.
