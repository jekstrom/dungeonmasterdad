# T006: Factory production interval in the pocket

**Story**: US-017  
**Status**: Todo  
**Depends on**: T005  
**Parallel**: with T005

## Goal

If a factory's **origin** lies in the live blizzard pocket, its production **interval is 2×**. Do **not** reset progress to 0.

## Files

- `buildings/buildables/smoke_factory.gd`
- `buildings/buildables/paper_factory.gd`
- `buildings/building.gd` if the interval lives on the base

## Requirements

- FR-005, AC7, edge: 90% complete
- Only factories whose origin is inside the pocket. Do not slow every factory on the map.
- Remaining time scales when slow starts (e.g. 10% left at 1× becomes 20% left at 2×), not a restart.
- Occupancy does not destroy the factory. Production continues at the slowed rate until the pocket ends, then interval returns to baseline in the same tick as pocket removal (FR-008).
- Goblin/knightling/gremlin movement is not slowed here.

## Acceptance

- **Given** a smoke or paper factory whose origin is in the pocket, **When** a production interval runs, **Then** it takes ~2× as long.
- **Given** a factory 90% complete when the pocket appears, **When** slow starts, **Then** remaining progress is scaled, not reset to 0.
- **Given** a factory outside the pocket, **When** blizzard is live, **Then** its interval is unchanged.

## Notes

Do not implement US-011 goblin raids. Overlay is T007.
