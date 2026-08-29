# T001: Staple magazine and HUD

**Story**: US-005  
**Status**: Todo  
**Depends on**: none  
**Parallel**: no

## Goal

Each Paper Pusher has a **staple magazine** with a configurable max (default **20**). The owning client sees the count on the HUD with `sprites/staple_hud_icon.png`. Count is replicated to that player's client.

## Files

- `player/player.gd` / `player/player_state.gd` — per-player magazine int + max export
- `gui/hud.gd` — Paper Pusher HUD ammo
- `sprites/staple_hud_icon.png` — exists (32×32)
- `_globals/player_manager.gd` if the HUD already reads player state there

## Requirements

- FR-001, FR-007
- Max size configurable; suggested default 20.
- Count is per Paper Pusher, not a shared pool.
- HUD is for the owning client. Other peers do not need a foreign ammo counter.
- Do not restock here (US-010). Spawn/fill policy: start at max unless a later story says otherwise.

## Acceptance

- **Given** a Paper Pusher spawns, **When** HUD is shown, **Then** magazine is at max (default 20) with `staple_hud_icon.png`.
- **Given** the server magazine changes, **When** the owning client is in session, **Then** their HUD matches the server count.

## Notes

Do not fire projectiles here (T002). Do not implement Office Max.
