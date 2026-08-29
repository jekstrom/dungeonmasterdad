# T002: Wave and knockback

**Story**: US-028  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: no

## Goal

Boss sends a Baja **wave forward**. On hit, host applies hit + **knockback**. Not a piercing syrup stream.

## Files

- New wave projectile (wide), not the US-027 jet stream
- DM (and any PP in dungeon) knockback on the host

## Requirements

- FR-001, FR-002, AC2
- Forward from boss facing. Host-authoritative knockback.
- Do not shove anyone out of Fantasy as occupancy (T011). Knockback is combat displacement, not a zone wall.

## Acceptance

- **Given** the telegraph completes, **When** the wave fires, **Then** it travels forward as a wide Baja wave.
- **Given** the wave overlaps the DM, **When** the host resolves, **Then** the DM is hit and knocked back.

## Notes

Wall → ice sheet is T003. Do not implement Jet here.
