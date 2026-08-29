# T004: Verification harness and independent test

**Story**: US-027  
**Status**: Todo  
**Depends on**: T002, T003  
**Parallel**: no

## Goal

Prove telegraph → piercing stream → DM hit headless, plus a two-window play pass.

## Files

- `test_harness/procedural_dungeon/us027_carbonated_jet_test.gd` (+ `.tscn`) — quit on success (US-001 T009 pattern)

## Headless checks

- Telegraph exists before the stream.
- Stream is piercing and host-hit on a dummy DM hurtbox in the lane.
- Death during telegraph: no stream.
- Jet scene is not `baja_boss_blast` and not a fountain splash.

## Play pass (host + client)

- Readable arm-point tell, neon stream, DM can be hit. Peer matches. Distinct from blast spit.

## Requirements

- Independent Test section of US-027

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** two windows, **When** Jet plays, **Then** both see the same lane and hit.

## Notes

Do not require the US-028 fountain, Sugar Rush, cozy, cube, or fireball.
