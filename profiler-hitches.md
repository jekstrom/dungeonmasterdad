# Fantasy-level pickup hitches (new capture)

Source: `profiler` (2026-09-03 14:07). Monitor ~23 samples; script profiler **981 frames**.

Pickup itself is cheap. The hitch is the **deferred claim-listener pass** that still runs on the same felt frame as a D6/D20 pickup.

---

## What the capture looks like

Monitor spikes (process / physics), ~15k nodes throughout:

| Monitor | FPS | Process | Physics | Notes |
|---|---:|---:|---:|---|
| m11 | 33 | **390 ms** | **106 ms** | first big hitch |
| m15 | 52 | **453 ms** | 80 ms | |
| m17 | 40 | **312 ms** | 70 ms | |
| m18 | 53 | **457 ms** | 74 ms | |
| m19 | 21 | **494 ms** | 69 ms | worst process |
| m21 | 30 | **456 ms** | 68 ms | |
| m22 | 29 | **469 ms** | 92 ms | |

Between spikes, process is ~17–27 ms (still over 16.6 ms, mostly minimap paint). Physics 2D solver is idle (4 bodies). `flush_queries` is **not** the hitch this time (0.2–0.5 ms on spike frames).

Script profiler: **7 frames** with `ZoneDriftClaim._run_listeners` at **306–488 ms**. Those line up with the monitor spikes.

---

## Pickup vs hitch (they are different functions)

| Script frame | `on_body_entered` | `handle_pickup` | Dice `use()` | Knightling unlock | `_run_listeners` |
|---|---:|---:|---:|---:|---:|
| f0104 | 0.50 ms | 0.47 ms | — | 0.13 ms | 0 |
| f0340 | 0.43 ms | 0.40 ms | — | 0.12 ms | 0 |
| **f0428** | 0.48 ms | 0.46 ms | **0.21 ms** | — | **381 ms** |
| **f0928** | 0.27 ms | 0.26 ms | **0.11 ms** | — | **462 ms** |

- Knightling unlock pickups no longer hitch (unlock no longer fake-emits fantasy level).
- Dice / fantasy-level `use()` is **&lt; 0.3 ms**.
- The 300–500 ms is `ZoneDriftClaim._run_listeners` (deferred claim work), attributed to the same profiler sample as the pickup when `call_deferred` / `process_frame` runs before the next vsync.

There are **7 listener frames** in the capture (f428, f684, f736, f815, f836, f910, f928) — consistent with several D6/D20 pickups.

---

## Nested cost on a hitch frame (inclusive GDScript times)

Example **f0836** (worst listener: 488 ms script):

```
ZoneDriftClaim._run_listeners                          488 ms
  ZoneDriftClaim.ensure_snapshot                       352 ms
    _refresh_zones                                     145 ms
    _rebuild_grid                                       50 ms
    _live_signature / _zone_pockets / claim_at         ~70 ms
  FantasyTileDrift._sync_schedules                     334 ms
    drift_claim_for_cell                               274 ms
    is_fantasy_drift_eligible                          153 ms
    _reconcile_stale_presentations                     167 ms
      _reconcile_tile                                  147 ms
  RealityTileDrift._sync_schedules                     138 ms
    _reconcile_stale_presentations                     132 ms
      _reconcile_tile                                  117 ms
    drift_claim_for_cell                               115 ms
  coverage_cells                                        35 ms
  ZoneAmbientVfx.rebuild_candidates                     16 ms
  minimap paint_map (same frame)                        41 ms
```

Inclusive times nest; unique work is roughly:

| Bucket | Typical hitch cost | What it does |
|---|---:|---|
| Full outside-tile reconcile (Fantasy + Reality) | **~250–330 ms** | Walk **every** outside tile, `claim_at` + presentation check |
| `ensure_snapshot` / grid rebuild | **~50–75 ms** grid + refresh | Rebuild claim grid for whole interior |
| Drift eligibility / `_tile_at` on many cells | **folded into sync** | `is_fantasy_drift_eligible` → `claim_at` |
| Minimap `paint_map` on same frame | **40–96 ms** | Full cell walk + fog textures |
| Ambient VFX `rebuild_candidates` | **10–24 ms** | Re-list dust/sparkle cells |
| Pickup / overlay sprites / unlock | **&lt; 1 ms** | Fixed; not this hitch |

`clip_home`, `_flush_presentation`, `_place_overlay_sprite` do **not** show up as hot. Skipping debug overlay sprites worked. The remaining hitch is **claim listeners + full tile reconcile**.

---

## Why reconcile still walks the whole map

`FantasyTileDrift._sync_schedules` is supposed to reconcile **only flipped cells**. It falls back to every outside tile when `flipped_cells()` is empty:

```gdscript
# fantasy_tile_drift.gd
var flipped: Array[Vector2i] = ZoneDriftClaim.flipped_cells()
if not flipped.is_empty():
    # cheap path
    ...
    return
for node in _iter_outside_tiles():  # hitch path
    _reconcile_tile(...)
```

On every hitch frame, that fallback ran (~130–177 ms Fantasy + ~110–157 ms Reality).

Cause: `ensure_snapshot` **clears `_flipped` on a cache hit**:

```gdscript
# zone_drift_claim.gd ensure_snapshot
if sig == _snapshot_sig and _grid.size() > 0:
    _flipped.clear()   # <-- wipes the list the rebuild just filled
    return
```

`_run_listeners` does:

1. `ensure_snapshot()` → rebuilds grid, fills `_flipped`.
2. `FantasyTileDrift._sync_schedules()` → `drift_claim_for_cell()` → `ensure_snapshot()` again → **same signature** → **clears `_flipped`**.
3. Reconcile sees an empty list → walks all outside tiles.

So the “flipped-only” path never runs on the hitch frames it was meant to fix.

Same empty-flipped fallback then uses `_fantasy_coverage_cells()` / `_reality_coverage_cells()` for scheduling, which is another full home walk (`coverage_cells` 18–41 ms).

---

## `ensure_snapshot` is also over-called

- **637 frames** call `ensure_snapshot`; median when called is **0.05 ms**.
- The **7 listener frames** are **248–352 ms** because they rebuild.
- Even the cheap path still runs `_refresh_zones()` (copy homes + pocket rects, `get_first_node_in_group`) **before** the signature check. That is why `_refresh_zones` has **636** non-zero samples.

Drift `drift_claim_for_cell` → `ensure_snapshot` on **502 frames** (max 274 ms, but that max is the hitch inclusive nest). Steady-state `claim_at` should not need a full snapshot refresh per eligibility test.

---

## Minimap still piles onto the same frames

`paint_map` / `_draw`: **62 paints**, mean **18 ms** when it runs, max **96 ms**. Several hitch frames also paint (40–96 ms). That is not the fantasy-level stack, but it adds to the same spike.

Dirty-redraw is working (not every frame). Paints still walk every interior cell (`is_dm_revealed` + fog `draw_texture_rect`).

---

## What is *not* the hitch (this capture)

- `ItemPickup.on_body_entered` / `handle_pickup` / `ItemData.use` / `IncreaseFantasyLevel.use` (&lt; 0.5 ms).
- Overlay sprite spawn / `_flush_presentation` (absent from the hot list).
- Knightling `unlock` (~0.1 ms).
- Physics 2D `flush_queries` (~0.3 ms on spikes).
- Node count does not jump (stays ~15.3k).

---

## Narrowed next fixes (in order)

1. **Do not clear `_flipped` on `ensure_snapshot` cache hit.** Clear it only when starting a new rebuild. That should make reconcile/schedule use the grown-home ring instead of all outside tiles (~250–330 ms off each dice pickup).

2. **Don’t call `_refresh_zones` until the snapshot is actually dirty** (or cache zone refs + pocket signature without copying arrays every `claim_at`).

3. **`drift_claim_for_cell` should `claim_at` only** after listeners have snapshotted; stop calling `ensure_snapshot` per cell.

4. **Keep claim listeners off the pickup physics callback** (already deferred) but also **don’t rebuild the minimap on the same process_frame** as `_run_listeners` (queue paint one frame later).

5. After (1), if hitch remains, profile `_iter_outside_tiles` / `_tile_at` — full child list of `OutsideTiles` is still the fallback.

---

## Suggested re-capture

After (1)–(3): one D6 and one D20 while standing still with the minimap open. Expect listener frames **&lt; 50 ms** if flipped-only reconcile works; if `_run_listeners` is still hundreds of ms, the leftover is `_rebuild_grid` + `coverage_cells`, not pickup or overlays.
