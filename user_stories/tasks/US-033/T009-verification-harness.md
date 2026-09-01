# T009: Verification harness

**Story**: US-033  
**Status**: Done  
**Depends on**: T003–T007; re-check / extend after T010  
**Parallel**: no  
**Owner (after sign)**: QA / Gameplay

## Goal

Headless or harness asserts for shared vs isolated reveal, visit radius brush, marker rules, toggle, and late-join snapshot. Short two-window play pass.

## Files

- `test_harness/` (follow existing multiplayer HUD / zone harness style)

## Requirements

- AC1–AC12 smoke (AC12 after T010)
- Assert PP shared union; assert DM set disjoint growth; assert ally-always / enemy-on-reveal markers.
- After T010: revealed living tree/mine/wall tint visible; fogged hidden; stumps absent by default.

## Acceptance

- **Given** the harness, **When** it runs, **Then** shared/isolate/snapshot asserts pass without manual editor clicks.
