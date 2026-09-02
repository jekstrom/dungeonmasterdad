# T003: Pathing and target preference

**Story**: US-013  
**Status**: Todo  
**Depends on**: T002  
**Owner**: Gameplay

## Goal

Gremlin pathfinds to pickups. When multiple piles exist, prefer resources near factories and the IRS (FR-007). May enter Reality Zone (AC7).

## Requirements

- FR-007, AC1, AC7

## Acceptance

- **Given** two piles (one by a factory, one far), **When** an empty gremlin chooses, **Then** it prefers the near-factory/IRS pile when reachable.
