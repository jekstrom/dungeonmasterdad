# T002: Effect — Dad Reflexes

**Story**: US-052  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay

## Goal

While `dad_reflexes` is owned, apply: **1.5× DM movement speed** on normal locomotion.

Hook points:
- DM walk / analog move speed (host-authoritative)
- Ownership query `dad_reflexes`

MUST NOT add:
- dash input or action
- dash cooldown
- burst displacement
- i-frames

Dad tab effect text for this node MUST say the DM moves 1.5× faster (not “Gain dash ability”).

## Requirements

- FR-002, FR-003, FR-005, FR-006, AC1, AC2, AC4

## Acceptance

- **Given** owned, **When** the DM moves, **Then** speed is 1.5× a not-owned control under the same input.
- **Given** not owned, **When** the same scenario runs, **Then** baseline locomotion holds and no dash exists.
