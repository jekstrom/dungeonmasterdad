# T005: Zones and buildings on revealed cells

**Story**: US-033  
**Status**: Done  
**Depends on**: T003 or T004  
**Parallel**: after either reveal path works for that HUD  
**Owner (after sign)**: Gameplay

## Goal

On revealed cells, paint Reality / Fantasy claim washes (home ∪ pockets, US-025) and building markers. Unrevealed cells stay fogged (no wash, no building icon).

## Files

- `ZoneDriftClaim` / zone home signals
- `building_root` / building cell lookup
- Mini-map paint pass

## Requirements

- FR-006, AC6, AC9
- Colored rects OK until T008 art.

## Acceptance

- **Given** a revealed Reality-claimed cell, **When** painted, **Then** it shows a Reality wash (not Fantasy).
- **Given** a building on a revealed cell, **When** painted, **Then** a building marker appears; on a fogged cell it does not.

## Notes

Trees, mines, and dungeon wall silhouette are **T010** (scope add after this task Done).
