# T004: Wire goblin DM summon placement

**Story**: US-055  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay  
**Parallel**: with T002 / T003

## Goal

Ensure a **goblin** DM summon path exists and uses T001. If HUD/ability is missing, add a minimal summon (button + cast id + spawner) that places via T001. Do **not** implement US-011 raid AI here — spawn + existing goblin scene baseline is enough.

## Requirements

- FR-001–FR-005, FR-008, AC3, AC9

## Acceptance

- **Given** the DM triggers goblin summon, **When** it resolves, **Then** the goblin appears near the DM under the same radius/walkable rules as gremlin/knightling.
