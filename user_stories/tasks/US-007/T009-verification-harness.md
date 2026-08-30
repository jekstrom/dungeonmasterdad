# T009: Verification harness and independent test

**Story**: US-007  
**Status**: Todo  
**Depends on**: T003–T008  
**Parallel**: no

## Goal

Prove the independent test in automation where possible, and list the play pass that still needs a host session.

## Files

- `test_harness/procedural_dungeon/us007_iron_item_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us007_mine_doodad_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us007_mine_harvest_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us007_iron_yield_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us007_mine_lockout_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us007_mine_placement_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us007_building_cost_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us007_replicate_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us007_independent_test.gd` (+ `.tscn`) — story Independent Test as a scripted sequence
- `test_harness/procedural_dungeon/us007_run_harness.sh` — same pattern as `us006_run_harness.sh`

Headless tests attach the `.gd` to a `.tscn`; do not use a bare `.gd` as the main scene. Testing skill: Node + `.tscn` that prints pass and `quit`s on success.

Keep `us006_run_harness.sh` and `us024_tree_scatter_test.tscn` green (trees still harvest; mines do not steal tree cells from the tree test's own scatter unless that test is isolated).

## Headless checks

- `ItemDatabase` loads `res://pickups/metal.tres`; `player_only`; not `auto_use`. Factory `.tres` `cost_item` is that path, `cost_qty` 3.
- Mine scene: `MineDoodad`, Hitbox layer 8.
- 4 melee hits → +1 metal; mine still present; `hits_taken` reset.
- 5 yields → depleted; further hits grant 0; SPACE hint off.
- Full unique inventory without metal → world metal pickup.
- Two completing hits same frame → one iron.
- Fantasy player or mine / DM / building overlap → no hits.
- Scatter: ≥1 mine, eligible cells only, same seed stable.
- 3 metal + legal place → building, inventory 0; 2 metal → reject, inventory 2; blocked footprint → no spend.
- Regen cooldown 0 stays depleted.
- Client cannot stick a local `hits_taken` write.

## Play pass (host)

Independent test from the story:

1. Start a match as a Paper Pusher. Find a mine on the overworld (not in the dungeon). SPACE shows in range.
2. Melee it four times: +1 metal in inventory. Mine still there.
3. A second window: same mine progress; no duplicate iron on the last hit.
4. Harvest until depleted (5 iron from that mine if starting empty aside from yields): depleted art; SPACE gone; further swings do nothing.
5. With ≥3 metal, place a smoke or paper factory in Reality on clear outside ground: cost deducted, building appears.
6. With 2 metal, placement does not spawn and metal stays 2.
7. Host+client: client log clean. Walk Fantasy: cannot mine. LMB staples still work after mining (melee pulse flag expires).

## Requirements

- Independent Test section of US-007
- Testing skill: `godot --path . --headless --quit-after 60 test_harness/procedural_dungeon/<scene>.tscn`

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** a play of the independent test, **When** a Paper Pusher harvests a mine and places a building, **Then** iron grant and cost deduction match the story.

## Notes

Do not claim the story done until this task's headless suite passes and the play pass is run or explicitly called out as not run.

Do not require wood/paper (US-006), gremlins (US-013), or IRS (US-009) to pass.
