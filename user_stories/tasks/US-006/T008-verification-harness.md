# T008: Verification harness and independent test

**Story**: US-006  
**Status**: Done  
**Depends on**: T003–T007  
**Parallel**: no

## Goal

Prove the independent test in automation where possible, and list the play pass that still needs a host session.

## Files

- `test_harness/procedural_dungeon/us006_wood_paper_items_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us006_tree_harvest_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us006_wood_yield_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us006_harvest_lockout_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us006_deposit_wood_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us006_paper_production_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us006_replicate_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us006_independent_test.gd` (+ `.tscn`) — story Independent Test as a scripted sequence
- `test_harness/procedural_dungeon/us006_run_harness.sh` — same pattern as `us014_run_harness.sh` / `us024_run_harness.sh`

Headless tests attach the `.gd` to a `.tscn`; do not use a bare `.gd` as the main scene. Testing skill: Node + `.tscn` that prints pass and `quit`s on success.

Keep `us024_tree_scatter_test.tscn` and `us017_blizzard_factory_test.tscn` green (trees still `TreeDoodad`; paper factory interval / blizzard factor unchanged on success-vs-fail ticks).

## Headless checks

- `ItemDatabase` loads `res://pickups/wood.tres` and `res://pickups/paper.tres`; `player_only`; not `auto_use`; distinct names; paper texture is not `sprites/paper-sheet.png`.
- Living tree, Paper Pusher melee: 1 hit per pulse; 3 hits default to complete; two strikers share `hits_taken`.
- Complete harvest with space: wood in that player's inventory; tree is stump/unavailable; second complete swing grants nothing.
- Full unique inventory without a wood stack: world wood pickup at the tree; item not lost.
- Two completing hits same frame: one yield.
- Fantasy-claimed player or tree: no hits. DM: no hits. Enabled building overlap: no hits.
- Deposit in range: inventory wood −1, factory `stored_wood` +1. Ghost / out of range / no wood: no change.
- Factory tick with wood + smoke ≥ 3: wood −1, smoke −3, paper dropped, Reality +10. Tick with 0 wood: smoke and Reality unchanged, no paper.
- Client cannot stick a local `hits_taken` or `stored_wood` write on the host.

## Play pass (host)

Independent test from the story:

1. Start a match as a Paper Pusher. Find a scattered overworld tree (US-024). Melee it three times: stump, wood in inventory (or a pickup if full).
2. A second window watches: same stump, no second wood.
3. Place or use an enabled paper factory in Reality with smoke available (smoke factory or debug smoke). Interact to deposit wood.
4. Wait one production interval: smoke down, paper pickup (or inventory paper) appears, Reality Level ticks +10 as today.
5. Deposit nothing / wait another tick with 0 factory wood: no paper, smoke not spent from that factory.
6. Host+client join: client log clean (`ERR_BUG` / `has_node` / invalid synchronizer). Walk a Paper Pusher through Fantasy and confirm harvest does not work there; walking itself still works (US-003 T011).

## Requirements

- Independent Test section of US-006
- Testing skill: `godot --path . --headless --quit-after 60 test_harness/procedural_dungeon/<scene>.tscn`

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** a play of the independent test, **When** a Paper Pusher harvests, deposits, and waits a factory tick, **Then** wood grant, factory consume, and paper output match the story.

## Notes

Do not claim the story done until this task's headless suite passes and the play pass is run or explicitly called out as not run.

Do not require mines (US-007), forms (US-009), or gremlins (US-013) to pass.
