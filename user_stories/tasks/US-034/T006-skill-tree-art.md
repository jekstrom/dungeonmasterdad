# T006: Skill Tree art (specific deliverables)

**Story**: US-034  
**Status**: Todo  
**Depends on**: T001; refine after T002 labels  
**Parallel**: with Gameplay  
**Owner (after sign)**: Art

## Goal

Ship the **concrete** Skill Tree UI art listed in US-034 **Required New Art Assets**. Pixel style matching existing DM HUD. Gameplay may keep text/color placeholders until these land. **UI chrome only** — no gameplay mechanics.

## Files

- Suggested: `gui/dm/skill_tree/` or `sprites/skill_tree/` (panel, tabs, frames, icons, tooltip)
- Wire into `gui/dm/skill_tree.tscn` / theme (Gameplay can hook paths)

## Checklist (must deliver)

1. DM Skill Tree **panel / frame chrome** (fits DmHud; ~stub 467×436 readable)
2. **DM** tab — idle + active
3. **Dad** tab — idle + active
4. Node frames — **locked**, **unlocked/available**, **owned/selected** (3 states min)
5. Row/category marks — **Lightning**, **Gremlins**, **Goblins**
6. Nine named DM passive icons (32×32 or 64×64):
   - Overcharged
   - Spark
   - Chain Lightning
   - Minions
   - Blind one-legged monkeys
   - Crib Death
   - Challenge Rating
   - +1 Swords
   - Random Encounter
7. DM ultimate icon — **TSB**
8. Dad: **9** placeholder passive icons + **1** placeholder ult (generic Dad/placeholder OK; reuse+tint allowed)
9. **Tooltip panel chrome** (bg + optional arrow)
10. **Optional** connector lines between nodes if layout needs them

## Requirements

- FR-009; full US-034 **Required New Art Assets** table
- Keep UI-only scope (no spend/spawn art that implies live unlock VFX unless purely cosmetic idle)

## Acceptance

- **Given** the checklist assets are imported, **When** DM opens the Skill Tree, **Then** panel, tabs, three node states, row marks, all 9+1 DM icons (named), Dad placeholders, and tooltip chrome replace programmer placeholders.
- **Given** art-only landing, **When** a node is clicked, **Then** still no spend/unlock/spawn from this story (Gameplay scope unchanged).
