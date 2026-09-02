# T003: Pathing, targets, and flee

**Story**: US-013  
**Status**: Todo  
**Depends on**: T002  
**Owner**: Gameplay

## Goal

Gremlin pathfinds to pickups on **walkable** navigation only (FR-011 / AC10) — no cliffs, off-map, or permanently stuck off-navmesh. When multiple piles exist and the gremlin is not fleeing, prefer resources near factories and the IRS (FR-007). May enter Reality Zone (AC7).

**Always flee Paper Pushers** (FR-013 / AC12): while any PP is within flee range, flee overrides acquire/path-to-pile; still walkable-only. Flee does not delete a carried item (drop timer / damage / death still apply).

## Requirements

- FR-007, FR-011, FR-013, AC1, AC7, AC10, AC12

## Acceptance

- **Given** two piles (one by a factory, one far) and no PP in flee range, **When** an empty gremlin chooses, **Then** it prefers the near-factory/IRS pile when reachable on walkable pathing.
- **Given** a nav edge / cliff / off-map cell, **When** the gremlin paths, **Then** it never steps there or wedges permanently off-navmesh.
- **Given** a PP in flee range, **When** AI updates, **Then** the gremlin flees on walkable cells and does not walk into the PP to grab piles.
