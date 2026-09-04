# T001: Skill point pool and income

**Story**: US-054  
**Status**: Todo  
**Depends on**: Fantasy Level change signals  
**Owner**: Gameplay / Systems

## Goal

Host integer SP balance (**start 0**). On each host **+10 Fantasy Level**, grant **+1 SP**. A jump of N FL grants N/10 SP. **Reality Level MUST NOT grant SP.** One shared pool for both trees. Replicate SP to the DM client. Persist SP for the match through DM death/respawn.

## Requirements

- FR-001, FR-012, FR-013, FR-014, FR-018, FR-024, MR-002
- AC1, AC2, AC3

## Acceptance

- **Given** a new match, **When** SP initializes, **Then** it is 0.
- **Given** FL increases by 30, **When** income runs, **Then** SP increases by 3.
- **Given** Reality Level changes, **When** income would run, **Then** SP is unchanged.
- **Given** a peer, **When** SP changes, **Then** the DM UI can show the host value.
- **Given** DM death/respawn, **When** the match continues, **Then** remaining SP is unchanged.
