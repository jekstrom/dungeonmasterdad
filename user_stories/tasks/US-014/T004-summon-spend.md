# T004: Gremlin and knightling HUD spend mana

**Story**: US-014  
**Status**: Done  
**Depends on**: T003  
**Parallel**: with T005 (not with T007 — same HUD scene)

## Goal

Pressing summon on the DM HUD asks the **host** to `try_cast`, then uses the existing spawn signals. Clients cannot create a gremlin or knight by faking a button. Fantasy Level is no longer the summon tax.

## Files

- `gui/dm/dm_hud.gd` — `_on_gremlin_button_pressed` / `_on_knight_button_pressed` today require `multiplayer.is_server()` and (gremlin) `fantasy_level >= 150`, then `update_fantasy_level(-150)` + `spawn_*`. Replace with a request into `DmManager`.
- `_globals/dm_manager.gd` — `request_cast(ability_id)` for the local host path; `@rpc("any_peer", "reliable")` for a client press. Server: ignore if sender is not the DM peer (host is peer 1 / the `dm` node authority today). Then `try_cast`; on true, existing `spawn_gremlin()` / `spawn_knight()`.
- `scripts/multiplayer_spawner.gd` — keep listening to `spawn_gremlin_cast` / `spawn_knight_cast`; do not re-check mana there if `try_cast` already ran. Do not spawn on a client.
- `test_harness/procedural_dungeon/us014_summon_spend_test.gd` (+ `.tscn`) — HUD gremlin/knight spend mana, refuse at 0, ignore non-DM RPC, no Fantasy Level tax.

## Requirements

- FR-004, FR-005, FR-006, MR-001, MR-002, AC1–AC3, AC7
- Ability ids: `gremlin`, `knightling` (catalog T002).
- HUD may stay visible when short on mana; the action must still no-op. Optional disable/grey is not required.
- Do not grant knightling unlock (US-016).

## Acceptance

- **Given** mana 0, **When** the gremlin or knight HUD button is pressed, **Then** no monster is spawned and mana stays 0.
- **Given** mana ≥ gremlin cost, **When** gremlin is pressed on the host, **Then** mana drops by the catalog cost and exactly one gremlin spawn path runs.
- **Given** the same with knightling and enough mana, **When** knight is pressed, **Then** mana drops by 40 (default) and one knight spawn path runs.
- **Given** a non-DM peer invokes the cast RPC, **When** the host handles it, **Then** mana and world are unchanged.
- **Given** a successful summon, **When** Fantasy Level is read, **Then** it was not reduced by 150 (or any summon tax).

## Notes

`root.gd` only turns `DmHud` on for the host, so the live DM is the server in current play. Still validate on the server so a crafted RPC cannot spawn (MR-002).

Fireball is T005 (targeting, then spend). Do not start fireball targeting from this task.
