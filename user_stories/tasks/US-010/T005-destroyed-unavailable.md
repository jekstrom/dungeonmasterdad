# T005: Destroyed Office Max unavailable

**Story**: US-010  
**Status**: Todo  
**Owner**: Gameplay  
**Depends on**: T003  
**Parallel**: no

## Goal

If Office Max is **destroyed** (US-011), restock is unavailable until it is **rebuilt**. This story only needs the restock gate + unique slot freeing; not goblin AI.

## Files

- `buildings/building.gd` / Office Max enabled flag / death
- Building manager uniqueness: destroyed instance no longer counts as the live unique, so a rebuild can place again

## Requirements

- AC6
- Disabled / destroyed: interact must not fill magazines.
- After destroy, uniqueness allows a new placement (still max one enabled).
- Do not implement goblin raid pathing or HP tuning (US-011 owns raids; suggested Office Max HP is noted there).

## Acceptance

- **Given** Office Max is destroyed, **When** players try to restock, **Then** restock fails and magazines are unchanged.
- **Given** Office Max was destroyed, **When** a legal rebuild is placed, **Then** restock works again on the new enabled building.

## Notes

Do not start US-011 work here. Harness can fake destroy/disable without goblins.
