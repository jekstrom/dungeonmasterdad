# T001: Ownership hook (`stoke`)

**Story**: US-048  
**Status**: Todo  
**Depends on**: US-035 node id if wired  
**Owner**: Gameplay

## Goal

Host tracks boolean ownership for `stoke`. Harness/debug can force-own. Optional: sync from Skill Tree owned chrome when US-034/035 click-to-own exists (still no currency).

## Requirements

- FR-001, FR-003, FR-006, MR-002

## Acceptance

- **Given** force-own, **When** queried on host, **Then** `stoke` is owned.
- **Given** not owned, **When** queried, **Then** false.
