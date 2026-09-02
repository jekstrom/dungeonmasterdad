# US-034 tasks: DM Skill Tree UI (UI only)

**Story**: [US-034.md](../../US-034.md)  
**Branch**: `034-dm-skill-tree-ui`  
**Status**: Todo

Replace the stub `gui/dm/skill_tree.tscn` with **DM** + **Dad** tabs, **3×3 + ultimate** each, hover tooltips. **No** spend, unlock power, or spawns. Markdown only until James signs — no Art/Gameplay handoff ping yet.

Defaults to confirm are in the story **Open defaults** table. Entry point today: Skill Tree doodad → `DmManager._show_skill_tree_hud` → `DmHud._toggle_skill_tree_hud`.

## Order

T001 shell/tabs first. T002 DM nodes + copy. T003 Dad placeholders parallel after T001. T004 tooltips after nodes exist. T005 locked/unlocked chrome with T002/T003. T006 art after labels stable. T007 harness last.

| ID | Task | Owner (after sign) | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-panel-tabs-open-close.md) | Panel open/close + DM/Dad tabs on existing HUD entry | Gameplay | existing DmHud / doodad | |
| [T002](T002-dm-tree-nodes.md) | DM 3×3 + TSB labels (Lightning/Gremlins/Goblins rows) | Gameplay | T001 | with T003 |
| [T003](T003-dad-tree-placeholders.md) | Dad 9 + ult placeholders | Gameplay | T001 | with T002 |
| [T004](T004-node-tooltips.md) | Hover/focus tooltips name + short text | Gameplay | T002, T003 | |
| [T005](T005-locked-unlocked-chrome.md) | Locked vs unlocked visuals only (no spend) | Gameplay | T002 | with T004 |
| [T006](T006-skill-tree-art.md) | Specific panel/tabs/node-states/icons/tooltip art checklist | Art | T001; refine after T002 | with Gameplay |
| [T007](T007-verification-harness.md) | Open/close, tabs, labels, tooltips, no gameplay side effects | QA / Gameplay | T002–T005 | |

## Out of scope

- Passive apply, currency spend, unlock gates, TSB/minion spawns.

## Independent test (story)

DM opens Skill Tree from doodad: DM + Dad tabs; DM nodes named per James; tooltips on hover; Dad placeholders; close works; no spawns/spend.
