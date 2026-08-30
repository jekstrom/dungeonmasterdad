# T003: Fill-out channel (stand still, interrupt-safe)

**Story**: US-009  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: after T001; T004 adds Reality on the same complete

## Goal

A Paper Pusher with a **blank form** starts a fill, choosing **standard** or **tax** at start. They must **stand still** for a configurable channel (default **3s** standard, **6s** tax). On success the blank becomes the filled item of that type. Interrupt (move, damage, death) does **not** consume the blank and must not double-complete. **No Reality Level** in this task (T004).

## Files

- `player/player.gd` (or a small `player/scripts/form_fill.gd` used by Player) — host state: filling bool, type, elapsed, token/id. `request_begin_fill(type)` RPC; host rejects if not server, not PP, no blank form, already filling, combat-locked, or invalid type. Each physics tick on the host: if the filler moved beyond a small epsilon, **cancel**. `take_damage` / death / respawn **cancel**. On elapsed ≥ duration, `_complete_fill` once (token): `consume_resources` 1 blank, `grant_item_or_drop` filled or tax. Ignore a second complete for the same token.
- `_globals/player_manager.gd` — consume/grant only; keep fill timing on the player node so move/damage are local to that body.
- `player/scripts/player_idle_state.gd` / `player_walk_state.gd` — start fill (two actions or one action + type argument). Walk should still cancel via the move check even if they press the stick.
- Local-only progress: a bar on the filling player (same overlay idea as factory/mine bars, or a Label/ColorRect on the local Player). Do not require other peers to simulate the bar; host can RPC `fill_progress` to the owner if needed. Hide when not filling.
- `test_harness/procedural_dungeon/us009_fill_channel_test.gd` (+ `.tscn`)

## Requirements

- FR-002, FR-003, FR-009, AC2, AC8
- Type is chosen **when fill-out starts** (story assumption). Cannot switch type mid-channel; cancel first.
- Stand still: any meaningful `global_position` change or non-zero move input cancels. Snapping from `enforce_body_interior` should not false-cancel if you use a threshold (suggested 2–4 px).
- Damage and death cancel; blank remains.
- Two complete calls the same frame → one filled item.
- Filling does not consume the blank until success (so interrupt cannot lose the form).
- DM cannot fill. Combat lock: do not start; cancel if combat starts.
- Do not grant Reality here.

## Acceptance

- **Given** a Paper Pusher with a blank form, standing still, **When** they start a standard fill and `interval` elapses with no move/damage, **Then** blank is 0 and filled standard is 1.
- **Given** the same setup for tax, **When** the tax duration elapses, **Then** blank is 0 and tax form is 1.
- **Given** a fill in progress, **When** the player moves, takes damage, or dies, **Then** they still have the blank and have no filled/tax item from that channel.
- **Given** a completed fill, **When** complete is invoked again with the same token, **Then** inventory does not gain a second filled form.

## Notes

Reality on standard vs tax is T004. Default durations 3s / 6s as `@export` knobs. Tests may set duration to ~0.05s and `_process` that delta rather than waiting real time. Local SPACE/E hints: do not show harvest SPACE as “fill” — use a distinct prompt or the progress bar only.
