# T002: Purchase costs and gates

**Story**: US-054  
**Status**: Todo  
**Depends on**: T001; node ids from US-034/035 / SKILL_TREE_PASSIVES.md  
**Owner**: Gameplay

## Goal

Host `try_purchase(tree, node_id)` using the **Node catalog**: col costs 1/2/3; Row2 FL≥10; Row3 FL≥50; Row1 ungated by FL; **no Reality Level gate**; ultimate needs ≥1 owned in each row on **that** tree + **5** SP; already-owned reject; insufficient SP reject; atomic SP+own; serialize double-click; no refunds.

Replace any live click-to-own (`SignalBus.unlock_skill` granting ownership) with this API.

## Requirements

- FR-002–FR-009, FR-015–FR-017, FR-021, FR-023
- AC4–AC17, AC21, AC23

## Acceptance

- **Given** each locked rule case in Independent Test, **When** purchase runs on the host, **Then** accept/reject matches US-054 (Row3 gated by FL, not RL; shared costs on both trees; DM ult prereq ignores Dad rows).
- **Given** two buys of the same node in one frame, **When** the host serializes, **Then** at most one success.
- **Given** a Paper Pusher, **When** they would request a spend, **Then** the host ignores it.
