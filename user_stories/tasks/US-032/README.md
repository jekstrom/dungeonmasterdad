# US-032 tasks: Generated dungeon exit forest

**Story**: [US-032.md](../../US-032.md)  
**Branch**: `032-dungeon-exit-forest`  
**Status**: Todo

Dense **TreeDoodad** forest + one **SkillTreeDoodad** immediately outside the procedural dungeon exit. Follows the exit when generation moves it. No trees on dungeon footprint. Markdown only until James signs — no Art/Gameplay/QA handoff yet.

## Order

T001 (pocket geometry + egress clear) first. T002 (dense trees) and T003 (Skill Tree) after T001; T003 can trail T002. T004 (rebuild / host sync) after place. T005 (US-024 sparse exclusion) with or right after T001/T002. T006 harness last.

| ID | Task | Depends on | Parallel |
|---|---|---|---|
| [T001](T001-exit-forest-pocket.md) | Exit forest pocket from live exit; egress clear; never dungeon | US-015 exit, US-024 bounds | |
| [T002](T002-dense-tree-placement.md) | Dense `TreeDoodad` fill in pocket | T001 | with T003 |
| [T003](T003-skill-tree-in-forest.md) | One Skill Tree in pocket; drop authored match source | T001 | with T002 |
| [T004](T004-follow-exit-rebuild.md) | Rebuild when exit moves; host-authoritative / shared seed | T002, T003 | |
| [T005](T005-sparse-scatter-exclusion.md) | US-024 sparse scatter excludes forest pocket | T001 | with T002 |
| [T006](T006-verification-harness.md) | Headless checks + play pass | T002–T005 | |

## Out of scope (stay in other stories)

- Sparse overworld tree density (US-024 T012).
- Harvest hits / wood (US-006).
- Skill HUD unlock contents (`DmManager` / DM HUD).
- Dungeon exit portal rules (US-015).
- Exit-room boss (US-017).

## Independent test (story)

Generate a dungeon: dense trees + one Skill Tree sit immediately outside the exit on outside cells only. Egress landing is clear. Move/regenerate exit: forest follows. Sparse trees elsewhere still appear and skip the pocket.
