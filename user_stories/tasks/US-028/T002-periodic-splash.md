# T002: Periodic Baja splash and knockback

**Story**: US-028  
**Status**: Done  
**Depends on**: T001  
**Parallel**: no

## Goal

The live fountain **periodically charges**, then **splashes Baja Blast Mt Dew around its room**. On overlap, the host applies a hit and **knockback**. Environmental, not a boss clip, not Carbonated Jet.

## Files

- Fountain script on `doodads/water_fountain.tscn`
- Splash VFX (room burst). **Not** `monsters/carbonated_jet.tscn`. **Not** a `baja_boss` Freeze Wave state
- DM (and any PP in the dungeon room) knockback on the host

## Requirements

- FR-002, FR-003, AC2, AC3, AC5
- Host timer. Suggested period 6–10s, charge ~1s. Charge MUST be readable before any splash exists (gurgle / swell — not Jet’s thin floor line).
- Splash covers the fountain's **room** (walkable cells of that room, or an equivalent large rect around the fountain).
- Host-authoritative knockback. Do not shove anyone out of Fantasy as occupancy (T011). Knockback is combat displacement, not a zone wall.
- Cancel in-flight charge if the fountain is freed; do not fire a splash from a missing doodad.
- Do not implement the lasting slick here (T003). A one-shot splash VFX is enough.
- Do not share Jet’s projectile scene.

## Acceptance

- **Given** a live fountain, **When** its period elapses, **Then** a charge is visible before the splash exists.
- **Given** the splash fires, **When** it overlaps the DM, **Then** the host applies a hit and knockback.
- **Given** Carbonated Jet, **When** the fountain splashes, **Then** the scenes / VFX are distinct.

## Notes

Dew slick / slide is T003. Replication of the live slick is T004.
