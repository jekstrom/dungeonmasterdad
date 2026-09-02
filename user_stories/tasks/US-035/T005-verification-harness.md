# T005: Verification harness

**Story**: US-035  
**Status**: Todo  
**Depends on**: T001–T003  
**Parallel**: no  
**Owner (after sign)**: QA / Gameplay

## Goal

Assert Dad labels + row order, tooltips, DM tab regression-free, open path unchanged, and node clicks cause no mechanical side effects in this build.

## Files

- Extend US-034 skill-tree harness if present; else `test_harness/` DM HUD style

## Requirements

- AC1–AC8 smoke

## Acceptance

- **Given** the harness, **When** it runs, **Then** Dad copy asserts pass, DM tab still matches US-034 names, and click side-effect asserts stay clean.
