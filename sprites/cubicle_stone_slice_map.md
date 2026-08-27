# Cubicle-stone slice map

Tile size 128x128. `Rect2(type * 128, 0, 128, 128)`.

## Floor `res://sprites/cubicle_stone_floor.png` (1280x128)

All walkable. Frames 0-9 share the same cobble on the outer 8px so variants tile against 0/1. Paper/carpet/fluorescent live in the interior.

| type | x | Role |
|---|---|---|
| 0 | 0 | room cobble |
| 1 | 128 | hallway cobble |
| 2-9 | 256-1152 | variants, cobble-edged |

Partitions: `cubicle_partitions.png`. Not walls. Not this strip.

## Wall `res://sprites/cubicle_stone_wall.png` (1536x128, 12 frames)

Same small-brick + light cap as frame 0. V graphics occupy the right half of the cell (x~64-119) so they sit on the type-2 collider. Frame 4 is shadow only.

| type | x | Kind |
|---|---|---|
| 0 | 0 | H middle (seamless) |
| 1 | 128 | V middle (N-S 3/4 column, right half) |
| 2 | 256 | L-corner Left-Down |
| 3 | 384 | L-corner Left-Up |
| 4 | 512 | shadow only. not a wall. wall.tscn Shadow stays Rect2(512,0,128,128) |
| 5 | 640 | L-corner Right-Up |
| 6 | 768 | L-corner Right-Down |
| 7 | 896 | H left end-cap |
| 8 | 1024 | H right end-cap |
| 9 | 1152 | V top end-cap |
| 10 | 1280 | V bottom end-cap (south face + column) |
| 11 | 1408 | spare H middle |

GP must update `_wall_frame_for_cell` to this map. Old 0/2/3/5/8 mapping is obsolete. Suggested pick: 0 H straight, 1 V straight, 2/3/5/6 corners, 7/8 H ends, 9/10 V ends, skip 4. `wall.gd` `_resolved_frame` currently `clampi(frame, 0, 9)` and defaults type-2 to frame 2; raise clamp to 11 and default type-2 to frame 1.
