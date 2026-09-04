# Profiler low-hanging fruit

Source: Godot 4 monitor + script profiler CSV in `profiler` (~305 monitor frames, ~1149 script frames).

Steady-state (median): **55 FPS**, **27 ms process** (already over a 16.6 ms / 60 FPS budget). Script functions median **29.6 ms/frame**. Physics 2D is idle most frames (4–8 bodies, ~8 pairs) except claim/pickup spikes.

Node count is high and growing: **~15.7k → 20.0k nodes**, **~25k → 29k objects**. Draw calls **168 → 578**. Raster objects drawn stay ~**4,890** (one draw per map cell plus overlays).

---

## Ranked list (do these first)

### 1. Stop redrawing the minimap every frame — ~15 ms/frame, every frame

| Function | Median | p95 | Total |
|---|---:|---:|---:|
| `gui/minimap/minimap_map_view.gd::_draw` | 14.0 ms | 21.0 ms | 17.0 s |
| `gui/minimap/minimap_widget.gd::paint_map` | 14.0 ms | 21.0 ms | 17.0 s |

`MinimapWidget._process` calls `_queue_map_redraw()` whenever the map is visible. That forces a full `_draw` **every idle frame**.

`paint_map` then walks **every interior cell** and, per cell:

- `MinimapReveal.is_dm_revealed` / `is_pp_revealed`
- `ZoneDriftClaim.for_cell` (group lookups + pocket tests)
- `draw_rect` / `draw_texture_rect` (fog or wash)

That alone is most of the frame.

**Cheap fix**

- Do **not** `queue_redraw()` from `_process`.
- Redraw on `reveal_changed`, claim/home changed, map bounds, and a throttled actor-pip update (5–10 Hz is plenty).
- If the map is hidden, `set_process(false)` and skip paint.

Expected: drop process from ~27 ms toward ~12 ms without touching gameplay.

---

### 2. Cache claim queries used by that paint — ~2–4 ms/frame stacked on (1)

| Function | Median | Mean | Notes |
|---|---:|---:|---|
| `ZoneDriftClaim.for_cell` | 1.03 ms | 3.80 ms | every frame |
| `ZoneDriftClaim._zone_pocket_covers` | 0.56 ms | 2.03 ms | child of `for_cell` |
| `RealityZone.winning_pocket_id` | 0.19 ms | 0.68 ms | calls `_sync_claim_home` per cell |
| `FantasyZone.winning_pocket_id` | 0.18 ms | 0.65 ms | same |
| `minimap_widget::_paint_fog` | 1.73 ms | 1.84 ms | per unrevealed cell |
| `collect_revealed_tree_cells` + `_draw_trees` | 1.65 ms | 1.83 ms | full group scan each paint |
| `MinimapReveal.is_dm_revealed` | 1.61 ms | 1.69 ms | dict hit per cell |

`for_cell` does `get_first_node_in_group("RealityZone")` and `"FantasyZone"` **once per cell per frame**. `winning_pocket_id` copies `home_rect` every call.

Tree/wall/mine collectors call `get_nodes_in_group` over all doodads on every paint (`scattered_trees`, `exit_forest_trees`, `generated_dungeon_tiles`, …).

**Cheap fix**

- Cache zone node refs; don’t group-search per cell.
- Build a `PackedByteArray` / Dictionary claim grid when homes/pockets change; minimap reads that.
- Cache revealed tree/wall/mine cell lists until those groups change.
- `winning_pocket_id`: skip `_sync_claim_home` unless `home_rect` actually changed.

Even with (1) still redrawing, this cuts the remaining minimap cost a lot.

---

### 3. Fantasy-level / pickup hitch — 200–620 ms spikes (13 events in this capture)

Monitor: several **~1 s process** stalls and physics spikes up to **636 ms**. Script traces them to the same stack:

```
ItemPickup.on_body_entered / ItemData.use
  → increase_fantasy_level / unlock_knightling
    → DmManager.update_fantasy_level / request_fantasy_level_incrase
      → FantasyZone.on_level_changed
        → Zone.clip_home_to_interior
          → _resolve_overlapping_homes
          → _apply_clipped_home_presentation / _rebuild_home_overlay
          → FantasyTileDrift._on_claim_changed → _sync_schedules → _reconcile_stale_presentations
          → RealityTileDrift same
          → ZoneAmbientVfx.rebuild_candidates
```

When called, mean cost is **hundreds of ms** (e.g. `update_fantasy_level` 503 ms mean, max 619 ms). `_rebuild_home_overlay` instantiates a sprite **per home cell**. `_reconcile_stale_presentations` walks **all outside tiles** and calls `for_cell` on each. Physics `flush_queries` hits **619 ms** on the same frames (new overlay Area2D / collision churn).

**Cheap fix**

- Debounce / coalesce level-changed work: one rebuild per frame, not per RPC hop.
- Don’t rebuild both zones’ overlays + both drift systems + ambient VFX synchronously on the pickup frame.
- Overlay: one `TileMap` / atlas, not one `Sprite2D` per cell.
- Drift reconcile: only cells whose claim actually flipped, not the whole outside set.
- Spread `_convert_cell` / overlay spawn across frames (already somewhat staggered for drift fire; apply the same to overlay rebuild).

This won’t raise median FPS, but it removes the “game freezes when I pick up Dew / level ticket” hitch.

---

### 4. Tile drift `_physics_process` while converting — ~7 ms p95 when active

`FantasyTileDrift._physics_process` / `_fire_due`: **476 frames**, p95 **6.8 ms**, max **27 ms**. `_fire_due` scans **all pending cells** every physics tick to find the next due cell.

**Cheap fix**

- Keep pending as a min-heap / sorted by fire time instead of a full Dictionary scan.
- Cap conversions per tick (already one cell; the scan is the cost).
- `is_fantasy_drift_eligible` → `drift_claim_for_cell` → `for_cell` again: use the cached claim grid from (2).

---

### 5. Gremlin steering does too much per physics tick — ~1.1 ms median (will scale with count)

`Gremlin._physics_process` median **0.91 ms** (max 21 ms). Hot children:

- `_steer_inland` 0.59 ms — 8 direction probes, each `_is_walkable`
- `_is_walkable` / `_get_walk_rect` / `_clamp_to_walkable` each do `get_first_node_in_group("level_manager")` + `get_map_bounds()`

HUD summons + Crib Death will multiply this.

**Cheap fix**

- Cache `level_manager` / `MapBounds` on the gremlin (refresh on map-bounds signal).
- Probe 4 directions, not 8, and not every tick (every 2–3 physics frames).
- Share one walk-rect with skeletons / knights.

---

### 6. Factory / mine HUD scans the world every frame

`gui/factory_status_hud.gd::_process` walks `mines`, `harvest_nodes`, factories, fill, IRS, interact prompts **every frame**, including `get_nodes_in_group` and stale-marker frees.

**Cheap fix**

- Sync markers on spawn/despawn/progress signals, not every frame.
- World-to-screen follow can stay in `_process` for *existing* markers only.

---

### 7. Empty `Hitbox._process`

`scripts/hitbox.gd::_process` is `pass` but still runs on every hitbox every frame (shows up in the script dump).

**Cheap fix:** delete `_process` (or never enable process). Same check for other empty `_process` stubs.

---

### 8. Unique `AtlasTexture` per outside tile

`OutsideTile._ensure_unique_texture` duplicates the atlas per instance. With a full overworld of outside tiles this is extra resources + extra draw-state.

**Cheap fix:** share one atlas per (kind, presentation, variety) and set `region` only, or use a `TileMap`/`TileSet`.

---

### 9. Scene graph size (~16–20k nodes)

Monitor: **15,697 nodes** shortly after load, **19,992** by the end. Raster still draws ~4,900 objects, so most nodes are off-screen tiles/doodads (outside tiles, trees, walls as individual scenes).

This makes (2), (3), (6), and group scans expensive even when “nothing is happening.”

**Cheap-ish steps before a full TileMap rewrite**

- Don’t put `MultiplayerSynchronizer` / extra Area2D on static tiles.
- Cull process on off-screen doodads (`VisibleOnScreenNotifier2D` or a grid sleep).
- Longer term: floors/walls/outside as `TileMap` layers (biggest structural win; not a one-line change).

Draw calls climbing **169 → 578** in this capture is consistent with overlay sprites, drift puffs, and extra actors accumulating.

---

### 10. Minimap reveal host tick

`MinimapReveal._process` → `_host_tick_living_movers` → `apply_visit_at` median **0.57 ms**. Fine vs minimap paint, but it still walks player/DM groups every frame and can emit `reveal_changed` (which should be the *only* thing that dirties the map once (1) is fixed).

**Cheap fix:** tick on movement cell-change, not every frame; keep the Chebyshev brush.

---

## What not to chase (from this dump)

- **Physics 2D idle:** integrate/solve are ~0.02–0.06 ms. The 600 ms physics spikes are `flush_queries` during overlay/pickup, not the solver.
- **Navigation:** ~0.
- **Orphan nodes:** 0.
- **Texture memory:** ~24 MB, stable. Video mem ~89 MB. Not the FPS problem.
- **Audio driver latency** is ~220 ms in the monitor counters (buffer/config), not script CPU. Separate from this list.
- **Crib Death / `exit_forest_plan`:** shows up when a gremlin auto-spawns; not a frame-rate issue.

---

## Suggested order of work

1. Minimap: redraw on dirty, not every `_process`. (Biggest FPS win, smallest risk.)
2. Cache `ZoneDriftClaim` + zone node refs; stop per-cell group lookups.
3. Cache tree/wall cell lists for the minimap.
4. Remove empty `Hitbox._process`.
5. Cache map-bounds on gremlins; fewer walk probes.
6. Coalesce fantasy-level overlay/drift rebuild off the pickup frame.
7. Heap / dirty-set for tile-drift pending cells.
8. Factory HUD: event-driven markers.
9. Shared outside-tile atlases / TileMap (larger, but unlocks node-count).

After (1)–(3), a new capture should show process median well under 16 ms if the minimap is the main culprit this file says it is.
