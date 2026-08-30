# T002: Convert paper into a blank form

**Story**: US-009  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T003 after T001 (different complete path; T003 must not consume paper)

## Goal

A Paper Pusher with ≥1 paper performs a **server-validated create-form** action: 1 paper consumed, 1 blank form granted (or dropped). Zero paper → reject. No building required (Office Max is US-010; IRS is for filing). No Reality grant.

## Files

- `_globals/player_manager.gd` — host `create_form(player_id) -> bool` (name as you like): `is_server`, player exists, `has_resources(paper, 1)`, `consume_resources` paper, `grant_item_or_drop` blank form at the player position. Erase paper keys at qty ≤ 0 (already true). Return false on reject.
- `player/player.gd` — owning client requests `rpc_id(1, ...)`; host maps sender like `request_interact`. Paper Pusher only; DM must fail. Optional: skip if `is_combat_locked()`.
- `player/scripts/player_idle_state.gd` / `player_walk_state.gd` — bind a **create-form** input. Do **not** overload factory `interact` (E) so wood deposit stays US-006. Suggested: inventory-use of paper that RPCs the host. Tests may call `PlayerManager.create_form` directly.
- `pickups/paper.tres` / `pickups/blank_form.tres` — consume/grant paths.
- `test_harness/procedural_dungeon/us009_create_form_test.gd` (+ `.tscn`)

## Requirements

- FR-001, FR-009, AC1, edge: 0 paper
- 1:1 only. Do not convert a stack in one press.
- Full inventory without a blank-form stack: paper is still consumed and the blank **drops** (`grant_item_or_drop`). Do not eat paper into the void.
- Host-authoritative. A client local `add_item_to_inventory` of a blank form must not stick on the host (same as wood).
- Do not require an IRS or factory in range.
- Do not start a fill channel (T003).

## Acceptance

- **Given** a Paper Pusher with 1 paper and inventory space, **When** they create a form, **Then** paper is 0 and blank form is 1.
- **Given** 0 paper, **When** they create a form, **Then** inventories are unchanged and the call fails.
- **Given** inventory full of a non-form item, **When** they create a form, **Then** paper decreases by 1 and a world drop of `blank_form.tres` is emitted.
- **Given** a DM, **When** create-form is requested, **Then** it fails.

## Notes

Fill is T003. If you add an InputMap action, keep the physical bind documented (US-006 bound E for `interact`). Default suggestion: reuse an unused action or inventory click on paper; do not make paper `auto_use`.
