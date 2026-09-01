# T005: Destroyed / ruined Office Max

**Story**: US-010  
**Status**: Todo  
**Owner**: Gameplay  
**Depends on**: T001, T003  
**Parallel**: no

## Goal

At **0 HP**, Office Max is destroyed: show **ruined** art, restock unavailable until **rebuilt**. Unique slot frees so a rebuild can place. Goblin AI stays US-011; this task is HP death → ruin + restock gate.

## Files

- `buildings/building.gd` destroyed / HP
- Office Max scene — swap to T001 ruined sprite on destroy
- Building manager uniqueness after destroy

## Requirements

- FR-006, AC7, MR-003
- 0 HP: destroyed, ruined presentation, interact must not fill magazines or spend iron.
- After destroy, uniqueness allows a new placement (still max one enabled).
- Do not implement goblin raid pathing (US-011).

## Acceptance

- **Given** Office Max reaches 0 HP, **When** destruction resolves, **Then** peers see ruined art and restock fails.
- **Given** Office Max was destroyed, **When** a legal rebuild is placed, **Then** live art returns and restock works again.

## Notes

Harness can fake damage to 0 without goblins.
