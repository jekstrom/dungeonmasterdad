# T006: Player markers

**Story**: US-033  
**Status**: Todo  
**Depends on**: T003, T004  
**Parallel**: with T005  
**Owner (after sign)**: Gameplay

## Goal

Draw player pips per Open defaults: PP map shows all living PPs always; DM pip only if DM cell ∈ `pp_shared_reveal`. DM map shows DM always; each PP only if that PP cell ∈ `dm_reveal`. No monsters. Dead = hidden until respawn.

## Files

- `PlayerManager` / `DmManager` positions → cell
- Mini-map marker layer

## Requirements

- FR-007, AC7, AC8, MR-003

## Acceptance

- **Given** two living PPs, **When** either views the PP map, **Then** both pips show even in fog.
- **Given** the DM is outside PP reveal, **When** PP maps paint, **Then** no DM pip; when a PP radius covers the DM, the pip appears.
