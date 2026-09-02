# T005: Gremlin art (distinct from goblin)

**Story**: US-013  
**Status**: Todo  
**Depends on**: —  
**Owner**: Art

## Goal

Deliver **gremlin-only** world sheet, spawn HUD icon, and optional death VFX per US-013 Required New Art Assets. **Forbidden:** goblin recolors, shared goblin atlases, goblin raid icons for this creature.

## Checklist

1. Gremlin world sprite sheet (`monsters/gremlin.png` or successor) — idle / walk / pick / carry; not `goblin.png`
2. Gremlin spawn HUD icon — refine `sprites/gremlin_spawn_button.png` if needed
3. Optional gremlin death/poof VFX (not goblin death FX)
4. Verify US-034 gremlin-row skill icons are not goblin assets

## Acceptance

- **Given** art imported, **When** side-by-side with goblin sheet/HUD, **Then** gremlin reads as a different creature with its own frames.
