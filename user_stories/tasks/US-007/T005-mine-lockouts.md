# T005: Mine harvest lockouts

**Story**: US-007  
**Status**: Todo  
**Depends on**: T003  
**Parallel**: with T004

## Goal

Mine harvest uses the **same occupancy rules as trees** (US-006 T004). Only a Paper Pusher on **non-Fantasy** ground can hit an **active** mine that is also not Fantasy-claimed and not under an enabled building. The DM cannot harvest. Paper Pushers **may walk** Fantasy (US-003 T011); do **not** add a zone wall.

## Files

- `doodads/mine.gd` — before applying a hit: striker is `Player` not `DM`; striker world pos and mine world pos are not `FantasyZone.is_claimed_world`; mine cell not covered by an enabled building footprint (same approach as `TreeDoodad._is_under_building`). Depleted mines already refuse in T004.
- `zones/FantasyZone.gd` — `is_claimed_world` / `is_claimed_cell` (home ∪ pockets). No circle `Area2D`.
- `_globals/building_manager.gd` — `is_area_clear` already includes doodad layer **16** (US-006). Mines on layer 16 should block new footprints. Harvest still no-ops if a building already overlaps.
- `player/player.gd` — SPACE hint only when `is_harvest_prompt_target` (range + `can_harvest_from`), so Fantasy / depleted / DM / no-range hide the prompt.
- `test_harness/procedural_dungeon/us007_mine_lockout_test.gd` (+ `.tscn`) — Fantasy on player or mine: no hit; DM: no hit; building overlap: no hit; Reality mine: hit still works.

## Requirements

- FR-005, AC1 (negative)
- Player inside Fantasy swinging a mine outside Fantasy: no hit.
- Player outside Fantasy swinging a mine inside Fantasy: no hit.
- When a Fantasy pocket expires, an active mine there is harvestable again if the player is also outside Fantasy.
- Ghost buildings do not lock harvest.
- Mine overlapping Reality **growth** stays harvestable if PPs can stand on it (story edge). Do not require Reality claim to mine.

## Acceptance

- **Given** a Paper Pusher whose world position is Fantasy-claimed, **When** they melee an active mine, **Then** `hits_taken` is unchanged.
- **Given** an active mine whose position is Fantasy-claimed, **When** a Paper Pusher outside Fantasy melees it, **Then** `hits_taken` is unchanged.
- **Given** an enabled building overlapping a mine, **When** a Paper Pusher melees that mine, **Then** it does not harvest.
- **Given** the DM in range of an active Reality mine, **When** they melee, **Then** the mine is not harvested and SPACE is not shown for the DM.
- **Given** a Paper Pusher and mine both outside Fantasy with no building, **When** they melee, **Then** a hit still applies (T003).

## Notes

Do not implement gremlin theft (US-013). Tree lockouts stay as they are.
