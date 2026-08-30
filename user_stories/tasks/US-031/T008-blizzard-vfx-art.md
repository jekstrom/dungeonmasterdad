# T008: Ground ice and falling snow / icicles

**Story**: US-031  
**Status**: Todo  
**Depends on**: T002  
**Parallel**: with T003–T005

## Goal

A live Bemidji Blizzard pocket **reads as a storm**: **ice on the ground** (tileable floor wash) plus **falling snowflakes and icicles** in the air over that rect only. Expire clears both. Cosmetic; no extra slow, collision, or occupancy.

## Files

- `sprites/blizzard_overlay.png` — today a **blue sparkle wash** (128×128). Replace or add a **ground ice** sheet: same **128×128**, **tileable**, 3/4 floor cell, rime / packed ice / frost, **not** grass, **not** `fantasy_sparkle.png`. Isolated, no divider lines. If you keep the filename, `FantasyZone` already loads it for overlay `"blizzard"` (T005). Prefer keeping that path so T005 stays green.
- New falling art (generate; do not reuse convert puffs or US-026 sparkles):
  - `spells/blizzard/snowflake.png` — small flake strip, suggested **16×16** cells (or 32×32), 3–6 frames, transparent bg.
  - `spells/blizzard/icicle.png` — falling spike strip, same cell size, 3–6 frames, transparent bg.
- New local VFX owner, e.g. `spells/blizzard/blizzard_fall_vfx.gd` (+ `.tscn`) with `CPUParticles2D` or `AnimatedSprite2D` pops, **or** a method on `FantasyZone` next to pocket overlay. Emission AABB = the live blizzard **world rect**(s). `emitting` follows pocket lifetime.
- `zones/FantasyZone.gd` — on `spawn_pocket(..., "blizzard")` start fall VFX; on `fantasy_pocket_expired` / map clear stop and free. Multiple live blizzards: one emitter per pocket id.
- `test_harness/procedural_dungeon/us031_blizzard_vfx_test.gd` (+ `.tscn`) — after a legal cast: ground overlay is the ice texture; a fall VFX node exists over the rect; after expire both are gone. Do not assert particle RNG / frame index.

## Requirements

- FR-004, AC7; story Required New Art Assets (ground ice + fall strips)
- **Ground**: one seamless 128×128 ice tile covering every pocket cell. Same y-sort / z as today’s pocket overlay (under actors). Walkable; no new collision.
- **Fall**: snowflakes **and** icicles, downward, only **inside** the pocket AABB (clip or emit-rect). Density readable in 8s, not a white-out, not US-026 infrequent sparkles.
- **Local only** (same rule as US-026): do **not** replicate `emitting`, particle seeds, or sprite frame. Peers already share pocket geometry (T006); each client plays its own fall.
- Expire / clip-to-empty: stop emit the same tick the overlay is cleared. Late join (T006): joiner **starts** local fall from the replicated live rect; do not wait for a second `spell_cast`.
- Do **not** use `sprites/fantasy_sparkle.png`, `sprites/sparks.png`, `fantasy_drift_puff.png`, or Dew-slick bubbles as the blizzard.
- HUD icons stay T005 (`spells/blizzard/blizzard.png`). This task is **world** VFX.

## Acceptance

- **Given** a live blizzard pocket, **When** a peer looks at those cells, **Then** the ground is the ice tile (`blizzard_overlay.png` or the new ice sheet wired to overlay `"blizzard"`), not grass or dungeon floor.
- **Given** that pocket, **When** a second or two pass, **Then** snowflakes and icicles fall inside the rect and do not spawn as a map-wide storm.
- **Given** the pocket expires, **When** overlays and VFX refresh, **Then** ice tiles and falling sprites are gone.
- **Given** two peers, **When** a blizzard is live, **Then** both see ice on the same cells; flake timing need not match.

## Notes

Do not change PP slow (T003) or factory interval (T004). Do not regenerate HUD icons unless missing. Tile drift (US-004) still owns grass/dirt; this ice is a **pocket overlay**, not a catalog floor kind.
