# T001: Dedicated gremlin scene (not goblin)

**Story**: US-013  
**Status**: Todo  
**Depends on**: —  
**Owner**: Gameplay

## Goal

Ship `monsters/gremlin.tscn` (or equivalent) as the DM gremlin spawn. **Remove** any path that instances `monsters/goblin.tscn` for the gremlin summon. Wire HUD spawn to the gremlin scene. Visuals use gremlin sheet (T005).

## Files

- DM spawn / `DmManager` gremlin summon
- `monsters/gremlin.tscn` (+ script extending enemy patterns as needed)
- Must not depend on `monsters/goblin.tscn` for this summon

## Requirements

- FR-008, FR-009, AC8, MR-003

## Acceptance

- **Given** DM spawns a gremlin, **When** the node is inspected, **Then** it is the gremlin scene/sheet — not goblin prefab or goblin atlas.
