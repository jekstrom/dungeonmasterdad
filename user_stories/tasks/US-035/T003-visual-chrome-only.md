# T003: Visual chrome only (no apply)

**Story**: US-035  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T002  
**Owner (after sign)**: Gameplay

## Goal

Confirm Dad nodes still use locked/unlocked/owned **visual** states only. Clicks must not spend, unlock power, apply passives, or call US-021 activate.

## Files

- Dad node click handlers / US-034 chrome styles

## Requirements

- FR-005, AC5, AC6

## Acceptance

- **Given** a Dad node click, **When** resolved in this story’s build, **Then** mana, unlock maps, blizzard/fireball tunables, inventory slots, dash, Fantasy timers, and US-021 form are unchanged by that click.
