# T001: Ownership hook (`blind_one_legged_monkeys`)

**Story**: US-040  
**Status**: Todo  
**Depends on**: US-034 node id if wired  
**Owner**: Gameplay

## Goal

Host tracks boolean ownership for `blind_one_legged_monkeys`. Harness/debug can force-own. Optional: sync from Skill Tree owned chrome when US-034/035 click-to-own exists (still no currency).

## Requirements

- FR-001, FR-003, FR-006, MR-002

## Acceptance

- **Given** force-own, **When** queried on host, **Then** `blind_one_legged_monkeys` is owned.
- **Given** not owned, **When** queried, **Then** false.
