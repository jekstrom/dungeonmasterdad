# T006: Spend feedback art

**Story**: US-054  
**Status**: Todo  
**Depends on**: T003 layout (where SP counter and toasts sit)  
**Owner**: Art  
**Parallel**: Gameplay can ship text cost/SP until this lands

## Goal

Ship the **concrete** spend/gate art in US-054 **Required New Art Assets**. Reuse US-034/035 panel, tabs, locked/available/owned frames, row marks, tooltip chrome, and node **icons**. Pixel style: DM HUD / existing Skill Tree icons.

## Files

- Suggested: `gui/dm/skill_tree/` (`sp_counter_plate.png`, `icon_skill_point.png`, `cost_badge_1.png` … `cost_badge_5.png`, overlays, toast bg + reason icons)

## Checklist (must deliver)

1. **SP counter plate** (header; holds pip + number)
2. **SP icon / pip** (16×16 or 32×32) — not the Dew can
3. Cost badges **1**, **2**, **3**, **5**
4. Node overlay **gated** (FL / ultimate prereq)
5. Node overlay **unaffordable** (gates OK, SP short)
6. Fail toast / banner 9-slice chrome
7. Fail toast icons: not enough SP, row gated, ultimate prereq, already owned
8. **Optional**: buy-success flash; row FL pip (10 / 50)

## Requirements

- US-054 Required New Art Assets table (items 1–13 required; 14–15 optional)
- FR-019, FR-020
- Do not redraw US-034/035 panel/tab/icon art

## Acceptance

- **Given** the checklist assets are imported, **When** the DM opens the Skill Tree, **Then** SP counter, cost badges, and gated/unaffordable overlays are visible and readable on both tabs.
- **Given** a rejected buy, **When** the toast shows, **Then** the matching reason icon + banner chrome appear without changing spend rules.
- **Given** art-only landing, **When** a node is clicked, **Then** spend still goes through T002/T003 (art does not grant ownership).
