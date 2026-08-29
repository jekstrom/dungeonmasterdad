# T009: Replicate home and pockets

**Story**: US-003  
**Status**: Todo  
**Depends on**: T002, T004  
**Parallel**: no

## Goal

Host/server decides Fantasy home rectangle and pocket set. Every peer, including late joiners, observes the same Fantasy home, live pockets, and occupancy. Do **not** replicate a Paper Pusher shove out of Fantasy.

## Files

- Fantasy claim owner + MultiplayerSynchronizer / host RPCs (match US-001 T008 / US-024 map bounds)
- `_globals/signal_bus.gd`
- Overlay refresh on replicated claim (T003)

## Requirements

- MR-001, MR-002
- Late join: send current home rect and full live pocket set (origin/size/remaining duration).
- Clients MUST NOT locally wall or shove Paper Pushers out of Fantasy.

## Acceptance

- **Given** a home rebuild or pocket create/expire on the host, **When** peers are in session, **Then** they show the same claim.
- **Given** a Paper Pusher walks Fantasy on the host, **When** peers simulate, **Then** they see that player inside Fantasy, still alive, not shoved out.
- **Given** a client joins late, **When** they spawn, **Then** they see the current home, current pockets, and the same occupancy as the host.

## Notes

Do not replicate circle radius. Building reject is host-side in T007; skeleton allow/ban uses US-001 T008 replication for removals. T005 displacement is revoked.
