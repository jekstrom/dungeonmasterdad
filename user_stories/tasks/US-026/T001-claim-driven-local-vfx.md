# T001: Claim-driven local ambience

**Story**: US-026  
**Status**: Todo  
**Depends on**: US-001 T001, US-003 T001  
**Parallel**: no

## Goal

A local VFX owner knows which nearby cells are Reality-claimed vs Fantasy-claimed and can spawn ambience there. Unclaimed cells are quiet. Occupancy is not touched. Do **not** scan every map cell every physics frame.

## Files

- Live Reality / Fantasy claim APIs (`zones/scripts/reality_claim.gd`, `fantasy_claim.gd`, `scripts/procedural_dungeon/zone_drift_claim.gd`)
- Suggested new local owner: `scripts/procedural_dungeon/zone_ambient_vfx.gd` (or under `zones/`)
- Listen to claim-change signals (`_globals/signal_bus.gd`); optional visible/nearby set from camera

## Requirements

- FR-003, FR-005, FR-006, AC3, AC6
- Inclusion is center-point, same as drift.
- Pockets override homes; US-025 exclusive homes apply.
- Rebuild the ambient set on claim/map change and/or camera move, not a full-map physics-frame scan.
- Missing VFX must not fail claim, drift, or occupancy.
- Do not implement dust/sparkle look here (T002 / T003).
- Do not replicate emitting here (T004).

## Acceptance

- **Given** a Reality-claimed cell in the nearby/visible set, **When** the owner is queried, **Then** it is a Reality-ambience candidate.
- **Given** a Fantasy-claimed cell in that set, **When** queried, **Then** it is a Fantasy-ambience candidate.
- **Given** an unclaimed cell, **When** queried, **Then** it is not an ambience candidate.
- **Given** claim change, **When** the set rebuilds, **Then** it did not require scanning every map cell that physics frame.

## Notes

Dungeon-claimed cells may be candidates (do not restyle the floor). Convert puffs are not this owner.
