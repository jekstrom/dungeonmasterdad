# T001: Office Max art

**Story**: US-010  
**Status**: Todo  
**Owner**: Art  
**Depends on**: none  
**Parallel**: with T002

## Goal

Ship / confirm the Office Max **building** and **build icons** so Gameplay can wire them. Optional staple-box prop is skipped if interact feedback is clear without it.

## Files

- `sprites/office_max.png` — exists (128×128); match `sprites/smoke_factory.png` footprint / 3/4
- `sprites/office_max_icon.png` / `office_max_icon_pressed.png` — exist (32×32); match `sprites/build_smoke_factory_icon.png`
- Optional staple box (32×32) — skip unless restock needs a world prop

## Requirements

- Required New Art Assets table in US-010
- Big-box office supply look; same cell footprint as dungeon floors / smoke factory.
- Do not invent a second building size. Do not block T002 if only polish remains on an already-present sheet.

## Acceptance

- **Given** the placement HUD, **When** Office Max is selected, **Then** the build icon pair is readable (normal + pressed).
- **Given** an enabled Office Max in world, **When** a peer looks at it, **Then** they see `office_max.png`, not a stretched factory or dungeon floor.

## Notes

Gameplay wires these in T002. Do not implement restock VFX that changes magazine rules.
