# T002: DM tree nodes (3×3 + TSB)

**Story**: US-034  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T003  
**Owner (after sign)**: Gameplay

## Goal

On the **DM** tab, show **9 passives + ultimate TSB** in a readable 3×3 + ult layout. Rows: Lightning (Overcharged, Spark, Chain Lightning), Gremlins (Minions, Blind one-legged monkeys, Crib Death), Goblins (Challenge Rating, +1 Swords, Random Encounter). Labels match story copy. No gameplay apply.

## Files

- Skill tree panel from T001
- Optional data resource for node id / name / tooltip string

## Requirements

- FR-003, FR-004, AC4, AC9

## Acceptance

- **Given** the DM tab, **When** nodes are shown, **Then** all nine names + **TSB** appear in the specified row order.
- **Given** a node click, **When** resolved in this story, **Then** no spawn/spend/passive apply occurs.
