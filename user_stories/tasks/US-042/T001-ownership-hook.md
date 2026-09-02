# T001: Ownership hook (`challenge_rating`)

**Story**: US-042  
**Status**: Todo  
**Depends on**: US-034 node id if wired  
**Owner**: Gameplay

## Goal

Host tracks boolean ownership for `challenge_rating`. Harness/debug can force-own. Optional: sync from Skill Tree owned chrome when US-034/035 click-to-own exists (still no currency).

## Requirements

- FR-001, FR-003, FR-006, MR-002

## Acceptance

- **Given** force-own, **When** queried on host, **Then** `challenge_rating` is owned.
- **Given** not owned, **When** queried, **Then** false.
