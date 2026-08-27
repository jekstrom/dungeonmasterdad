# Cubicle-stone slice map

Tile size: **128 x 128**. UV: `Rect2(type * 128, 0, 128, 128)`.

## Floor — `res://sprites/cubicle_stone_floor.png` (1280 x 128)

All walkable. Generator 0=room, 1=hallway.

| type | x | Role |
|---|---|---|
| 0 | 0 | room / entrance / exit |
| 1 | 128 | hallway |
| 2–9 | 256–1152 | walkable variants |

Cubicle partitions are NOT on this strip. See `cubicle_partitions.png`. Doodads only. Not walls.

## Wall — `res://sprites/cubicle_stone_wall.png` (1280 x 128)

Overwrite of the dual-end-cap strip. Neighbor-based pick:

| type | x | Kind | Place when |
|---|---|---|---|
| **0** | 0 | **seamless horizontal middle** | straight E/W run (default) |
| 1 | 128 | seamless H middle variant | straight E/W variant |
| **2** | 256 | **inner-corner / end-on** | actual inner corners only |
| **3** | 384 | **left end-cap** | west end of a straight run |
| 4 | 512 | shadow source only | `wall.tscn` Shadow `Rect2(512,0,128,128)`. Not a wall. |
| **5** | 640 | **right end-cap** | east end of a straight run |
| 6 | 768 | moss middle | straight variant |
| 7 | 896 | window middle | straight variant |
| **8** | 1024 | **outer corner** | actual outer corners only |
| 9 | 1152 | skull middle | straight variant |

Do not place 2 or 8 on straight runs. Do not place 0/1/6/7/9 as corners. Skip 4 for wall instances.

Y-sort is GP (`339e8a8`). Art does not set `z_index=1`.

## Partitions — `res://sprites/cubicle_partitions.png`

Out of v1. Not walls.
