# T002: Wire Baja Blast boss sheet

**Story**: US-017  
**Status**: Todo  
**Depends on**: T001  
**Parallel**: with T003

## Goal

Wire the boss at **128×128**, **3 directions** (S, N, E; flip E for W). Anims: idle, wander, attack, blast, die. Art is expanding `monsters/baja_boss.png`; **do not wait** on the full sheet — spawn a **south placeholder**.

## Files

- `monsters/baja_boss.png` — exists and is expanding
- New boss scene/script under `monsters/` (goblin / `enemy.gd` as the combat pattern, larger cell)
- Do not reuse the 32×32 can (`pickups/bajablast/bajablast.png`) as the boss body

## Requirements

- Required New Art Assets table in US-017
- 128×128 cells so it reads larger than a 64 goblin without a new camera.
- Missing N/E/W or extra anims: keep facing south / idle until those frames exist.
- Don't block T001 spawn on a complete strip.

## Acceptance

- **Given** the boss is spawned, **When** a peer looks at it, **Then** they see the baja boss art (south placeholder is enough), not the Dew can and not a stretched goblin.
- **Given** only south frames exist, **When** the boss wanders or attacks, **Then** it still plays with the placeholder instead of waiting on the full sheet.

## Notes

Combat state machine is T003. Can pickup art is T004.
