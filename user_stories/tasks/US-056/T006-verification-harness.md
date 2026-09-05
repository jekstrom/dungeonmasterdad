# T006: Verification harness

**Story**: US-056  
**Status**: Done  
**Depends on**: T003–T005  
**Owner**: QA / Gameplay

## Goal

Headless Node+.tscn asserts: path around a wall, empty path when sealed, LOS skip (no search), per-frame search cap with many requesters, occupancy dirty after a solid appears, gremlin inland cost still walkable-only, dungeon-to-overworld path through the exit door. Do not use generation `PathValidator` as the runtime AI under test.

## Requirements

- AC1, AC2, AC7, AC8, AC9, AC10, AC14, FR-009, FR-014

## Acceptance

- **Given** the harness, **When** it runs, **Then** around-wall, no-path, LOS skip, budget, and dirty-occupancy asserts pass without the editor.
