# T001: Ownership hook (`crib_death`)

**Story**: US-041  
**Status**: Todo  
**Depends on**: US-034 node id if wired  
**Owner**: Gameplay

## Goal

Host tracks boolean ownership for `crib_death`. Harness/debug can force-own. Optional: sync from Skill Tree owned chrome when US-034/035 click-to-own exists (still no currency).

## Requirements

- FR-001, FR-003, FR-006, MR-002

## Acceptance

- **Given** force-own, **When** queried on host, **Then** `crib_death` is owned.
- **Given** not owned, **When** queried, **Then** false.
