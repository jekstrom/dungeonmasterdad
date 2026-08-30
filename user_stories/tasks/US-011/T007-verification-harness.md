# T007: Verification harness and independent test

**Story**: US-011  
**Status**: Done  
**Depends on**: T003–T006  
**Parallel**: no

## Goal

Prove the independent test in automation where possible, and list the play pass that still needs a host session.

## Files

- `test_harness/procedural_dungeon/us011_building_hp_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us011_raid_targeting_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us011_goblin_melee_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us011_destroy_rubble_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us011_non_goblin_lockout_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us011_replicate_test.gd` (+ `.tscn`)
- `test_harness/procedural_dungeon/us011_independent_test.gd` (+ `.tscn`) — story Independent Test as a scripted sequence
- `test_harness/procedural_dungeon/us011_run_harness.sh` — same pattern as `us006_run_harness.sh` / `us016_run_harness.sh`

Headless tests attach the `.gd` to a `.tscn`; do not use a bare `.gd` as the main scene. Testing skill: Node + `.tscn` that prints pass and `quit`s on success.

Keep green: `us005_combat_loadout_test.tscn` (no staple damage to buildings), `us006_paper_production_test.tscn` / `us006_deposit_wood_test.tscn` (operating factories still produce/deposit), `us009_irs_building_test.tscn` uniqueness (destroyed IRS does not block rebuild if that test exists; if it only checks a living IRS, do not break it), `us017_blizzard_factory_test.tscn` (operating factory interval), `us001_reality_claim_test.tscn` / `us001_skeleton_ban_test.tscn` (goblins still allowed in Reality; skeletons still do not raid).

## Headless checks

- Smoke 8/8, paper 12/12, IRS 20/20 when enabled; ghost has no bar.
- Goblin, no player in range: acquires enabled factory and moves closer; ignores ghost; prefers factory over IRS; IRS if no factory; player in `screen_spot_range()` beats factory.
- One goblin melee pulse: factory HP −1 on server.
- Last HP: rubble (smoke 128×128 / paper 100×100, same sprite offset), collision off, no `add_smoke` / no paper emit on a following `_process(interval)`, no iron/wood refund. Deposit after destroy fails.
- Same-frame last HP vs production tick: no smoke/paper grant.
- Skeleton, knight, staple, PP melee: HP unchanged. Goblin still chips.
- `raids_buildings` true only on goblin.
- Replicated `hitpoints` path present; client `hitpoints = 0` does not destroy the host factory.
- Independent sequence: enable factory → instance goblin in range → HP drops → at 0 factory not producing. Second sequence: damage the goblin / place a player in range → goblin leaves raid; factory survives if the goblin dies first (`Enemy.die()`).

## Play pass (host)

Independent test from the story:

1. Start a match as a Paper Pusher. Place an enabled smoke or paper factory in Reality (iron from US-007; tests/play may grant metal).
2. As DM (second window or after role): spawn a goblin (`goblin.tscn` — dungeon crawl or HUD gremlin, which currently uses that scene). Confirm it walks to the factory, not the ghost preview.
3. Watch HP bar drop on both windows. At 0: factory becomes rubble, collision gone, smoke/paper stop. Iron is not refunded.
4. Repeat with a new factory. Staple / pencil the goblin dead before 0 HP: factory remains and keeps producing. Staples do not chip the factory.
5. Optional: place IRS, remove factories, confirm goblins will hit IRS (unique not immune).
6. Host+client join: client log clean (`ERR_BUG` / `has_node` / invalid synchronizer). Late join after a destroy sees rubble, not a live factory.

## Requirements

- Independent Test section of US-011
- Testing skill: `godot --path . --headless --quit-after 60 test_harness/procedural_dungeon/<scene>.tscn`

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** a play of the independent test, **When** a goblin raids a factory, **Then** HP, destroy/rubble, stop-production, and “kill goblin to save it” match the story.

## Notes

Do not claim the story done until this task’s headless suite passes and the play pass is run or explicitly called out as not run.

Do not require Office Max (US-010), gremlin carry (US-013), knightling execute (US-012), or mana spend (US-014) to pass. Headless tests instance `monsters/goblin.tscn` and factory scenes directly.
