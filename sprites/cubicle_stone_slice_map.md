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

## Wall `res://sprites/cubicle_stone_wall.png` (1920x128, 15 frames)

Same small-brick + light cap as frame 0. West V occupies the right half (x~64-119). East V occupies the left half (x~8-63). Frame 4 is shadow only. Frames 0-11 are unchanged; 12-14 are appended.

| type | x | Kind |
|---|---|---|
| 0 | 0 | H middle (seamless) |
| 1 | 128 | V middle west (N-S column, right half) |
| 2 | 256 | L-corner Left-Down |
| 3 | 384 | L-corner Left-Up |
| 4 | 512 | shadow only. not a wall. wall.tscn Shadow stays Rect2(512,0,128,128) |
| 5 | 640 | L-corner Right-Up |
| 6 | 768 | L-corner Right-Down |
| 7 | 896 | H left end-cap |
| 8 | 1024 | H right end-cap |
| 9 | 1152 | V top end-cap west (right-aligned) |
| 10 | 1280 | V bottom end-cap west (right-aligned) |
| 11 | 1408 | spare H middle |
| 12 | 1536 | V middle east (N-S column, left half, mirror of 1) |
| 13 | 1664 | V top end-cap east (left-aligned, mirror of 9) |
| 14 | 1792 | V bottom end-cap east (left-aligned, mirror of 10) |

Pick: 0 H straight, 1 west V straight, 12 east V straight, 2/3/5/6 corners, 7/8 H ends, 9/10 west V ends, 13/14 east V ends, skip 4. West wall of a room keeps 1. East wall of a room uses 12. `wall.gd` `_resolved_frame` must `clampi(frame, 0, 14)`.
