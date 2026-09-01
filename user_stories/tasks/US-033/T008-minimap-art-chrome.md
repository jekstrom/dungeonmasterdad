# T008: Mini-map art chrome and pips

**Story**: US-033  
**Status**: Todo  
**Depends on**: T001 (chrome); T005/T006/T010 for final pip pass  
**Parallel**: with Gameplay after T001  
**Owner (after sign)**: Art

## Goal

Ship mini-map frame chrome, fog/zone modulate guidance, dungeon wall-tint guidance, and small PP / DM / building / **tree** / **mine** pips per story art table. Gameplay may keep rect placeholders until these land.

## Files

- `sprites/` or `gui/minimap/` assets
- Wire into widget themes / textures

## Requirements

- Story **Required New Art Assets** table
- FR-010 (missing art must not soft-lock)

## Acceptance

- **Given** art imported, **When** both HUDs show the mini-map, **Then** chrome and pips replace programmer placeholders without changing reveal rules.
