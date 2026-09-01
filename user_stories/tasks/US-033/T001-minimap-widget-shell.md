# T001: Mini-map widget shell

**Story**: US-033  
**Status**: Todo  
**Depends on**: —  
**Parallel**: no  
**Owner (after sign)**: Gameplay

## Goal

Add a bottom-right mini-map panel to **both** Paper Pusher and DM HUDs. Visible by default. Toggle with **`M`**. Empty/placeholder content OK. Must not block world click targeting (mouse filter discipline like existing HUD spacers).

## Files

- `gui/player/player_hud.tscn` / `player_hud.gd`
- `gui/dm/dm_hud.tscn` / `dm_hud.gd`
- Suggested: `gui/minimap/minimap_widget.tscn` + script shared by both

## Requirements

- FR-001, AC1, AC2
- Do not implement fog or markers here (T002+).

## Acceptance

- **Given** a PP or DM HUD, **When** the match HUD is shown, **Then** a bottom-right mini-map panel is visible.
- **Given** that panel, **When** the owner presses `M`, **Then** it toggles hidden/shown without breaking other HUD buttons.
