# T001: Ownership hook (`bemidji_cold`)

**Story**: US-045  
**Status**: Todo  
**Depends on**: US-035 node id if wired  
**Owner**: Gameplay

## Goal

Host tracks boolean ownership for `bemidji_cold`. Harness/debug can force-own. Optional: sync from Skill Tree owned chrome when US-034/035 click-to-own exists (still no currency).

## Requirements

- FR-001, FR-003, FR-006, MR-002

## Acceptance

- **Given** force-own, **When** queried on host, **Then** `bemidji_cold` is owned.
- **Given** not owned, **When** queried, **Then** false.
