# T002: Host-validated harvest hits on trees

**Story**: US-006  
**Status**: Done  
**Depends on**: none  
**Parallel**: with T001

## Goal

A living `TreeDoodad` is a harvest node. Paper Pushers in range use the existing **melee / harvest** action; the **host** applies one harvest hit per legal swing. Hits to finish are configurable (default **3**). Two players share **one** server-side progress. No wood yet. The tree stays a living tree until T003.

## Files

- `doodads/tree.gd` / `doodads/tree.tscn` — harvest state: `hits_required` (default 3), `hits_taken` (host), living vs later stump. Add a `Hitbox` the pencil `AttackHurtbox` already hits (player.tscn `AttackHurtbox.collision_mask = 8`; goblin/skeleton hitboxes use `collision_layer = 8`). Do not put the tree on the player-damage layer (256).
- `player/player.gd` — reuse `start_melee_attack` / `request_melee_attack` / `_pulse_melee_hurtbox`. US-005 T005 already notes harvest may reuse melee input. Do not add a second harvest keybind.
- `scripts/hitbox.gd` / `scripts/hurtbox.gd` — existing `Hurtbox` → `Hitbox.take_damage` → `Damaged`. Tree listens on the host.
- `test_harness/procedural_dungeon/us006_tree_harvest_test.gd` (+ `.tscn`) — instance `doodads/tree.tscn`, pulse a Paper Pusher melee (or call the tree's host harvest API), assert hit counts, shared progress, no yield yet.

## Requirements

- FR-001, FR-002, FR-008, AC1, MR-001
- Only **Paper Pushers** increment harvest. DM melee on a tree is a no-op for harvest (lockouts in T004 can also cover this; do not grant hits to the DM here).
- One successful swing = **one hit**, not `melee_damage` HP. `hits_required` default 3, export/configurable.
- Host-authoritative: clients may play the swing; `hits_taken` only changes on `Lobby.is_network_server()` / `multiplayer.is_server()` (headless `OfflineMultiplayerPeer` is a server).
- Two players hitting the same tree share `hits_taken`. Progress must not fork per player.
- Same swing must not apply twice if the hurtbox stays overlapping (`Damaged` once per pulse).
- Do not remove the tree or spawn wood here (T003). After `hits_taken >= hits_required`, leave the tree living until T003 consumes it — or expose `is_ready_to_yield` / a signal T003 connects. Prefer: T002 stops incrementing past required and emits a host signal; T003 performs yield. If T002 and T003 land together, T002 tests may assert `hits_taken == hits_required` with the tree still present when yield is stubbed.
- Combat vs harvest: if the same swing also overlaps a monster, existing combat still applies. Do not cancel pencil damage to harvest.

## Acceptance

- **Given** a Paper Pusher in melee range of a living tree, **When** they use the harvest/melee action, **Then** the host increments that tree's harvest progress by 1.
- **Given** `hits_required` 3, **When** the same player hits twice, **Then** `hits_taken` is 2 and the tree is still living.
- **Given** two Paper Pushers hitting the same tree, **When** each lands one hit, **Then** `hits_taken` is 2 (one shared bar), not 1+1 on two bars.
- **Given** one swing whose hurtbox overlaps the tree for several frames, **When** the pulse ends, **Then** only one hit was applied.
- **Given** a client, **When** it assigns `hits_taken` locally, **Then** the host value is unchanged.

## Notes

Fantasy / under-building / DM lockouts are T004. Stump and wood are T003. Tree scatter stays US-024; tests instance a tree. Optional client-visible progress bar is nice; server `hits_taken` is required.
