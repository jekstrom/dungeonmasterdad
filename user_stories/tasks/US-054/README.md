# US-054 tasks: Skill Tree skill-point spend

**Story**: [US-054.md](../../US-054.md)  
**Branch**: `054-skill-tree-spend`  
**Status**: Todo

Host-authoritative SP spend for **both** DM and Dad trees: col costs 1/2/3, Row2 FL gate, Row3 RL gate, ultimate needs one unlock per row + SP cost. Passive **effects** stay US-036–053.

Markdown only until James signs — no Art/Gameplay handoff ping yet.

## Order

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-sp-pool-and-income.md) | SP pool + income (+1 per FL up); replicate | Gameplay / Systems | FL signals | |
| [T002](T002-purchase-costs-and-gates.md) | Col costs, Row1–3 gates, ultimate prereq+cost; atomic spend | Gameplay | T001; US-034/035 UI | |
| [T003](T003-ui-feedback.md) | Wire clicks; fail reasons; SP display | Gameplay | T002 | |
| [T004](T004-ownership-for-passives.md) | Ownership feeds US-036–053; late-join snapshot | Gameplay | T002 | with T003 |
| [T005](T005-verification-harness.md) | Gate matrix + SP atomicity + multiplayer | QA / Gameplay | T002–T004 | |
| [T006](T006-spend-feedback-art.md) | Optional SP icon / fail flash | Art | T003 | optional |

## Out of scope

- Passive effect bodies; US-021 / TSB combat; refunds.
