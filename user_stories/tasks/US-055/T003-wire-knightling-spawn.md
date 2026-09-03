# T003: Wire knightling DM summon placement

**Story**: US-055  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay  
**Parallel**: with T002 / T004

## Goal

Replace world-origin `randi() % 50` knight placement with T001. Each Chain Lightning knightling (US-038) rolls independently. Fail closed per unit / cast per Open defaults (suggested: if picker fails for a unit, skip that unit; if all fail, refund/don’t charge).

## Requirements

- FR-001–FR-005, FR-007, AC2, AC8, AC9

## Acceptance

- **Given** a knightling summon, **When** it spawns, **Then** position is near-DM in-band, not near (0,0).
- **Given** Chain Lightning multi-spawn, **When** three spawn, **Then** each used the picker.
