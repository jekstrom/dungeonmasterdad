# Cubicle-stone slice map

Drop-in for `level/floor.tscn` and `level/wall.tscn`. Do not rewrite the generator. Do not treat cubicle partitions as walls.

`doodads/dungeon.tres` (`autotile_template.png`) is a leftover Godot TileSet. The generator does not use it. Leave it.

## Files

| Path | Size | Use |
|---|---|---|
| `res://sprites/cubicle_stone_floor.png` | 1280 x 128 | `floor.tscn` Sprite2D atlas |
| `res://sprites/cubicle_stone_wall.png` | 1280 x 128 | `wall.tscn` Sprite2D + Shadow atlas |
| `res://sprites/cubicle_partitions.png` | 512 x 128 | doodads only, later. NOT walls. NOT generator floor_type |

Tile size: **128 x 128**. Same UV math as today:

```
region = Rect2(type * 128, 0, 128, 128)
```

Nearest-neighbor. Project already has `default_texture_filter=0`.

## Floor (`cubicle_stone_floor.png`)

All 10 frames are **walkable**. No collision. Generator today only writes 0 and 1. Frames 2–9 exist so `floor.gd` `randi_range(0, 9)` is no longer junk UVs.

| type | x | Role | Look |
|---|---|---|---|
| 0 | 0 | room / entrance / exit (generator) | plain cobble |
| 1 | 128 | hallway (generator) | cobble + paper specks |
| 2 | 256 | walkable variant | coffee stains |
| 3 | 384 | walkable variant | papers |
| 4 | 512 | walkable variant | fluorescent strip |
| 5 | 640 | walkable variant | moss |
| 6 | 768 | walkable variant | beige carpet |
| 7 | 896 | walkable variant | PAPER FIRM rug |
| 8 | 1024 | walkable variant | drain |
| 9 | 1152 | walkable variant | green puddle |

## Wall (`cubicle_stone_wall.png`)

All frames except type 4 are **blocking** (`StaticBody2D`, existing colliders). Type 4 is the **shadow sprite source only** (`wall.tscn` Shadow region `Rect2(512, 0, 128, 128)`).

Generator today: non-EW occupancy-adjacent → `wall_type = 1`. E/W walkable neighbor → `wall_type = 2` (vertical collider in `wall.gd`). Do not change that.

| type | x | Blocking | Look |
|---|---|---|---|
| 0 | 0 | yes, horizontal collider | clean standard |
| 1 | 128 | yes, horizontal collider (generator default) | standard + small crack |
| 2 | 256 | yes, **vertical collider** (generator EW) | inner-corner / end-on |
| 3 | 384 | yes, horizontal collider | damaged fissure |
| 4 | 512 | **no** (shadow texture only) | top-down cobble, flattened by existing Shadow node |
| 5 | 640 | yes | note pinned |
| 6 | 768 | yes | moss |
| 7 | 896 | yes | barred window |
| 8 | 1024 | yes | outer corner |
| 9 | 1152 | yes | skull pillar |

`wall.gd` `randi_range(0, 9)` is now in-bounds. Prefer keeping generator on 1 and 2 so colliders stay correct. Random 0–9 can pick type 2 (vertical collider) on a horizontal edge, or type 4 (flat cobble) as a "wall" visual. If you still randomize, skip 2 and 4.

## Cubicle partitions (`cubicle_partitions.png`)

These sat on the concept atlas floor row. **Do not map them to `wall.tscn`.** They will z-fight with occupancy walls.

| type | x | Layer | Collision |
|---|---|---|---|
| 0 | 0 | floor doodad / y-sorted obstacle | own low collider later, not wall |
| 1 | 128 | same | same |
| 2 | 256 | same | same |
| 3 | 384 | same | same |

Looks: corner, straight, T-junction, doorway gap. Out of v1 generator catalog (no trees/buildings/doodads in v1). Ship the PNG so they exist. Do not instance them in this swap.

## Swap

1. `level/floor.tscn` `ExtResource` texture → `res://sprites/cubicle_stone_floor.png`. Keep AtlasTexture `Rect2(0, 0, 128, 128)`.
2. `level/wall.tscn` both AtlasTextures → `res://sprites/cubicle_stone_wall.png`. Sprite region stays `Rect2(0, 0, 128, 128)` (script overwrites from `wall_type`). Shadow stays `Rect2(512, 0, 128, 128)`.
3. Leave `floor.gd` / `wall.gd` / generator math alone.
4. Do not touch `doodads/dungeon.tres`.
