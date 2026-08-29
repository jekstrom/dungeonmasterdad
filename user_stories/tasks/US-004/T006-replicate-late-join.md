# T006: Host-authoritative variants and late join

**Story**: US-004  
**Status**: Todo  
**Depends on**: T003  
**Parallel**: no

## Goal

Tile variant changes originate on the host. Every peer shows the same variant for a given outside tile. A late joiner receives **current** art for every existing outside tile, not only future drift events.

## Files

- Tile-art owner + MultiplayerSynchronizer / snapshot RPC (match US-002 T006 / US-001 T008 / US-024 bounds)
- Do not send dungeon restyles (there are none)

## Requirements

- FR-005, MR-001, MR-002
- Snapshot: kind + variety index + presentation (Neutral / Reality / Fantasy) for each outside tile. Share the US-002 snapshot if it already exists; do not send a second copy of the same cells.
- Dungeon tiles are not restyled by this story and need not be in the snapshot.

## Acceptance

- **Given** a host conversion, **When** peers are in session, **Then** they show the same Fantasy-element variant.
- **Given** a client joins mid-match, **When** they spawn, **Then** they receive current art for every existing outside tile, including already-drifted ones.

## Notes

Do not replicate occupancy here. Pending delays can stay host-only; joiner only needs the current presentation.
