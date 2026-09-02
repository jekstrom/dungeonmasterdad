# T001: Dad labels and Frost/Fire/Control rows

**Story**: US-035  
**Status**: Todo  
**Depends on**: US-034 Dad tab shell  
**Parallel**: no  
**Owner (after sign)**: Gameplay

## Goal

On the **Dad** tab in `gui/dm/skill_tree`, replace placeholders with the nine passives + **Dad All Powerful** in 3×3 + ult order (Frost / Fire / Control rows). Show row/category marks (text OK until T004 art). Do not change DM tab content or open path.

## Files

- `gui/dm/skill_tree.tscn` / Dad tab scripts or data resources

## Requirements

- FR-001, FR-002, FR-003, FR-006, FR-007, AC1, AC2, AC7, AC8

## Acceptance

- **Given** Dad tab, **When** opened, **Then** labels match US-035 Dad tree content (no `Dad Passive N` placeholders).
- **Given** DM tab, **When** opened, **Then** US-034 DM names remain.
