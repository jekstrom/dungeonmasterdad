# US-059 tasks: DM wizard sprite sheets (walk, melee, cast)

**Story**: [US-059.md](../../US-059.md)  
**Branch**: (not started)  
**Status**: Signed — ready for Art/Gameplay

James signed at `08441ab` and asked to **implement**. **Art pipeline lock:** single frames / 1-row strips + solid non-green BG → script-stitch (no full sheet/grid prompts). **Style lock:** smooth/subtle deltas; quiet idle breath; no in-clip hand item-swaps; no green/near-green fringe. **Staged:** James approves **walk-down** strip first (L/R feet only; no flip; staff same hand; no color drift). Replace the DM’s `PlayerSprite02` body with 128×128 3-dir wizard sheets: idle, walk, staff melee, d20 cast. Red robe, brown hat, green Dew can on the hip. Side faces right; engine flips left.

## Order

Art (T001) first. Wire locomotion/melee (T002) as soon as idle/walk/attack exist. Cast (T003) needs the cast sheet + targeting hook. Harness last.

| ID | Task | Owner | Depends on | Parallel |
|---|---|---|---|---|
| [T001](T001-wizard-sheets.md) | Walk-down strip OK first → then frames/strips → script-stitch four 512×384 sheets | Art | — | |
| [T002](T002-wire-idle-walk-attack.md) | Point `dm.tscn` at idle/walk/attack; 4-frame clips | Gameplay | T001 | |
| [T003](T003-wire-cast.md) | Play `cast_*` while targeting; restore idle/walk after | Gameplay | T001, T002 | |
| [T004](T004-verification-harness.md) | Sheet size + clip names + targeting uses cast | QA / Gameplay | T002, T003 | |

## Independent test

Host as DM: idle wizard, walk all facings (left = flipped side), staff melee, d20 cast while a reticle is up. Client sees the same body.
