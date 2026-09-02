# T001: Skill point pool and income

**Story**: US-054  
**Status**: Todo  
**Depends on**: Fantasy Level change signals  
**Owner**: Gameplay / Systems

## Goal

Host integer SP balance (start 0). On each host **+1 Fantasy Level**, grant **+1 SP** (Open default). Replicate SP to DM client.

## Requirements

- FR-001, FR-012, MR-002

## Acceptance

- **Given** FL increases by 3, **When** income runs, **Then** SP increases by 3 (unless James overrides income).
- **Given** a peer, **When** SP changes, **Then** DM UI can show the host value.
