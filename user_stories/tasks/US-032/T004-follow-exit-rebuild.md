# T004: Forest follows exit rebuild

**Story**: US-032  
**Status**: Todo  
**Depends on**: T002, T003  
**Parallel**: no

## Goal

When generation or map apply moves the exit, clear the previous exit forest (trees + Skill Tree) and re-place for the new exit. Placement is host-authoritative and deterministic (shared seed from interior + dungeon + exit) so peers and late joiners match.

## Files

- `_globals/level_manager.gd` — `apply_map_interior`, replicate payload (`ex`/`ey`), tree scatter seed pattern
- Forest parent/group from T002/T003

## Requirements

- FR-003, FR-008, AC5, AC7, MR-001, MR-002
- No orphan forest at the old exit.
- Late join must rebuild or receive the same cells.

## Acceptance

- **Given** exit cell A with a forest, **When** exit becomes cell B and rebuild runs, **Then** no forest doodads remain keyed to A and forest + Skill Tree exist for B.
- **Given** two peers after host place, **When** forest cells are compared, **Then** they match.

## Notes

Mirror the deterministic hash style used by `_tree_scatter_seed` (distinct salt, e.g. `"exit_forest|..."`).
