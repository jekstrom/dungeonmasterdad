# T007: Verification harness

**Story**: US-034  
**Status**: Todo  
**Depends on**: T002–T005  
**Parallel**: no  
**Owner (after sign)**: QA / Gameplay

## Goal

Assert open/close via toggle path, both tabs, DM label set + TSB, Dad ten placeholders, tooltips present, and that activating a node does not change mana / unlock maps / spawn counts in this build.

## Files

- `test_harness/` (DM HUD style)

## Requirements

- AC1–AC10 smoke

## Acceptance

- **Given** the harness, **When** it runs, **Then** UI asserts pass and no gameplay side-effect asserts fire from node clicks.
