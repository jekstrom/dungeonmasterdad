# T004: Iron yield, deplete, and regen

**Story**: US-007  
**Status**: Todo  
**Depends on**: T001, T003  
**Parallel**: with T005

## Goal

When harvest progress completes, the host grants **1 iron** (`pickups/metal.tres`) via `PlayerManager.grant_item_or_drop`, resets hit progress, and keeps the mine in the world. After **5** yields the mine **depletes** (depleted art, not harvestable). After a configurable **regen cooldown**, it becomes active again; cooldown **0** means it stays depleted.

## Files

- `doodads/mine.gd` — `iron_per_yield` default 1; `yields_before_deplete` default 5; `yields_taken`; `is_depleted`; `regen_cooldown` (seconds, export; 0 = no regen). On yield: `grant_item_or_drop` at mine position; `hits_taken = 0`; `yields_taken += 1`; if `yields_taken >= yields_before_deplete` then deplete. Host regen timer while depleted if cooldown > 0: restore active art, `yields_taken = 0`, `hits_taken = 0`, harvest Hitbox on.
- `sprites/mine_depleted.png` — swap sprite on deplete; restore `mine_active.png` on regen.
- `_globals/player_manager.gd` — reuse `grant_item_or_drop` (full unique slots without a metal stack → world drop; existing metal stack still grants).
- `test_harness/procedural_dungeon/us007_iron_yield_test.gd` (+ `.tscn`) — 4 hits → +1 metal; 5 yields → depleted, further hits grant nothing; inventory full without metal → world pickup; same-frame completing hits → one iron; cooldown 0 stays depleted; cooldown > 0 then wait → harvestable again.

## Requirements

- FR-002, FR-004, FR-005, AC2, AC3, AC6
- Mines are **not** destroyed by a yield (unlike trees → stump).
- Same-frame last hits: **one** iron, one `yields_taken` increment.
- Completing hit player's inventory gets the iron when it can; else drop at the mine. Disconnect between hit and grant: drop at the mine; do not delete iron.
- Depleted: `can_harvest_from` false; SPACE hint off.
- Regen only on the host; clients follow T008.

## Acceptance

- **Given** a mine at `hits_required - 1`, **When** a Paper Pusher lands the last hit and has inventory space, **Then** they gain 1 metal and the mine remains with `hits_taken` 0.
- **Given** 5 completed yields, **When** the mine is inspected, **Then** it is depleted (depleted sprite) and further melee grants no iron.
- **Given** `regen_cooldown` 0 and a depleted mine, **When** time passes, **Then** it stays depleted.
- **Given** `regen_cooldown` > 0, **When** that time elapses on the host, **Then** the mine is active and harvestable.
- **Given** 8 distinct item types and no metal, **When** a yield completes, **Then** metal appears as a world pickup.
- **Given** two players' completing hits on the same frame, **When** the host resolves, **Then** exactly one iron is granted.

## Notes

Lockouts are T005. Placement is T006. Do not spend iron on buildings here (T007).
