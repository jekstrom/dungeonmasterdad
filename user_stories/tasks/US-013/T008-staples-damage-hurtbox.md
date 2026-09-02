# T008: Staples damage gremlin hurtbox

**Story**: US-013  
**Status**: Todo  
**Depends on**: T001; US-005 staple projectiles  
**Owner**: Gameplay  
**Parallel**: with T002

## Goal

Gremlin scene exposes a hurtbox/hitbox so US-005 staples deal damage and can kill (FR-012 / AC11). Death drops carried resources (AC5). Use existing monster HP / damage pipeline unless gremlin sets its own HP in-scene.

## Requirements

- FR-012, FR-006, AC5, AC11, MR-004

## Acceptance

- **Given** a PP fires staples that intersect the gremlin hurtbox, **When** the host resolves hits, **Then** HP drops and the gremlin can die; carried items drop; peers agree.
