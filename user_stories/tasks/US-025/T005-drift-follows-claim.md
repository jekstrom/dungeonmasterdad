# T005: Drift presentation follows current claim

**Story**: US-025  
**Status**: Todo  
**Depends on**: T001, US-002, US-004  
**Parallel**: no

## Goal

Fix James’s bug: some tiles show Fantasy presentation when they are not inside a Fantasy zone. Presentation MUST follow current claim. Stale linger-until-the-other-drift is out.

## Files

- `scripts/procedural_dungeon/fantasy_tile_drift.gd`
- `scripts/procedural_dungeon/reality_tile_drift.gd`
- `scripts/procedural_dungeon/zone_drift_claim.gd`
- US-023 strips (kind + variety stay; only presentation changes)

## Requirements

- FR-005, AC5
- No Fantasy-element art on a cell that is not Fantasy-claimed.
- No Reality-element art on a cell that is not Reality-claimed.
- Unclaimed outside cells MUST be Neutral.
- On claim **loss**, drop that zone’s art **immediately** (Neutral, or the new claim’s art if already applied). Do not wait for the other zone’s 0.5–8s delay.
- US-002 / US-004 per-tile delay MAY still stagger converting **into** a claimed look after the cell is already claimed.
- Cancel pending drift that would apply the wrong zone after claim change (already in US-002 T002 / US-004 T002); also strip any already-applied mismatched art.
- Dungeon cells stay dungeon catalog (US-023). No collision/walkability/kind change.

## Acceptance

- **Given** an outside tile showing Fantasy art whose center is not Fantasy-claimed, **When** claim is applied, **Then** it is not left on Fantasy presentation.
- **Given** an outside tile showing Reality art whose center is not Reality-claimed, **When** claim is applied, **Then** it is not left on Reality presentation.
- **Given** a cell that loses Fantasy claim and is Reality-claimed, **When** the Fantasy look is stripped, **Then** it does not stay Fantasy until Reality drift happens to fire.

## Notes

Do not add a second tile catalog. Puff VFX is still US-002 T005 / US-004 T005 and must not block the strip.
