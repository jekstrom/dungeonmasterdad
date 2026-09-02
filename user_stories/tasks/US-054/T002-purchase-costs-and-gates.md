# T002: Purchase costs and gates

**Story**: US-054  
**Status**: Todo  
**Depends on**: T001; node ids from US-034/035  
**Owner**: Gameplay

## Goal

Host `try_purchase(tree, node)` enforcing: col costs 1/2/3; Row2 FL≥30; Row3 RL≥80; Row1 ungated by FL/RL; ultimate needs ≥1 owned in each row on that tree + ultimate SP cost (default 5); already-owned reject; atomic SP+own.

## Requirements

- FR-002–FR-009, AC1–AC11

## Acceptance

- **Given** each locked rule case in Independent Test, **When** purchase runs on host, **Then** accept/reject matches US-054.
