# US-026 tasks: Ambient zone particles

**Story**: [US-026.md](../../US-026.md)  
**Branch**: `026-ambient-zone-particles`  
**Status**: Todo

Subtle infrequent **dust** on Reality-claimed cells and **sparkles** on Fantasy-claimed cells. Local VFX only. Convert puffs stay US-002 / US-004.

## Order

Do T001 first (where they play, no full-map scan, occupancy untouched). Dust (T002) and sparkles (T003) can run in parallel after that. Local-only (T004) is a constraint on T002/T003. Harness (T005) closes.

| ID | Task | Depends on | Parallel |
|---|---|---|---|
| [T001](T001-claim-driven-local-vfx.md) | Claim-driven local ambience; no full-map scan; occupancy unchanged | US-001 T001, US-003 T001 | |
| [T002](T002-reality-dust.md) | Subtle infrequent dust in Reality claim | T001 | with T003 |
| [T003](T003-fantasy-sparkles.md) | Subtle infrequent sparkles in Fantasy claim | T001 | with T002 |
| [T004](T004-no-replicate-emitting.md) | Do not replicate particle emitting | T002, T003 | |
| [T005](T005-verification-harness.md) | Headless checks + two-window play pass | T002–T004 | |

## Out of scope (stay in other stories)

- Convert puffs (US-002 T005, US-004 T005).
- Tile art drift (US-002, US-004) and overlays (US-001 T003, US-003 T003).
- Occupancy, buildings, skeletons, PP walk (US-001, US-003 T011).
- Blizzard slow (US-017).
- Game over when one zone covers the map.

## Independent test (story)

Stand in Reality home: occasional grey/paper dust, not a convert puff. Walk into Fantasy home or a Fantasy pocket: dust stops, infrequent sparkles play. A second window need not match burst timing. Occupancy unchanged.
