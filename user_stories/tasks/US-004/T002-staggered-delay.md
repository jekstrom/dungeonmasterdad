# T002: Per-tile random delay

**Story**: US-004  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T004

## Goal

Eligible tiles convert after a **per-tile random delay**, staggered so the whole region does not swap on one frame. A tile converts **at most once** until its owning claim changes. Pocket expire **cancels** pending Fantasy drift.

## Files

- Drift scheduler on the host (suggested: autoload or tile-art owner; share infrastructure with US-002 if it exists)
- Configurable delay range; suggested default **0.5s–8s** after a tile becomes eligible
- Listen to US-003 claim changes (home rebuild, pocket create/expire)

## Requirements

- FR-003, AC2, AC6, edge: home growth spike, short-lived pocket
- New eligible tiles (home grew, pocket appeared) each draw their own delay; no freeze of the whole set.
- Already Fantasy-presenting tiles that stay Fantasy-claimed do not re-roll or flicker.
- If a pocket expires (or claim otherwise leaves Fantasy) before the delay fires, cancel; do **not** apply Fantasy art after the claim is gone.
- **Perf**: schedule on claim/map change only. Do **not** scan every outside tile every physics frame.

## Acceptance

- **Given** many eligible outside tiles, **When** drift is running, **Then** they do not all swap on the same frame.
- **Given** an outside tile already on Fantasy presentation that remains Fantasy-claimed, **When** time passes, **Then** it does not flicker.
- **Given** a scheduled Fantasy drift, **When** the pocket expires before it fires, **Then** that drift is cancelled and Fantasy art is not applied.

## Notes

Do not apply sprites here (T003). Do not replicate here (T006). Delay RNG is host-side. Same delay range as US-002 unless tuned separately.
