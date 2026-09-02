# T001: Panel open/close and DM/Dad tabs

**Story**: US-034  
**Status**: Todo  
**Depends on**: existing `DmHud` / `SkillTreeDoodad`  
**Parallel**: no  
**Owner (after sign)**: Gameplay

## Goal

Keep the live open path (`SkillTreeDoodad` → `DmManager._show_skill_tree_hud` → `DmHud._toggle_skill_tree_hud`). Replace stub content with a panel that has **DM** and **Dad** tabs and reliable open/close (toggle + Esc if missing). PP HUD unchanged.

## Files

- `gui/dm/skill_tree.tscn` (+ script as needed)
- `gui/dm/dm_hud.gd` / `dm_hud.tscn`
- `doodads/skill_tree.gd` (entry only; do not redesign doodad)

## Requirements

- FR-001, FR-002, FR-010, AC1–AC3, AC10

## Acceptance

- **Given** DM interact on Skill Tree doodad, **When** toggle runs, **Then** the panel shows and exposes DM + Dad tabs.
- **Given** the panel is open, **When** toggled/Esc closed, **Then** it hides without breaking other DM HUD controls.
