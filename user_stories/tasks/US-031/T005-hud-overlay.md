# T005: HUD icons and ice overlay

**Story**: US-031  
**Status**: Todo  
**Depends on**: T002  
**Parallel**: no (HUD + FantasyZone overlay)

## Goal

The DM HUD shows Bemidji Blizzard **only when unlocked**, using `spells/blizzard/blizzard.png` / `blizzard_pressed.png`. Live pocket cells show **`sprites/blizzard_overlay.png`**, not grass. Expire clears the ice.

## Files

- `gui/dm/dm_hud.gd` / `dm_hud.tscn` — `blizzard` ColorRect visibility from `DmUnlocks` (`_apply_unlock_visibility`). Button already wired.
- `zones/FantasyZone.gd` — `_blizzard_overlay_texture`, pocket overlay `"blizzard"`.
- HUD art already on disk — do **not** regenerate unless a file is missing. Ground ice **look** (packed rime vs today’s blue wash) and falling flakes are **T008**; this task only needs overlay `"blizzard"` to resolve to `sprites/blizzard_overlay.png` so T007 HUD tests stay green if T008 later replaces that file.
- `test_harness/procedural_dungeon/us017_blizzard_hud_test.tscn` — keep green.

## Requirements

- FR-004, AC7
- Locked: blizzard HUD control **hidden** (same pattern as fireball / knightling).
- Unlocked + 0 mana: icon **visible**; confirm still refuses (T001).
- Overlay tiles the pocket cells for the duration; not occupancy debug draws; not dungeon floor frames.
- Expire: overlay gone when pocket is gone.

## Acceptance

- **Given** locked, **When** the DM HUD is on, **Then** the blizzard button parent is not visible.
- **Given** unlock, **When** HUD is shown, **Then** `spells/blizzard/blizzard.png` is the button texture.
- **Given** a live blizzard pocket, **When** overlay is queried for those cells, **Then** it is `sprites/blizzard_overlay.png`.
- **Given** expire, **When** overlays refresh, **Then** the ice wash is gone.

## Notes

Do not use leftover `sprites/blizzard_hud.png` if the HUD already uses `spells/blizzard/`. Ambient Fantasy sparkles are US-026. Falling blizzard flakes are T008.
