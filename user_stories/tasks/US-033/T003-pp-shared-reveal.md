# T003: Paper Pusher shared reveal

**Story**: US-033  
**Status**: Todo  
**Depends on**: T002  
**Parallel**: with T004  
**Owner (after sign)**: Gameplay / Systems

## Goal

Host maintains **`pp_shared_reveal`**. Each living PP contributes a Chebyshev **r=3** brush around their cell every move/tick as needed. Sticky for the match. Replicate to all PP clients. Never write DM reveals into this set.

## Files

- Host map/fog owner (new autoload or `LevelManager` / `PlayerManager` neighbor)
- `SignalBus` or RPC snapshot/delta
- PP mini-map data source

## Requirements

- FR-003, FR-004, FR-008, AC3, AC5, MR-001

## Acceptance

- **Given** PP A walks into new cells, **When** PP B’s map updates, **Then** B sees those cells revealed without walking them.
- **Given** only DM movement, **When** PP maps update, **Then** `pp_shared_reveal` does not grow from the DM.
