# T002: Per-tile random delay

**Story**: US-002  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T004

## Goal

Eligible tiles convert after a **per-tile random delay**, staggered so the whole region does not swap on one frame. A tile converts **at most once** until its owning claim changes. Pocket expire **cancels** pending Reality drift.

## Files

- Drift scheduler on the host (suggested: autoload or tile-art owner)
- Configurable delay range; suggested default **0.5s–8s** after a tile becomes eligible
- Listen to US-001 claim changes (home rebuild, pocket create/expire)

## Requirements

- FR-003, FR-004, AC2, AC4, edge: home growth spike, short-lived pocket
- New eligible tiles (home grew, pocket appeared) each draw their own delay; no freeze of the whole set.
- Already Reality-presenting tiles that stay Reality-claimed do not re-roll or flicker.
- If a pocket expires (or claim otherwise leaves Reality) before the delay fires, cancel; do **not** apply Reality art after the claim is gone.

## Acceptance

- **Given** many eligible outside tiles, **When** drift is running, **Then** they do not all swap on the same frame.
- **Given** an outside tile already on Reality presentation that remains Reality-claimed, **When** time passes, **Then** it does not flicker.
- **Given** a scheduled Reality drift, **When** the pocket expires before it fires, **Then** that drift is cancelled and Reality art is not applied.

## Notes

Do not apply sprites here (T003). Do not replicate here (T006). Delay RNG is host-side.
