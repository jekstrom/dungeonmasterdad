# T003: Pathing, targets, and flee

**Story**: US-013  
**Status**: Todo  
**Depends on**: T002  
**Owner**: Gameplay

## Goal

Gremlin pathfinds to pickups on **walkable** navigation only (FR-011 / AC10) — no cliffs, off-map, or permanently stuck off-navmesh. Additionally apply **inland bias** (FR-012 / AC11): prefer running **away from cliffs** / map edges when choosing flee, wander, or carry routes — soft preference among walkable cells, not only a hard clamp after leaving walkable.

When multiple piles exist and the gremlin is not fleeing, prefer resources near factories and the IRS (FR-007) among inland-safe options. May enter Reality Zone (AC7).

**Always flee Paper Pushers** (FR-014 / AC13): while any PP is within flee range, flee overrides acquire/path-to-pile; still walkable-only + inland bias. Flee does not delete a carried item (drop timer / damage / death still apply).

## Requirements

- FR-007, FR-011, FR-012, FR-014, AC1, AC7, AC10, AC11, AC13

## Acceptance

- **Given** two piles (one by a factory, one far) and no PP in flee range, **When** an empty gremlin chooses, **Then** it prefers the near-factory/IRS pile when reachable on walkable pathing with inland bias.
- **Given** a nav edge / cliff / off-map cell, **When** the gremlin paths, **Then** it never steps there or wedges permanently off-navmesh.
- **Given** inland vs cliff-edge walkable flee/wander options, **When** AI picks a route, **Then** it prefers inland (away from cliffs) rather than skimming the edge.
- **Given** a PP in flee range, **When** AI updates, **Then** the gremlin flees on walkable inland-biased cells and does not walk into the PP to grab piles.
