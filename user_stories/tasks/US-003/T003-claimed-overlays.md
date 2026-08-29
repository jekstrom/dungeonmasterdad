# T003: Player-facing overlays on claimed cells

**Story**: US-003  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T002

## Goal

Players can see Fantasy home vs Fantasy pocket on the ground. Overlays are **tileable 128×128 cell washes**, not a circle.

## Files

- `sprites/fantasy_home_overlay.png` — exists (saturated greens/purples, sparkle flecks)
- `sprites/fantasy_pocket_overlay.png` — exists (frost/sparkle border)
- Overlay placer (suggested: under `zones/` or `level/`) that instances the wash on claimed cells
- `zones/scripts/zone.gd` — `draw_rect` / `draw_circle` may remain as occupancy debug; they are not the player-facing look

## Requirements

- Required New Art Assets table in US-003
- Home overlay on home-claimed cells that are not covered by a winning Fantasy pocket.
- Pocket overlay on live pocket cells (distinct from the home wash).
- Do **not** reuse dungeon floor/wall frames as the overlay.
- Same 3/4 camera and south-foot y-sort as `level/floor.tscn`.
- Dungeon cells under Fantasy keep dungeon tiles; overlay may sit on top, but occupancy must not plant outside grass/dirt (US-023, US-004).

## Acceptance

- **Given** a Fantasy home, **When** a peer looks at claimed cells, **Then** they see `fantasy_home_overlay.png`, not a circle.
- **Given** a live pocket, **When** a peer looks at those cells, **Then** they see `fantasy_pocket_overlay.png` distinct from the home wash.
- **Given** a pocket expires, **When** overlays refresh, **Then** pocket art is gone and remaining home art matches the live claim.

## Notes

Art files already exist; this task is placement and replication of what is shown, not new pixels. Blizzard (US-017) may later tint the pocket icy; T003 only needs a readable Fantasy pocket shape.
