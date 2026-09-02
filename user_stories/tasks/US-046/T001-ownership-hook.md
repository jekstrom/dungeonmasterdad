# T001: Ownership hook (`tshirt_in_december`)

**Story**: US-046  
**Status**: Todo  
**Depends on**: US-035 node id if wired  
**Owner**: Gameplay

## Goal

Host tracks boolean ownership for `tshirt_in_december`. Harness/debug can force-own. Optional: sync from Skill Tree owned chrome when US-034/035 click-to-own exists (still no currency).

## Requirements

- FR-001, FR-003, FR-006, MR-002

## Acceptance

- **Given** force-own, **When** queried on host, **Then** `tshirt_in_december` is owned.
- **Given** not owned, **When** queried, **Then** false.
