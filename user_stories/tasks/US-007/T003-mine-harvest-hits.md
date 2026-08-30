# T003: Host-validated mine harvest hits

**Story**: US-007  
**Status**: Todo  
**Depends on**: T002  
**Parallel**: no

## Goal

A Paper Pusher harvests a mine with the **same Space / pencil melee** as trees (US-006). The host applies **one harvest hit per legal swing**. Hits per iron yield are configurable (default **4**). Two players share **one** server-side progress bar. Completing a yield cycle does **not** destroy the mine (reset hits after a yield in T004). This task may stop at `hits_taken` / `apply_harvest_hit` without granting iron.

## Files

- `doodads/mine.gd` — copy the US-006 harvest loop from `doodads/tree.gd`: `hits_required` (default **4**), `hits_taken`, `Damaged` on the Hitbox, one hit per hurtbox pulse (`_hit_hurtboxes` token), `apply_harvest_hit(striker)` host-only. PP only; DM no-op. `can_harvest_from` / `is_harvest_prompt_target` using `HARVEST_HINT_RANGE` (64, same as trees).
- `player/player.gd` — reuse `start_melee_attack` / `request_melee_attack` / `_pulse_melee_hurtbox`. **Do not add a new harvest key.** Extend `can_prompt_tree_harvest` (or rename to `can_prompt_harvest`) so SPACE shows when a **mine** in range can currently take a hit (active, not depleted — deplete is T004; until then any living mine). Local-only labels already exist.
- `scripts/hitbox.gd` / `scripts/hurtbox.gd` — existing path. Mine Hitbox layer 8.
- `test_harness/procedural_dungeon/us007_mine_harvest_test.gd` (+ `.tscn`) — instance mine, `apply_harvest_hit` / melee pulse, 1 hit per swing, shared progress, 4 hits to complete a cycle, same-swing no double count.

## Requirements

- FR-002 (hits-per-yield), FR-005, AC1, MR-001
- One successful swing = **one hit**, not `melee_damage` HP.
- Host-authoritative: `hits_taken` only changes on `multiplayer.is_server()` (`OfflineMultiplayerPeer` is a server).
- Two players share `hits_taken`. Same-frame / overlapping hurtbox: one increment per pulse.
- Combat vs harvest: if the swing also hits a monster, existing combat still applies.
- After `hits_taken >= hits_required`, T003 tests may leave the mine in place with progress full; T004 grants iron and resets/depletes. If T003+T004 land together, expose `apply_harvest_hit` returning true on yield-ready.
- `_melee_swing_active` must still expire (~0.12s) so LMB staples work after mining (US-006 harvest fix).

## Acceptance

- **Given** a Paper Pusher in melee range of an active mine, **When** they use Space / melee, **Then** the host increments that mine's `hits_taken` by 1.
- **Given** `hits_required` 4, **When** they hit three times, **Then** `hits_taken` is 3 and the mine is still there.
- **Given** two Paper Pushers each land one hit on the same mine, **When** progress is read, **Then** `hits_taken` is 2 (one bar).
- **Given** the local player is in harvest range of an active mine, **When** hints update, **Then** **SPACE** shows; a remote peer does not see that player's hint.
- **Given** a client, **When** it assigns `hits_taken` locally, **Then** the host value is unchanged.

## Notes

Fantasy / DM / building lockouts are T005. Iron grant and deplete are T004. Map scatter is T006.
