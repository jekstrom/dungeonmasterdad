# T007: Move speed 2× baseline

**Story**: US-013  
**Status**: Todo  
**Depends on**: T001  
**Owner**: Gameplay  
**Parallel**: with T002

## Goal

Set gremlin move speed to **2×** the pre-fix placeholder baseline (the speed the goblin-prefab gremlin summon used). Host-authoritative; peers see matching locomotion (FR-010 / AC9).

## Requirements

- FR-010, AC9, FR-006

## Acceptance

- **Given** a spawned gremlin and the recorded baseline speed, **When** it moves, **Then** its speed is 2× baseline (± small float tolerance in harness).
