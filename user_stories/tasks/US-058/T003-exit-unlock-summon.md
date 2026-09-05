# T003: First dungeon exit unlocks goblin summon

**Story**: US-058  
**Status**: Todo  
**Depends on**: US-015 exit flow, US-055 goblin HUD  
**Owner**: Gameplay  
**Parallel**: with T002

## Goal

Goblin summon (`DmAbilityCatalog.GOBLIN`) MUST require unlock id `goblin`. Grant it on the **first successful host dungeon exit** this match. Until then the HUD control is hidden or unusable and `try_cast` spends no mana.

After unlock, mana cost stays 20 (US-014) and placement stays US-055.

## Files

- `dm/dm_ability_catalog.gd`
- `_globals/dm_unlocks.gd` (or equivalent)
- Exit handling (`level_manager` / `DmManager` / US-015 exit accept)
- `gui/dm/dm_hud.gd`

## Requirements

- FR-004, FR-007, AC3, AC4, AC8

## Acceptance

- **Given** pre-exit, **When** the DM HUD is shown or a goblin cast is requested, **Then** the summon does not run and mana is unchanged.
- **Given** the host accepts the first exit, **When** unlock replicates, **Then** the DM can summon a goblin with enough mana; a second exit does not toggle the unlock off.
