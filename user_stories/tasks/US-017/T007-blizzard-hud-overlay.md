# T007: Blizzard HUD and ground overlay

**Story**: US-017  
**Status**: Todo  
**Depends on**: T005  
**Parallel**: with T005

## Goal

Show the spell on the DM HUD and ice on the live pocket. Locked/empty-mana still shows as not castable.

## Files

- `spells/blizzard/blizzard.png` and `blizzard_pressed.png` — exist (32×32)
- `sprites/blizzard_overlay.png` — exists (128 tileable icy wash)
- `gui/dm/dm_hud.gd` / fireball HUD pattern
- Overlay placer (US-003 T003 pocket overlay path) — ice, not grass, on this pocket

## Requirements

- Required New Art Assets table in US-017
- HUD uses `spells/blizzard/blizzard.png` + pressed, not the leftover `sprites/blizzard_hud.png` unless they are duplicates — prefer the `spells/blizzard/` pair James queued.
- Ground overlay sits on the Fantasy pocket cells for the duration and clears on expire.
- Do not reuse dungeon floor frames or grass as the ice.

## Acceptance

- **Given** Blizzard is unlocked, **When** the DM HUD is shown, **Then** they see `spells/blizzard/blizzard.png`.
- **Given** a live blizzard pocket, **When** a peer looks at those cells, **Then** they see `sprites/blizzard_overlay.png`.
- **Given** the pocket expires, **When** overlays refresh, **Then** the ice wash is gone.

## Notes

Occupancy debug draws are not the player-facing ice. Convert puffs and ambient sparkles are other stories.
