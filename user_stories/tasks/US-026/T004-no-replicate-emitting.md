# T004: Do not replicate particle emitting

**Story**: US-026  
**Status**: Todo  
**Depends on**: T002, T003  
**Parallel**: no

## Goal

Particle emitting stays **local**. Do not sync GPU/CPU particle `emitting`, seeds, or burst times. Each client plays ambience from the already-replicated claim.

## Files

- Ambient owner from T001–T003
- Zone replication already used by US-001 T008 / US-003 T009 — claim only, not VFX
- Do not add MultiplayerSynchronizer properties for these particles

## Requirements

- FR-004, MR-001, MR-002, AC5
- Host and client may show different burst times in the same cell. That is correct.
- Claim overlays and occupancy still match (existing replication).
- Late join: joiner starts local ambience from the claim snapshot they already receive. No VFX catch-up RPC.

## Acceptance

- **Given** two peers in the same Reality or Fantasy cell, **When** ambience plays, **Then** neither session sends particle-emitting traffic for it.
- **Given** a late joiner, **When** they spawn into claimed ground, **Then** they play local ambience from current claim without a particle snapshot.

## Notes

If a particle node is in a replicated scene, turn off replicating its emitting state. Occupancy is unchanged.
