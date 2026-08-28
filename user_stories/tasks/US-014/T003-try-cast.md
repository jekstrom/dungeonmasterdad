# T003: Server `try_cast` — validate and deduct

**Story**: US-014  
**Status**: Done  
**Depends on**: T001, T002  
**Parallel**: no

## Goal

One host function is the only way mana is spent on an ability. It checks unlock + cost, deducts **atomically**, and returns success/failure. On failure the world does not change. Callers (T004, T005) run the existing spawn/spell only after `true`.

## Files

- `_globals/dm_manager.gd` — `try_cast(ability_id: String) -> bool` (name may be `try_spend`; one function that checks and deducts).
- Optional `request_cast` RPC lives in T004; this task is the host-only gate.
- `test_harness/procedural_dungeon/us014_try_cast_test.gd` (+ `.tscn`) — refuse at 0 / short mana, unlock gate, sequential spend, no spawn, no Fantasy Level tax.

## Requirements

- FR-004, FR-005, FR-006, FR-008, MR-001, AC1, AC2, AC3, AC7
- `if not multiplayer.is_server(): return false` (or `Lobby.is_network_server()` if OfflinePeer would false-pass in tests — tests may set mana on the autoload and call `try_cast` with a fake server; document the check).
- Order: unknown id → fail; unlock id set and `DmUnlocks` false/missing → fail; `current_mana < cost` → fail; else subtract cost, replicate, return true.
- Deduct **before** the caller emits `spawn_gremlin_cast` / `spell_cast`.
- Two calls in one frame: second sees the new current. Do not snapshot mana once and approve both.
- Fantasy Level is **not** read or written as payment. Gremlin’s `>= 150` / `-150` and knight’s `-150` must not live in this function.

## Acceptance

- **Given** current mana 0, **When** `try_cast("gremlin")` / `"knightling"` / `"fireball"` / `"bemidji_blizzard"` runs, **Then** it returns false, mana stays 0, and no spawn/spell signal fires from this function.
- **Given** current mana 10 and gremlin cost 20, **When** `try_cast("gremlin")` runs, **Then** false and mana stays 10.
- **Given** current mana 25 and gremlin cost 20, **When** `try_cast("gremlin")` returns true, **Then** mana is 5 and only then may the caller spawn.
- **Given** fireball still locked, **When** `try_cast("fireball")` runs with enough mana, **Then** false and mana is unchanged.
- **Given** two successful-cost abilities requested in one frame with mana for only one, **When** both go through `try_cast`, **Then** the first succeeds and the second fails.
- **Given** a successful `try_cast("gremlin")`, **When** `fantasy_level` is read, **Then** it is unchanged.

## Notes

This function must not instance goblins, knights, or fireballs. `bemidji_blizzard` and `dad_all_powerful` only need reject/allow. Cost 0 (`dad_all_powerful`) passes the mana check and still fails if locked.

Do not add `print` spam for every refuse; HUD/audio feedback is T007 if needed.
