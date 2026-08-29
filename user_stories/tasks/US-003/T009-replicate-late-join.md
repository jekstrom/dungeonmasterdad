# T009: Replicate home, pockets, and Paper Pusher displacement

**Story**: US-003  
**Status**: Todo  
**Depends on**: T002, T004, T005  
**Parallel**: no

## Goal

Host/server decides Fantasy home rectangle, pocket set, blocked movement, and Paper Pusher displacement. Every peer, including late joiners, observes the same Fantasy home, live pockets, and occupancy.

## Files

- Fantasy claim owner + MultiplayerSynchronizer / host RPCs (match US-001 T008 / US-024 map bounds)
- `_globals/signal_bus.gd`
- Overlay refresh on replicated claim (T003)
- Client prediction of PP stop/push, reconcile to server position (MR-001)

## Requirements

- FR-009, MR-001, MR-002
- Late join: send current home rect, full live pocket set (origin/size/remaining duration), and current Paper Pusher positions after displacement.
- Do not resurrect a displaced player inside Fantasy.

## Acceptance

- **Given** a home rebuild or pocket create/expire on the host, **When** peers are in session, **Then** they show the same claim.
- **Given** a Paper Pusher is pushed on the host, **When** peers simulate, **Then** they see that player outside Fantasy, still alive.
- **Given** a client joins late, **When** they spawn, **Then** they see the current home, current pockets, and the same occupancy as the host.

## Notes

Do not replicate circle radius. Building reject is host-side in T007; skeleton allow/ban uses US-001 T008 replication for removals.
