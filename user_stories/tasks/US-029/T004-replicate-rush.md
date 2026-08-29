# T004: Replicate Sugar Rush buff

**Story**: US-029  
**Status**: Todo  
**Depends on**: T002  
**Parallel**: no

## Goal

Trigger, remaining time, multipliers, and end are host-authoritative. Late join during the frenzy sees the buff.

## Files

- Boss combat replication / MultiplayerSynchronizer on a rush-active + remaining-time field

## Requirements

- FR-006, MR-001, MR-002
- Peers agree whether rush is active. Particles may be local.

## Acceptance

- **Given** the host starts or ends Sugar Rush, **When** peers are in session, **Then** they show the same buff window.
- **Given** a client joins mid-rush, **When** they spawn, **Then** they see the boss in Sugar Rush for the remaining time.

## Notes

Do not replicate Jet or Freeze Wave here.
