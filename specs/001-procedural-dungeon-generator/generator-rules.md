# Generator Rules v1

**Feature:** Parameterized Procedural Dungeon Generation  
**Branch:** `001-procedural-dungeon-generator`  
**Audience:** whoever implements this (Gameplay Programmer)  
**Status:** Design pass. Replaces the current "two squares + L + random walks" behavior.  
**Contract that does not change:** server-authoritative; caller still passes `requestId`, `startPosition`, `exitPosition`, `generationBounds`; exactly one entrance and one exit on those cells; existing floor/wall scenes and goblin/skeleton/knight only.

This is not a new generator. It is rules for the modules that already run in `_build_layout_candidate()`.

---

## Player-facing goal

A generated dungeon is a short readable journey: **safe start → at least one purposeful middle room → gated exit**. Hallways connect. Dead ends pay. Monsters are encounters in rooms, not noise on cells.

If a layout is connected but has only two rooms, it is a failed layout. Retry.

---

## Pipeline (same order, new jobs)

| Step | Module | v1 job |
|---|---|---|
| 1 | `EntranceExitResolver` | Unchanged. Start ≠ exit, both in bounds. No snap. |
| 2 | `RoomGraphGenerator` | Place **start, exit, and 1–3 mid rooms**. Build a tree of edges. |
| 3 | `HallwayCarver` | Carve a **1-cell L** for **every graph edge**, not just start→exit. |
| 4 | `MazeInfillGenerator` | 1–3 **dead-end** branches that end in a **3×3 pocket**. No scribble infill. |
| 5 | `LayoutComposer` + classifiers | Every room square and every pocket is a **room**. Everything else walkable is a **hallway**. |
| 6 | `PathValidator` | Unchanged BFS. Must connect entrance to exit. |
| 7 | Tiles | Set **floor_type / wall_type** from role. Walls are **occupancy-adjacent only** (no solid-block fill). |
| 8 | `MonsterSpawnPlanner` | Place **encounter packages by room role**. No density formula. |

`profile_id` `"standard"` means these rules. Other profiles are out of scope. Do not leave the field unused; read it and branch only on `"standard"` (unknown profile → `INVALID_REQUEST`).

Use `generation_seed` for **all** RNG: room jitter, extra loop edge, dead ends, encounters. Formula can stay `request_id.hash() + (attempt_index + 1) * 7919`. Rooms and the L currently ignore seed; that is a bug after this pass.

---

## 1. Rooms

### Counts and size

- Always place `room_start` (center = start cell, **radius 2** → 5×5 before clip) with role `start`.
- Always place `room_exit` (center = exit cell, radius 2) with role `exit`.
- Place `mid_count` extra rooms, role `mid`:

```
mid_count = clamp(floor(bounds_area / 180), 1, 3)
```

Examples: `16×16` → 1 mid (3 rooms total). `20×20` → 2. `24×24` → 3.

- Mid room radius is **2** (same 5×5). No size variety in v1. Shape is still a Chebyshev square. Variety comes from **count, placement, and contents**, not blobs.

### Separation (hard)

- After clip, a room MUST keep **≥ 9 cells**.
- Chebyshev distance between any two room **centers** MUST be **≥ 6** (the 5×5 squares do not touch or overlap; at least one cell of hall or wall between them).
- If start and exit already violate that, fail the candidate (`LAYOUT_INFEASIBLE` after retries). Do not merge them into one region.

### Mid placement (implement this, not a different algorithm)

1. Build the current start→exit L cells (same X-then-Y walk as today's carver). Those are **anchors**, not yet hallways.
2. Pick candidate centers from cells on that L whose Chebyshev distance to start **and** to exit is **≥ 6**.
3. Shuffle with the generation seed. Greedily take up to `mid_count` candidates that also sit **≥ 6** from already chosen centers and whose clipped square has ≥ 9 cells.
4. **Jitter (required if `mid_count >= 2`):** pick one placed mid and move it perpendicular to the start→exit L by `randi_range(4, 8)` cells (either sign). Keep the jitter only if separation, bounds, and ≥ 9 clipped cells still hold. If every jitter fails, retry the candidate. A layout where every mid sits on the start→exit L cannot grow a real loop, because every extra L retraces that backbone.
5. If you cannot place `mid_count` rooms, fail the candidate and retry with the next seed. Do not silently drop to two rooms.

Worked maps: `generator-rules-examples.md` in this folder.

### Graph

- Sort mid rooms by projection onto the vector `exit - start`.
- Edges: `start → mid_1 → … → mid_n → exit`. This is the **backbone**.
- If `mid_count >= 2` and `seed % 2 == 0`, add **one** extra edge between two non-adjacent rooms on that list. Add it only if the X-then-Y L between those two rooms contains **at least one cell that is not already on the backbone**. Otherwise skip the extra edge (do not add a degenerate retrace). At most one extra edge.
- `graph_edges` MUST be consumed by the carver. Today's unused `[["room_start","room_exit"]]` is the bug.

### Roles the rest of the pipeline can read

Every room region record MUST include `role`: `start` | `mid` | `exit` | `deadend`.  
Store it on the region. Classifiers today only have `{roomId, cells}`. Add `role`.

---

## 2. Hallways

- Width **1 cell**. Keep it. This game's cell is 128px and walk speed is 300; a 1-cell hall is a choke, not a bug.
- Carve one L per graph edge (`HallwayCarver` as it exists, called in a loop).
- Where an L crosses a room square, those cells stay **room** cells. They are doors, not hallway.
- After all edges: hallway cells = walkable cells that are not in any room square or deadend pocket.
- No second-wide corridors in v1. No winding halls. The maze feel comes from **the extra loop + dead ends**, not from random walks off the backbone.

### Door cells

A **door cell** is a room cell with at least one hallway neighbor (4-way).  
Spawns and dead-end roots may not use door cells.

---

## 3. Dead ends (replaces maze infill)

Today's 2–6 random walks of length 6–16 are noise. Replace them.

- `deadend_count = clamp(mid_count, 1, 3)`
- Each dead end:
  1. Pick a **hallway** cell that is not on the BFS `main_path_cells` if any such cell exists; otherwise any hallway cell that is not a door neighbor.
  2. Walk **4–8** steps with the seeded RNG, 4-way, **rejecting** steps that enter a room square or leave bounds. Prefer steps that increase Chebyshev distance from the nearest room center.
  3. At the terminal cell, stamp a **3×3** (radius 1) clipped to bounds. That pocket is a room with role `deadend`.
  4. The walk cells are hallway.

If a walk cannot grow at least **4** cells plus a pocket of **≥ 5** cells, abort that dead end and try another root (max 8 tries). It is legal to end up with fewer dead ends than `deadend_count` after that. It is **not** legal to have **zero** dead ends unless bounds area `< 16×16`.

Dead-end pockets have **no monsters** in v1. They exist so a branch is worth walking (space, cover, future loot). Do not fill them with knights.

---

## 4. Bounds and failure

Enforce what `dungeon_constants.gd` already defines:

- `generationBounds.size` MUST be **≥ `STANDARD_MIN_BOUNDS` (16, 16)** on both axes. Smaller → `POSITION_OUT_OF_BOUNDS` or a new `BOUNDS_TOO_SMALL` (prefer the new code; US1 and US2 use `24×24` as in `generator-rules-examples.md`).
- Size ≤ 0 still invalid.
- Keep `MAX_GENERATION_ATTEMPTS = 20`.
- A candidate fails if: path missing, any required room role missing (`start`, `mid`, `exit`), any room has < 9 cells, rooms overlap/touch (Chebyshev centers < 6), hallway regions empty.

Direct `generate_dungeon_contract` must clear `active_request_id` on success **and** failure the same way the RPC notifies do. The US2 harness currently cannot run a second request without `SESSION_CONFLICT`. That is a blocker for variety tests; fix it as part of this pass.

---

## 5. Tiles (visual language)

Catalog stays `floor.tscn` and `wall.tscn`. Entrance and exit still use the floor scene. The atlas only has **two** floor frames (0 and 1) and **four** wall frames (0–3, type 2 = vertical collider). Do not write `floor_type` 2–9 or `wall_type` 4–9; those UVs are junk.

| Cell | Scene | Type |
|---|---|---|
| Room floor (`start`, `mid`, `exit`, `deadend`) | floor | `floor_type = 0` |
| Hallway floor | floor | `floor_type = 1` |
| Entrance cell | floor | `floor_type = 0` (same as start room; identity is the 5×5 + no spawns) |
| Exit cell | floor | `floor_type = 0` |
| Wall with an E/W **walkable** neighbor | wall | `wall_type = 2` (vertical collider; blocks E/W) |
| Other occupancy-adjacent walls | wall | `wall_type = 1` |

`wall_type` follows the **collider**, not compass-dominant neighbors. `wall.gd` type 2 is the vertical collider that blocks E/W occupancy edges. Match client-tile smoke (`d8a1710`): E/W walkable neighbor → 2, else 1.

Place walls only on cells **adjacent to walkable occupancy**. Do not fill remaining bounds or the interiors of solid blocks. Every walkable-to-blocked 4-edge MUST still have a wall collider (that is what occupancy-adjacent means). Hollow interiors stay empty so the dungeon is a shell in the playground, not a 24×24 wall stamp.

Set the export **on the instanced node** in `DungeonSceneBuilder`. `variantId: -1` is why everything looks the same today. Either plumb `variantId` to `floor_type` / `wall_type` or set the property directly. Direct is fine.

Do not instantiate trees, zones, pickups, or buildings in v1. They exist in the project and they are the right next toys; they are not in FR-006/007. Call that **v1.1** at the bottom. Do not sneak them in.

---

## 6. Encounters

Delete `spawn_count = mini(8, maxi(2, candidate_cells.size() / 20))`. That formula is not a designer.

### Exclusion (hard)

No spawn on:

- entrance cell, exit cell
- 4-neighbors of entrance or exit
- door cells
- any `start` room cell
- any `deadend` room cell

### Packages by role

At most **one knight** in the whole dungeon.

| Role | Package (roll once per room, seeded) |
|---|---|---|
| `start` | always `[]` |
| `deadend` | always `[]` |
| `mid` | `00–59`: two `goblin`; `60–89`: `skeleton` + `goblin`; `90–99`: one `knight` **if no knight placed yet**, else two `goblin` |
| `exit` | `00–69`: one `skeleton`; `70–99`: `[]` |
| hallway | only if **that hallway region** has **≥ 8** cells: `00–39` one `goblin` on a cell ≥ 3 steps (BFS) from every door cell; else `[]` |

Place package members on **distinct** cells inside the room, preferring cells **farther from door cells** (max min-distance to a door). 8 occupied-cell retries then drop that member.

### Known combat debt (do not block on it)

- Goblin has no hurtbox. Still spawn it; it is a readable body and the catalog type we have.
- Skeleton chases the DM, not the player. Still spawn it in mid/exit; that is existing AI.
- Knight charges randomly. That is why it is **solo** and **room-only**.
- Enemy take-damage and player attack are commented out. Generator still places the pack. Combat tuning is not this task.

---

## 7. What you may not do in v1

- Change cell size (128).
- Change hallway width.
- Add keys, locks, secrets with items, or spawn tables beyond the three catalog monsters.
- Generate DM HUD actions, cursor spawns, or zones.
- Treat infill pockets as hallways.
- Pass a layout with fewer than **one** `mid` room.
- Use `profile_id` for anything except rejecting non-`"standard"`.

---

## 8. Acceptance (replace the current harness checks)

Keep the three harness scripts. Change what they assert.

**US1 connectivity** (`us1_connectivity_test.gd`)

- Request: start `(2,2)`, exit `(16,16)`, bounds `24×24`. Do **not** keep the old `(2,2)→(10,10)` in `20×20`; those centers are only Chebyshev 8 apart and cannot fit a mid that is ≥ 6 from both.
- `ok`, entrance and exit coords match request, `mainPath` non-empty.
- **New:** walk `mainPath` and assert each step is 4-adjacent and walkable.
- **New:** at least one region with `role == "mid"`.
- **New:** start room has zero spawns.

**US2 variety** (`us2_layout_variety_test.gd`)

- Six runs. After the session-lock fix, use the **same** start `(2,2)`, exit `(16,16)`, bounds `24×24`, and **different** `requestId` (so seed differs).
- Each run has ≥1 `start`, ≥1 `mid`, ≥1 `exit`, ≥1 hallway.
- Signature = sorted walkable-cell set (or a hash of it), **not** region counts. Fail only if all six cell-sets are identical.
- **New:** at least one run has a loop (walkable degree-3+ junction or hallway cell not on `mainPath`).

**US3 content** (`us3_content_compliance_test.gd`)

- All `tileSourcePath` in catalog. All spawn paths in catalog. No spawn on entrance/exit **or their 4-neighbors**.
- **New:** every room floor instance has `floor_type == 0`, every hallway floor `floor_type == 1`.
- **New:** no spawn in the start room. At least one spawn in some mid room.
- **New:** knight count ≤ 1.

---

## 9. Debug (cheap, do it)

No overlay exists. Add a server-only print dump on success, one line per region:

```
[dungeon] role=mid id=room_mid_1 cells=25 doors=2 spawns=2
```

If you have time, color the `Tiles` node's groups (`room`, `hallway`, `entrance`, `exit`) so playground inspection is possible. Do not block the rules on a debug draw.

---

## v1.1 (not this pass)

When FR-006/007 open up:

1. Trees (`doodads/tree.tscn`) as 1–2 chokes in a mid room, never on doors.
2. One pickup in each deadend (`metal.tres` for players, or `d6.tres` for DM).
3. Optional `RealityZone` around start and `FantasyZone` around exit so the dual meter has a spatial read.

Until then, do not instance them.

---

## Suggested implementation order

1. Session lock clear on contract success/failure (unblocks tests).
2. Room graph with mid rooms + separation + consume `graph_edges`.
3. Dead-end pockets instead of random infill.
4. Role on regions; spawn planner rewrite; start-room exclusion.
5. `floor_type` / `wall_type` in the scene builder.
6. Harness asserts above.

If a step ships alone, ship **2 before 4**. Encounters on a two-room L are still the old game.
