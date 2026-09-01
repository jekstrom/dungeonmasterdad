# T003: Skill Tree in exit forest

**Story**: US-032  
**Status**: Done  
**Depends on**: T001  
**Parallel**: with T002

## Goal

Place exactly **one** `SkillTreeDoodad` (`doodads/skill_tree.tscn`) in the exit forest pocket, off the mandatory egress clear cells. Stop using the hand-placed `playground.tscn` Skill Tree as the match source once procedural place runs.

## Files

- `doodads/skill_tree.tscn` / `doodads/skill_tree.gd`
- `playground.tscn` — authored `SkillTree` instance
- Level / match bootstrap next to forest place

## Requirements

- FR-004, FR-005, AC3, AC4
- One per match; inside pocket; not dungeon; not west spawn strip.
- Interact / HUD open behavior stays existing (`DmManager` skill HUD) — do not redesign unlocks here (FR-009).

## Acceptance

- **Given** forest place, **When** skill trees in the match are counted, **Then** there is exactly one, in the pocket, not on an egress-clear cell.
- **Given** match start with procedural forest, **When** the old authored playground Skill Tree would conflict, **Then** it is removed, hidden, or superseded so peers do not see two.

## Notes

Prefer a pocket cell with a bit of surround trees so it reads as “in the woods.”
