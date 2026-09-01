# T006: Replicate uniqueness and magazines

**Story**: US-010  
**Status**: Todo  
**Owner**: Gameplay  
**Depends on**: T003  
**Parallel**: no

## Goal

Uniqueness and restock are **host-authored**. Two players may restock in sequence; each magazine is independent. Peers see the same single Office Max and the correct owner magazines.

## Files

- Building spawn / uniqueness replication (IRS pattern)
- `player/player.gd` staple count replication / `staple_count_changed` (US-005)
- Late join: current buildings + owner magazine

## Requirements

- FR-004, MR-001, MR-002
- Client cannot create a second Office Max or force another player's mag to max.
- After restock, owning client HUD matches server `staple_count`.

## Acceptance

- **Given** two Paper Pushers restock in sequence, **When** each finishes, **Then** each magazine is independent and full for that player only.
- **Given** a client requests a second Office Max, **When** the host validates, **Then** it is rejected and peers still see one.
- **Given** a late joiner, **When** they spawn, **Then** they see the current Office Max (if any) and correct staple counts.

## Notes

QA harness is T007.
