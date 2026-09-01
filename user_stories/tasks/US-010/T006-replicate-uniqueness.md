# T006: Replicate uniqueness, HP, and restock

**Story**: US-010  
**Status**: Todo  
**Owner**: Gameplay  
**Depends on**: T003  
**Parallel**: no

## Goal

Uniqueness, HP/destruction, and restock (magazine + iron) are **host-authored**. Two players may restock in sequence; each magazine and iron spend is independent.

## Files

- Building spawn / HP / destroyed replication
- `player/player.gd` staple count + iron inventory replication
- Late join: current building (live or ruined), HP, owner magazines, iron

## Requirements

- FR-004, MR-001, MR-002, MR-003
- Client cannot create a second Office Max, force another player's mag to max, or spend iron they do not have.
- After restock, owning client HUD matches server staple count and iron.

## Acceptance

- **Given** two Paper Pushers restock in sequence, **When** each finishes, **Then** each magazine and iron spend is independent.
- **Given** a client requests a second Office Max or a free restock, **When** the host validates, **Then** it is rejected.
- **Given** a late joiner, **When** they spawn, **Then** they see the current Office Max state (live/ruined/HP) and correct staple/iron values.

## Notes

QA harness is T007.
