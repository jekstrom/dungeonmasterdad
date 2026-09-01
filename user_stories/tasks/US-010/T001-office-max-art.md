# T001: Office Max art (live + ruined)

**Story**: US-010  
**Status**: Todo  
**Owner**: Art  
**Depends on**: none  
**Parallel**: with T002

## Goal

Ship / confirm the Office Max **live building**, **ruined** destroyed building, and **build icons**. Ruined uses the same footprint family as other ruined buildings (US-011 rubble). Optional staple-box prop is skipped if interact feedback is clear without it.

## Files

- `sprites/office_max.png` — exists (128×128); match `sprites/smoke_factory.png` footprint / 3/4
- `sprites/office_max_ruined.png` (or equivalent name) — **new**; 128×128, same footprint as live Office Max; match other ruined buildings
- `sprites/office_max_icon.png` / `office_max_icon_pressed.png` — exist (32×32)
- Optional staple box (32×32) — skip unless restock needs a world prop

## Requirements

- Required New Art Assets table in US-010
- Live: big-box office supply look.
- Ruined: readable destroyed store; same cell footprint so debris does not shift y-sort.
- Do not invent a second building size. Do not block T002 if only the ruin sheet is still landing — Gameplay can placeholder until ruin art ships, but ruin art is required before story sign-off play.

## Acceptance

- **Given** the placement HUD, **When** Office Max is selected, **Then** the build icon pair is readable (normal + pressed).
- **Given** an enabled Office Max, **When** a peer looks, **Then** they see the live `office_max` art.
- **Given** Office Max is destroyed, **When** a peer looks, **Then** they see the ruined art at the same footprint, not the live building and not a missing texture.

## Notes

Gameplay swaps to ruined on 0 HP in T005. Do not implement restock VFX that changes magazine or iron rules.
