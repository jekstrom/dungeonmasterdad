# T005: Host-authoritative use of an active cell

**Story**: US-030  
**Status**: Todo  
**Depends on**: T002, T004  
**Parallel**: T006 after this (hold vs tap)

## Goal

Pressing **that cell’s** hotkey (or clicking the cell) asks the host to **use the item in that active index**. Empty cell → no-op. Static cells cannot be used this way. Client `ItemData.use()` + local qty-- is **not** authority.

Instant items: one press → one host use. Channel items: T006 (this task may `begin_fill` on blank form as a tap-to-start if T006 is not in yet; prefer not to ship tap-to-complete-channel).

## Files

- `_globals/player_manager.gd` or `player/player.gd` — host `request_use_slot(slot_index)` / `use_active_slot(player_id, index)`: `index` 0–3 only; owner check (`get_remote_sender_id` == peer); empty → false; static row never used here. Dispatch by item path:
  - Blank form → existing `begin_fill` (type still chosen at start — keep a default or a tiny type arg; do **not** revive global R/T).
  - Tax form → existing IRS `try_file_tax` if in range, else no-op (form kept).
  - Other active items → run the **host-safe** effect those items already have (dice / Dew that are in-bag). Do not invent new effects.
- `player/scripts/player_idle_state.gd` / `player_walk_state.gd` / DM idle+walk — on `inv_slot_n` pressed, owner `rpc_id(1, n)` (or local if host). Combat/death/building lock: no use (US-005 / US-009 lockouts).
- `player/inventory/inventory_slot_ui.gd` — remove client qty decrement. Optional: click active cell = same as hotkey (host request). Static click: no use.
- `test_harness/procedural_dungeon/us030_use_slot_test.gd` (+ `.tscn`) — put a blank form in active 0 vs 2; using slot 2 starts fill on **that** stack; empty slot 1 does nothing; static wood in bottom row is not used by `use_active_slot`.

## Requirements

- FR-004, FR-006, AC3, AC5, AC6
- Hotkeys bind to **cells**. After a later swap (T007), the same key uses whatever is now in that cell.
- Host-only consume/effect. A client calling `ItemData.use()` must not change host qty.
- PP and DM both send `use_active_slot` for their peer id.

## Acceptance

- **Given** a blank form in active slot 2, **When** slot 2 is used, **Then** fill targets that cell’s item (blank count decreases only on successful complete in T006; this task may only **start** fill).
- **Given** active slot 1 empty, **When** its hotkey fires, **Then** inventory is unchanged.
- **Given** wood in a static cell, **When** `use_active_slot` is called with a static index, **Then** it fails and wood is unchanged.

## Notes

Hold-to-channel is T006. Until then, do not complete a channel on a single tap if you can avoid it. Tax file via slot is “use tax form” — IRS range still required (US-009); interact remains the world key after T004, but using the tax **item** may also file (story: activate that cell). Prefer one path: slot use **or** interact, not both consuming twice — if both exist, host consume-once.
