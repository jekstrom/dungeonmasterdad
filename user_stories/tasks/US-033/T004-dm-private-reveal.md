# T004: DM private reveal

**Story**: US-033  
**Status**: Done  
**Depends on**: T002  
**Parallel**: with T003  
**Owner (after sign)**: Gameplay / Systems

## Goal

Host maintains **`dm_reveal`** with the same visit-radius rule for the DM only. Isolated from `pp_shared_reveal`. Replicate only to the DM client.

## Files

- Same fog owner as T003 (separate set)
- DM mini-map data source

## Requirements

- FR-003, FR-005, FR-008, AC4, AC5, MR-002

## Acceptance

- **Given** the DM explores cells, **When** a PP map is checked, **Then** those cells stay fogged on the PP map.
- **Given** PP shared reveals, **When** the DM map is checked, **Then** those cells stay fogged until the DM’s own radius covers them.
