# T004: Replicate carry state

**Story**: US-013  
**Status**: Todo  
**Depends on**: T002  
**Owner**: Gameplay

## Goal

All peers see the same carried vs world-dropped state. Two gremlins cannot claim the same item instance.

## Requirements

- MR-001, MR-002, FR-006

## Acceptance

- **Given** two peers, **When** a gremlin picks up and drops, **Then** both see the same ownership of the item.
- **Given** two gremlins and one pile, **When** both try grab, **Then** exactly one succeeds.
