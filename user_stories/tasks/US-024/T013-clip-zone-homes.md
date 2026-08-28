# T013: Clip Reality and Fantasy homes to the interior

**Story**: US-024  
**Status**: Todo  
**Depends on**: T004  
**Parallel**: with T011

## Goal

Reality and Fantasy home regions (and pockets when those stories land) stay entirely inside the map interior. Growth that would cross a cliff is truncated, not allowed to punch through.

## Files

- `zones/RealityZone.gd`, `zones/scripts/zone.gd`, Fantasy zone equivalent
- Future rectangle homes (US-001 / US-003) — clip helper on map bounds: `intersect_interior(Rect2i) -> Rect2i`
- Playground authored zone positions (`FantasyZone`, `RealityZone`) must be moved/resized to fit the committed interior

## Requirements

- FR-006, AC7
- Occupancy rules stay US-001 / US-003; this task only enforces interior clipping.
- Suggested Reality start: anchored on the **west** interior edge (US-001 assumption).

## Acceptance

- **Given** Reality and Fantasy home regions, **When** they are placed or grown, **Then** every cell they cover is an interior cell; none are cliff or void.
- **Given** a pocket that would extend past a cliff, **When** it is created, **Then** it is truncated to the interior.

## Notes

Homes may overlap each other inside the same interior; occupancy is unchanged. Do not restyle tiles here.
