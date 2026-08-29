# T010: Verification harness and independent test

**Story**: US-005  
**Status**: Todo  
**Depends on**: T003–T009  
**Parallel**: no

## Goal

Prove the independent test headless where possible, and list the two-window play pass.

## Files

- `test_harness/procedural_dungeon/us005_combat_loadout_test.gd` (+ `.tscn`) — Node script that quits on success (same pattern as US-001 T009)
- Optional shell wrapper matching `us001_run_harness.sh`

## Headless checks

- Magazine starts at configurable max (default 20); HUD/owner replica matches.
- Fire with ammo: one projectile, magazine −1; last staple: one shot then 0.
- Empty: no projectile; jam path invoked (or at least no spawn).
- Projectile dies on wall or max range; does not pass through walls.
- Host hit on a dummy hurtbox: damage once, projectile consumed.
- Building overlap: no building HP change.
- Melee: `melee_damage` applied, magazine unchanged, works at magazine 0.
- Same-frame melee + fire: melee only, magazine unchanged.
- Dead / building / attack-block state: neither attack.
- Client cannot decrement server magazine by predicting extra shots.

## Play pass (host + client, two windows)

- Fire at a dummy: projectile, HUD count, peer sees the shot and damage.
- Empty the mag: jam, no bolt. Melee still works (pencil sheet + ink slash).
- Same-frame mash: melee wins, no spend.
- Building is not damaged by staples. Combat still works in both zones.
- Staple-gun sheet on ranged, pencil sheet on melee; not a stretched sword.

## Requirements

- Independent Test section of US-005
- Testing skill: new tests under `test_harness/procedural_dungeon/` as Node + `.tscn` that quit on success

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** a two-window play of the independent test, **When** both roles watch fire and melee, **Then** both windows agree on damage and the owner cannot over-fire ammo.

## Notes

Do not require Office Max restock or the chainsaw. Harvest must not be required to pass this harness.
