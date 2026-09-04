# US-054 tasks: Skill Tree skill-point spend

**Story**: [US-054.md](../../US-054.md)  
**Branch**: `054-skill-tree-spend`  
**Status**: Todo

Host-authoritative SP spend for **both** DM and Dad trees: col costs 1/2/3, Row2 FL≥10, Row3 FL≥50 (no Reality Level gate), ultimate needs one unlock per row + 5 SP. Shared SP pool starts at 0; +1 SP per +1 FL. Passive **effects** stay US-036–053.

Markdown only until James signs — no Art/Gameplay handoff ping yet.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-sp-pool-and-income.md) | SP pool + income (+1 per FL up); replicate; no RL income | Gameplay / Systems | FL signals | |
| [T002](T002-purchase-costs-and-gates.md) | Catalog, col costs, Row1–3 FL gates, ultimate prereq+cost; atomic spend | Gameplay | T001; US-034/035 UI | |
| [T003](T003-ui-feedback.md) | Wire clicks; fail reasons; SP + cost display; chrome refresh | Gameplay | T002 | T006 art can land after |
| [T004](T004-ownership-for-passives.md) | Ownership feeds US-036–053; late-join snapshot; persist death | Gameplay | T002 | with T003 |
| [T005](T005-verification-harness.md) | Gate matrix + SP atomicity + both trees + late join | QA / Gameplay | T002–T004 | |
| [T006](T006-spend-feedback-art.md) | SP counter, cost badges, gated/unaffordable overlays, fail toasts | Art | T003 layout | after T003; required |

## Out of scope

- Passive effect bodies; US-021 / TSB combat; refunds.
- Reality Level as a Skill Tree purchase gate or SP source.
- Redraw of US-034/035 panel/tab/icon art.
