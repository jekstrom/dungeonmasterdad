# T003: Replicate telegraph and stream

**Story**: US-027  
**Status**: Todo  
**Depends on**: T002  
**Parallel**: no

## Goal

Telegraph start, stream spawn, and hits originate on the host. Peers see the same lane and the same hit outcome. Clients may predict VFX.

## Files

- Existing projectile / combat replication pattern
- Jet state + stream from T001–T002

## Requirements

- FR-005, MR-001, MR-002
- Late join during a stream: show it if still alive, or skip if already gone. Do not invent a hit the host did not apply.

## Acceptance

- **Given** a host Jet, **When** a peer is watching, **Then** they see the telegraph and stream and the same DM hit.
- **Given** a client-only fake fire, **When** the host did not start Jet, **Then** no damage is applied.

## Notes

Do not replicate occupancy. Bubble particles are US-029.
