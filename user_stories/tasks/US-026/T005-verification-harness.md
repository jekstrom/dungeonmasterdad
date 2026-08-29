# T005: Verification harness and independent test

**Story**: US-026  
**Status**: Todo  
**Depends on**: T002–T004  
**Parallel**: no

## Goal

Prove claim gating and the no-scan / no-replicate constraints headless where possible, and list the two-window play pass.

## Files

- `test_harness/procedural_dungeon/us026_ambient_vfx_test.gd` (+ `.tscn`) — Node script that quits on success (same pattern as US-001 T009)
- Optional shell wrapper matching `us001_run_harness.sh`

## Headless checks

- Reality-claimed nearby cell is a dust candidate; Fantasy-claimed is a sparkle candidate; unclaimed is neither.
- Claim change rebuilds the set without a full-map physics-frame scan.
- Occupancy queries unchanged (PP may walk Fantasy, buildings still reject, skeletons still follow US-001).
- No replicated particle-emitting property on the ambient owner.
- Convert puff assets are not the looping ambience strip.

## Play pass (host + client, two windows)

- Reality home: subtle infrequent dust, not a convert-puff loop.
- Walk into Fantasy home or pocket: dust stops, sparkles play; PP is not walled.
- Second window need not match burst timing; claim overlays still match.
- Convert a tile (if drift is on): puff is a one-shot on top of ambience.

## Requirements

- Independent Test section of US-026
- Testing skill: new tests under `test_harness/procedural_dungeon/` as Node + `.tscn` that quit on success

## Acceptance

- **Given** the harness, **When** it runs headless, **Then** it prints pass and exits 0.
- **Given** a two-window play, **When** both roles stand in Reality then Fantasy claim, **Then** each sees the right local ambience and occupancy is unchanged.

## Notes

Do not require blizzard slow or a game-over path. Do not fail the harness if burst RNG differs between windows.
