# T006: Verification harness

**Story**: US-032  
**Status**: Done  
**Depends on**: T002–T005  
**Parallel**: no

## Goal

Headless (or harness) checks plus a short play pass that the exit forest is dense, outside-only, follows the exit, keeps egress clear, hosts one Skill Tree, and does not fight US-024 sparse scatter.

## Files

- `test_harness/` (follow existing US-024 tree scatter / dungeon harness style)
- Optional dump of pocket cells + exit cell for debug

## Requirements

- AC1–AC7
- Assert: zero forest trees on dungeon cells; Skill Tree count == 1 in pocket; egress cells empty; after fake exit move, old pocket empty / new pocket filled; sparse eligible ∩ pocket == ∅.

## Acceptance

- **Given** the harness seed, **When** it runs, **Then** the asserts above pass without manual editor clicks.
- **Given** a two-window play pass, **When** the DM exits, **Then** both see the same forest and can path out; Skill Tree prompt still works for the DM.

## Notes

No new art required. Do not implement Skill HUD content tests here.
