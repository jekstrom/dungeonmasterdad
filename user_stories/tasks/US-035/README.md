# US-035 tasks: Dad Skill Tree content (UI only)

**Story**: [US-035.md](../../US-035.md)  
**Branch**: `035-dad-skill-tree-content`  
**Status**: Todo

Replace US-034 **Dad** placeholders with Frost / Fire / Control + **Dad All Powerful** labels, tooltips, and icons. **UI-only** (same as US-034). No spend/apply/US-021 activation. Markdown only until James signs — no Art/Gameplay handoff ping yet.

Open defaults: UI-only unless James overrides. Entry path unchanged.

## Order

T001 Dad labels/rows first (needs US-034 Dad tab). T002 tooltips with or right after T001. T003 chrome/states reuse check. T004 Art parallel after names stable. T005 harness last.

| ID | Task | Owner (after sign) | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-dad-labels-and-rows.md) | Dad 3×3 + ult labels; Frost/Fire/Control rows | Gameplay | US-034 Dad tab | |
| [T002](T002-dad-tooltips.md) | Tooltips with locked Dad copy | Gameplay | T001 | with T003 |
| [T003](T003-visual-chrome-only.md) | Locked/unlocked still visual-only; no apply | Gameplay | T001 | with T002 |
| [T004](T004-dad-tree-art.md) | Frost/Fire/Control marks + 9 named icons + Dad All Powerful ult | Art | T001 names | with Gameplay |
| [T005](T005-verification-harness.md) | Labels, tooltips, DM tab intact, no side effects | QA / Gameplay | T001–T003 | |

## Out of scope

- Passive apply, spend/unlock economy, US-021 form, DM tree edits, redrawing US-034 shared chrome.

## Independent test (story)

Dad tab shows James’s nine + Dad All Powerful with tooltips; DM tab unchanged; clicks do nothing mechanical.
