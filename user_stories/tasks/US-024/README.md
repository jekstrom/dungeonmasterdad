# US-024 tasks: Bounded map, layout, and cliff edge

**Story**: [US-024.md](../../US-024.md)  
**Branch**: `024-bounded-map`  
**Status**: Todo

Play inside a finite map ringed by cliffs. Dungeon flush to the **east** interior edge. Paper Pushers on the **west** interior edge. Interior filled with outside grass/dirt and trees. Nothing walks into the void.

## Order

Do T001–T003 first. Layout (T004–T006) needs the map API and cliff tiles. Spawns and clamps (T007–T010) need a real interior. Fill (T011–T013) needs layout. Replication (T014) and the harness (T015) close the story.

| ID | Task | Depends on | Parallel |
|---|---|---|---|
| [T001](T001-map-interior-api.md) | Map interior + cliff ring API | — | |
| [T002](T002-cliff-tile-scene.md) | Cliff tile scene, collision, catalog | T001 | with T003 |
| [T003](T003-cliff-edge-art.md) | Cliff edge / corner sprites | — | with T001–T002 |
| [T004](T004-interior-size.md) | Interior ≥ 4× dungeon AABB | T001 | |
| [T005](T005-dungeon-east-edge.md) | Dungeon flush to east interior | T004 | |
| [T006](T006-cliff-ring.md) | Place cliff ring | T002, T004 | after T005 origin known |
| [T007](T007-player-cliff-clamp.md) | Block players at the cliff | T006 | |
| [T008](T008-actor-cliff-rules.md) | Monsters, projectiles, knockback | T007 | |
| [T009](T009-west-spawn-strip.md) | Paper Pusher west spawn | T004 | with T010 |
| [T010](T010-dm-entrance-spawn.md) | DM at east dungeon entrance | T005 | with T009 |
| [T011](T011-outside-fill.md) | Interior outside grass/dirt fill | T005, US-023 | |
| [T012](T012-tree-scatter.md) | Scatter trees on eligible cells | T011 | |
| [T013](T013-clip-zone-homes.md) | Clip Reality/Fantasy homes to interior | T004 | with T011 |
| [T014](T014-replicate-late-join.md) | Host-authoritative map + late join | T006, T011, T012 | |
| [T015](T015-verification-harness.md) | Headless + play independent test | T007–T014 | |

## Out of scope (stay in other stories)

- Outside grass/dirt variety art (US-023). T011 may use a Neutral placeholder until US-023 lands.
- Zone occupancy and pockets (US-001, US-003) except clipping homes to the interior.
- Dungeon interior generation (existing generator + US-015), except world origin / east flush.
- Tree harvest (US-006). T012 only places existing `TreeDoodad`s.
- Mines (US-007).

## Independent test (story)

Start a match. Playable ground is a rectangle of outside grass/dirt with random trees, large enough that the generated dungeon AABB would fit four times. A cliff ring surrounds it. Paper Pusher and DM both stop at the cliff. Dungeon is committed against the right interior edge. Paper Pushers spawn on the left interior edge. Reality and Fantasy home rectangles lie entirely inside the interior. Walking off the cliff is impossible. A late joiner sees the same map.
