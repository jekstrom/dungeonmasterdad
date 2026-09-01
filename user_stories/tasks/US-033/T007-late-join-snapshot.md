# T007: Late-join reveal snapshot

**Story**: US-033  
**Status**: Todo  
**Depends on**: T003, T004  
**Parallel**: no  
**Owner (after sign)**: Gameplay

## Goal

On late join, host sends the full role-appropriate reveal set so the joiner’s first paint matches peers (not empty fog).

## Files

- Fog owner RPCs / join handshake
- Existing late-join patterns (zone / unlock snapshots)

## Requirements

- FR-009, AC10, AC11

## Acceptance

- **Given** a non-empty `pp_shared_reveal`, **When** a PP late-joins, **Then** their mini-map matches that set on first paint.
- **Given** a non-empty `dm_reveal`, **When** the DM late-joins, **Then** their mini-map matches that set on first paint.
