# US-033 tasks: Mini-map for all players

**Story**: [US-033.md](../../US-033.md)  
**Branch**: `033-minimap`  
**Status**: Signed — in progress

Corner mini-map for every player. **Shared PP fog** (`pp_shared_reveal`) vs **private DM fog** (`dm_reveal`). Visit-radius reveal (Chebyshev 3). James signed at `219629e`; Art + Gameplay kicked off. Defaults in the story **Open defaults** table are locked unless overridden. **Scope add:** revealed-cell **trees**, **mines**, and **dungeon wall** silhouette (T010) from James on PR #14 (`5c1da01`).

## Order

T001 shell first. T002 grid/fog paint next. T003 (PP shared) and T004 (DM private) in parallel after T002. T005 content (zones/buildings) and T006 markers after reveal sets exist. T007 late-join with T003/T004. T008 art can start after T001 (chrome) and refine pips after T005/T006/T010. T009 harness covered core fog; extend or re-run for T010. T010 (trees/mines/walls) after T002 + reveal gate.

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-minimap-widget-shell.md) | Corner widget + `M` toggle on PP + DM HUDs | Gameplay | — | |
| [T002](T002-cell-grid-and-fog-paint.md) | Interior cell grid + fog vs revealed paint | Gameplay | T001, US-024 bounds | |
| [T003](T003-pp-shared-reveal.md) | Host `pp_shared_reveal` + visit radius + replicate to PPs | Gameplay / Systems | T002 | with T004 |
| [T004](T004-dm-private-reveal.md) | Host `dm_reveal` isolated from PP set | Gameplay / Systems | T002 | with T003 |
| [T005](T005-zones-and-buildings.md) | Reality/Fantasy washes + building markers on revealed cells | Gameplay | T003 or T004 | |
| [T006](T006-player-markers.md) | Ally/enemy marker rules per story defaults | Gameplay | T003, T004 | |
| [T007](T007-late-join-snapshot.md) | Full reveal snapshot on late join | Gameplay | T003, T004 | |
| [T008](T008-minimap-art-chrome.md) | Frame chrome + fog/zone tints + pips | Art | T001 (chrome); T005/T006 for final pips | with Gameplay after T001 |
| [T010](T010-trees-mines-dungeon-walls.md) | Living trees + mines + dungeon wall tint on revealed cells | Gameplay | T002; T003 or T004 | with T008 |
| [T009](T009-verification-harness.md) | Headless + two-window play pass | QA / Gameplay | T003–T007; extend for T010 | |

## Out of scope

- LOS occlusion, sticky pings, monster icons, zoom/pan, click-to-move.
- World-space fog hiding actors.

## Independent test (story)

PP A explores; PP B sees the same reveal. DM explores separately; sets stay isolated. Markers, buildings, trees, mines, and dungeon walls follow the defaults table. `M` toggles. Late-join PP gets shared snapshot.
