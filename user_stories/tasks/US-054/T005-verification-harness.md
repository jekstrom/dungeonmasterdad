# T005: Verification harness

**Story**: US-054  
**Status**: Todo  
**Depends on**: T002–T004  
**Owner**: QA / Gameplay

## Goal

Headless matrix covering: start SP 0; +1 SP per 10 FL; RL does **not** grant SP or gate; costs 1/2/3; Row1 open at FL 0; Row2 FL≥10; Row3 FL≥50; insufficient SP; double-buy; both trees; shared pool; ultimate prereq per-tree; ultimate 5 SP; atomicity; late-join snapshot; PP cannot spend.

## Requirements

- AC1–AC23, MR-001–MR-003

## Acceptance

- **Given** the harness, **When** it runs, **Then** gate/cost/income/atomicity/late-join asserts pass without manual editor clicks.
