# T001: Shared near-DM spawn picker

**Story**: US-055  
**Status**: Todo  
**Depends on**: DM body position; walkable/cliff map data  
**Owner**: Gameplay / Systems

## Goal

Host helper: given DM world/cell, return a random walkable spawn cell with Chebyshev distance in **[1, 3]** (Open defaults), soft inland bias, or failure if none. No instantiate here.

## Requirements

- FR-001, FR-002, FR-004–FR-006, AC5–AC7

## Acceptance

- **Given** a DM on open ground, **When** the picker runs many times, **Then** results stay in-band, walkable, vary, and prefer inland when both exist.
- **Given** no eligible cell, **When** picker runs, **Then** it reports failure (no silent origin fallback).
