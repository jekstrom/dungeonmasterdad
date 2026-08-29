# T008: Replicate home, pockets, and skeleton removals

**Story**: US-001  
**Status**: Todo  
**Depends on**: T002, T004, T007  
**Parallel**: no

## Goal

Host/server decides home rectangle, pocket set, building placement success/failure, and skeleton removal. Every peer, including late joiners, observes the same Reality home, live pockets, buildings, and living skeletons.

## Files

- Reality claim owner + MultiplayerSynchronizer / host RPCs (match how US-024 map bounds replicate)
- `_globals/signal_bus.gd`
- Overlay refresh on replicated claim (T003)

## Requirements

- FR-009, MR-001, MR-002
- Late join: send current home rect, full live pocket set (origin/size/remaining duration), and do not resurrect host-despawned skeletons.

## Acceptance

- **Given** a home rebuild or pocket create/expire on the host, **When** peers are in session, **Then** they show the same claim.
- **Given** a skeleton removal on the host, **When** peers simulate, **Then** that skeleton is gone for everyone.
- **Given** a client joins late, **When** they spawn, **Then** they see the current home, current pockets, and the same living skeleton set as the host.

## Notes

Do not replicate circle radius. Building placement reject is already host-side in T006; this task makes the world state match.
