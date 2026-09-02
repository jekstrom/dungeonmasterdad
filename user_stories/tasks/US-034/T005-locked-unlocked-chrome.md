# T005: Locked / unlocked chrome only

**Story**: US-034  
**Status**: Todo  
**Depends on**: T002  
**Parallel**: with T004  
**Owner (after sign)**: Gameplay

## Goal

Visual locked vs unlocked states on nodes. No currency spend, no host unlock writes, no power grant. Mock which nodes look unlocked per Open defaults (document choice in PR).

## Files

- Node button/styles on skill tree panel

## Requirements

- FR-007, FR-008, AC8, AC9

## Acceptance

- **Given** locked and unlocked styled nodes, **When** rendered, **Then** they are visually distinct.
- **Given** a click on either state, **When** this story’s build runs, **Then** no gameplay unlock/spend/spawn occurs.
