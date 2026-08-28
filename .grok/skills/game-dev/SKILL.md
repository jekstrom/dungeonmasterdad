---
name: game-dev
description: >
  Default game-development workflow for Dungeon Master Dad. Use when building
  features, tuning feel, adding content, or choosing how to implement gameplay.
  Triggers: game design, gameplay, feature, dungeon, player, DM, feel, content,
  /game-dev.
when-to-use: gameplay feature, dungeon content, player feel, ship a vertical slice
metadata:
  short-description: Gameplay workflow for this Godot RPG
  author: dungeon-master-dad
---

# Game dev

Ship playable changes. Follow `AGENTS.md` for naming, state machines, and file layout.

For Godot engine work, also follow `/godot`. For verification, also follow `/testing`. For new sprites, tiles, or UI art, use the bundled `game-asset-core` skill plus the matching specialist (`game-tilesets`, `game-animation-frames`, `game-character-consistency`, `game-ui-icons`).

## Order of work

1. Name the player-facing change in one sentence (what you can do, see, or fight).
2. Touch the smallest scene/script set that implements it. Prefer existing systems (`SignalBus`, spawners, `DungeonGenerator`, state machines) over new frameworks.
3. Keep the host authoritative for world state. Client-owned input is only for the local player's movement/camera.
4. Verify in play: movement, y-sort, collision, then a host+client join if the change is networked or spawned.
5. Do not leave debug prints, unused scenes, or half-wired inspector exports.

## Feel checks (2D)

- Character draw order is south-foot y-sort: approaching from the south draws in front of walls; from the north, walls overlap the sprite.
- Collision matches the visible obstacle, not the full sprite rect.
- Generated or placed content must stay walkable from entrance to exit unless the task is to block a path on purpose.

## Content

- Tiles: `level/floor.tscn`, `level/wall.tscn`.
- Monsters: catalog in `scripts/procedural_dungeon/monster_catalog.gd` (goblin, skeleton, knight).
- Dungeon layout knobs live on the `DungeonGenerator` node (`scenes/dungeon_generator.tscn`), not in `level_manager.gd`.
