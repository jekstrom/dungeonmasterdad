# T002: Pickup, carry, drop

**Story**: US-013  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay

## Goal

Host-authoritative: empty gremlin acquires one world resource (AC-1 types), carries at most one, drops after configurable delay (suggested 2s–6s) or on damage policy; death always drops same identity/qty. No building destroy, no lethal execute.

## Files

- Gremlin AI / interact with item pickup pool
- World pickup APIs

## Requirements

- FR-001–FR-006, AC1–AC6

## Acceptance

- **Given** a wood pile and a gremlin, **When** it completes a cycle, **Then** the pile moves and is reclaimable; quantity preserved; no delete.
