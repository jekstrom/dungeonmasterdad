# T006: Paper factory consumes wood and smoke, emits paper

**Story**: US-006  
**Status**: Done  
**Depends on**: T005  
**Parallel**: no (same `paper_factory.gd` as T005)

## Goal

On a successful production interval, an enabled paper factory that has **both** required wood and required smoke consumes those inputs and emits **paper**. If wood is missing, that tick produces **no paper** and consumes **no smoke**. Reality Level grants stay the existing US-008 behavior (only on success). Paper is a world pickup at the factory (harvester can take it) so a disconnect cannot delete output.

## Files

- `buildings/buildables/paper_factory.gd` — today's tick: if `PlayerManager.smoke_amt >= smoke_consume_amt` and `use_smoke`, then `update_reality_level(10)` and play `"paper"`. Change the gate to: **server**, not ghost, `stored_wood >= wood_consume_amt` (default **1**) **and** enough smoke. On success: decrement `stored_wood`, `use_smoke`, `update_reality_level(10)` unchanged, spawn paper. On missing wood: skip; do not call `use_smoke`; do not raise Reality from this factory this tick.
- Keep `sync_blizzard_interval()` at the top of `_process` (US-017). Do not reset interval progress on a failed tick (timer already subtracts `interval`; a no-op tick is OK — next interval retries).
- `pickups/paper.tres` (T001) — emit via `SignalBus.on_item_drop` `{ "item_type": "res://pickups/paper.tres", "position": factory_origin() }` (or a chute offset). Do **not** auto-insert into a player's inventory; they pick it up. Independent test allows inventory **or** world pickup; world drop matches the disconnect edge case ("paper is not deleted").
- `_globals/player_manager.gd` — do **not** add `paper_amt` as a global pool. `max_paper_amt` is unused leftover; ignore it.
- `test_harness/procedural_dungeon/us006_paper_production_test.gd` (+ `.tscn`) — wood+smoke → −wood −smoke +paper drop + Reality +10; no wood → smoke and Reality unchanged, no paper; two factories one smoke budget: only one success if smoke is 3 (US-008 edge; if in scope here, one factory with wood and one without is enough).

## Requirements

- FR-005, FR-006, FR-008, AC4, AC5
- Suggested `wood_consume_amt` **1**. `smoke_consume_amt` stays **3**. Reality on success stays **+10**. Do not retune those for this story.
- Atomic: check wood **and** smoke, then deduct both, then emit paper. If `use_smoke` fails after the wood check, do not lose wood.
- Missing smoke (US-008) also produces nothing; this task must not spend wood without smoke either.
- Ghost factories never produce (existing `is_ghost` guard).
- Production while the depositor is gone: still runs on the host from `stored_wood` + global smoke; paper drop stays in the world.
- Do not convert paper into forms (US-009).
- Existing `"paper"` animation may still play on success only.

## Acceptance

- **Given** an enabled paper factory with `stored_wood >= wood_consume_amt` and `smoke_amt >= smoke_consume_amt`, **When** a production interval completes, **Then** wood and smoke decrease by their costs, a paper pickup exists at the factory, and Reality Level increased by 10.
- **Given** `stored_wood` 0 and enough smoke, **When** an interval elapses, **Then** smoke is unchanged, Reality is unchanged from this factory, and no paper is spawned.
- **Given** enough wood but not enough smoke, **When** an interval elapses, **Then** wood is unchanged and no paper is spawned.
- **Given** the depositing player has disconnected, **When** a legal interval completes, **Then** paper is still spawned on the server and is not deleted.

## Notes

US-008 owns smoke caps and "paper raises Reality more than smoke". Do not change smoke-factory math. Do not grant paper into a hidden global count. Replication of drops/buffer is T007.
