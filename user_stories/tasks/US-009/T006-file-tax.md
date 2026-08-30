# T006: File a tax form at the IRS

**Story**: US-009  
**Status**: Todo  
**Depends on**: T004, T005  
**Parallel**: no (extends `Player.try_interact`)

## Goal

A Paper Pusher with a **tax form**, in range of an **enabled** IRS, **interacts (E)** to file: tax form consumed, Reality += tax amount (suggested **+50**). No IRS, ghost IRS, out of range, or 0 tax forms → fail, inventory unchanged. Tax-file Reality MUST be **strictly greater** than one paper-factory cycle (**+10**).

## Files

- `buildings/buildables/irs.gd` — `file_range` export (~64px, match `PaperFactory.deposit_range`). Host `try_file_tax(player_id) -> bool`: `is_operating()`, player in range, `has_resources` tax form, `consume_resources` 1 tax, `PlayerManager.update_reality_level(tax_amount)`. One form per interact.
- `player/player.gd` — extend `try_interact` / `_host_try_deposit_wood`: if an IRS file is possible, **file first**; else existing wood deposit. Do not deposit wood and file in one press. `can_prompt_building_interact` must show **E** when file is possible (`carried_count` tax form on clients — `has_resources` is server-only; paper deposit already uses `carried_count` for the hint).
- `_globals/player_manager.gd` — consume + `update_reality_level` only.
- `test_harness/procedural_dungeon/us009_file_tax_test.gd` (+ `.tscn`)

## Requirements

- FR-006, FR-009, AC5, AC6, AC7, MR-001
- Compare tax amount to **10**, not to smoke-factory +1. `tax_file_rl > 10`. Default 50.
- No IRS in tree / only ghost: file fails, tax form remains.
- Two players cannot file the **same** form instance: consume on host first; second file sees 0 tax forms (per-player inventory). A world-dropped tax pickup is one `ItemPickup`; do not file from the ground — player must carry it (gremlins later).
- IRS destroyed mid-interact (US-011 later): `is_operating()` false → fail, form remains. Handle missing node safely now.
- Standard filled forms do **not** file and do not grant extra RL at the IRS.
- Host-authoritative.

## Acceptance

- **Given** a Paper Pusher with 1 tax form in range of an enabled IRS and Reality 0, **When** they interact, **Then** tax form is 0 and Reality is 50 (or the configured tax amount).
- **Given** that amount, **When** compared to `10`, **Then** it is strictly larger.
- **Given** no enabled IRS, **When** they try to file, **Then** the tax form remains and Reality is unchanged.
- **Given** a ghost IRS or out-of-range player, **When** they interact, **Then** no consume and no RL.
- **Given** only a filled **standard** form, **When** they interact at the IRS, **Then** Reality does not change from filing.

## Notes

E hint: only when file can succeed (has tax form, in range, operating IRS), same honesty as tree SPACE after US-006/harvest reach work. Keep factory E when deposit is possible and file is not.
