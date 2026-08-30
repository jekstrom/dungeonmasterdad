# T004: Harvest lockouts (Fantasy, building, DM)

**Story**: US-006  
**Status**: Done  
**Depends on**: T002  
**Parallel**: with T003

## Goal

Harvest only works for a Paper Pusher standing on **non-Fantasy** ground, swinging a **living** tree that is also not Fantasy-claimed and not under a placed building. The Dungeon Master cannot harvest. Paper Pushers **may walk** Fantasy (US-003 T011); this task must **not** add a zone wall or push-out.

## Files

- `doodads/tree.gd` — before applying a hit, host-check: striker is `Player` (not `DM`); striker world pos and tree world pos are not `FantasyZone.is_claimed_world`; tree cell is not covered by an enabled building footprint.
- `zones/FantasyZone.gd` — `is_claimed_world` / `is_claimed_cell` already exist (home ∪ pockets). Use them; do not query a circle `Area2D`.
- `_globals/building_manager.gd` — `is_area_clear` uses `collision_mask = 1`; tree `StaticBody2D` is **layer 16**, so buildings can sit on trees today. Either (a) include doodad/tree collision in the clear-area check so new placements prefer clear ground, and/or (b) reject harvest when an enabled building overlaps the tree cell. Story edge case: "Tree under a placed building: cannot be harvested; building placement should prefer clear ground." Do both if cheap: clear-area sees trees; harvest no-ops under a building that already exists.
- `test_harness/procedural_dungeon/us006_harvest_lockout_test.gd` (+ `.tscn`) — Fantasy home/pocket on player or tree: no hit; DM swing: no hit; building overlap: no hit; Reality/neutral tree: hit still works (T002).

## Requirements

- FR-001, FR-007, AC1 (negative), edge: tree under building
- Occupancy addendum: US-003 T011 **revoked** PP exclusion. FR-007's parenthetical "Paper Pushers cannot be there — US-003" is stale. Implement **harvest refusal**, not displacement.
- Trees inside Fantasy (home grew over them, blizzard pocket, etc.) MUST NOT take hits while claimed. When the pocket expires, a still-living tree becomes harvestable again if the player is also outside Fantasy.
- Player **inside** Fantasy swinging a tree **outside** Fantasy: no hit (harvester must not work from inside Fantasy).
- Player outside Fantasy swinging a tree inside Fantasy: no hit.
- Ghost (unenabled) building footprints do not lock harvest.
- Do not change skeleton/building occupancy rules.

## Acceptance

- **Given** a Paper Pusher whose world position is Fantasy-claimed, **When** they melee a living tree, **Then** `hits_taken` is unchanged.
- **Given** a living tree whose position is Fantasy-claimed, **When** a Paper Pusher outside Fantasy melees it, **Then** `hits_taken` is unchanged.
- **Given** an enabled building overlapping a tree, **When** a Paper Pusher melees that tree, **Then** it does not harvest.
- **Given** the DM in range of a living Reality tree, **When** they melee, **Then** the tree is not harvested.
- **Given** a Paper Pusher and tree both outside Fantasy with no building, **When** they melee, **Then** a hit still applies (T002).

## Notes

Do not implement US-007 mines. Do not destroy the building. Yield still T003: a locked tree must not yield from a rejected swing.
