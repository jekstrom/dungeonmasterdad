# Cubicle-stone slice map

Tile size 128x128. `Rect2(type * 128, 0, 128, 128)`.

Diablo 1 cathedral 3/4 tileset: dark gray small-brick caps, grimy south faces, cobble floor.

## Floor `res://sprites/cubicle_stone_floor.png` (2048x128)

16 slices of a 512×512 seamless cathedral floor (4×4). `floor.gd` picks frame from cell `x%4 + (y%4)*4` so a 2×2 of rooms reconstructs the megatile instead of stamping one tile.

Wall sprites are transparent outside the cap/face so floor z-index never comes from a wall.

## Wall `res://sprites/cubicle_stone_wall.png` (3584x128, 28 frames)

Centered 40px wall plan. South-exposed tops get a 44px face. Non-wall pixels are transparent. Frame 4 is shadow only. Frames 12-16 are east aliases of the centered V/corner art. 17-21 are T and +. Collision uses an H rect and a V rect from each frame's connections.

| type | x | Kind |
|---|---|---|
| 0 | 0 | H middle |
| 1 | 128 | V middle |
| 2 | 256 | L-corner W+S |
| 3 | 384 | L-corner W+N |
| 4 | 512 | shadow only. wall.tscn Shadow stays Rect2(512,0,128,128) |
| 5 | 640 | L-corner E+N |
| 6 | 768 | L-corner E+S |
| 7 | 896 | H left end-cap (connects E) |
| 8 | 1024 | H right end-cap (connects W) |
| 9 | 1152 | V top end-cap (connects S) |
| 10 | 1280 | V bottom end-cap (connects N) |
| 11 | 1408 | spare H middle |
| 12 | 1536 | V middle (east alias of 1) |
| 13 | 1664 | V top (east alias of 9) |
| 14 | 1792 | V bottom (east alias of 10) |
| 15 | 1920 | L-corner W+S (east alias of 2) |
| 16 | 2048 | L-corner W+N (east alias of 3) |
| 17 | 2176 | T stem north (N+E+W) |
| 18 | 2304 | T stem east (N+S+E) |
| 19 | 2432 | T stem south (S+E+W) |
| 20 | 2560 | T stem west (N+S+W) |
| 21 | 2688 | cross (+) |
| 22 | 2816 | H left end north-hug (south wall of a room) |
| 23 | 2944 | H right end north-hug |

H 0 = south-hug (north wall, against floor below). H 11 = north-hug (south wall, against floor above). V 1 = east-hug (west wall). V 12 = west-hug (east wall). Sprite offset matches floor `(0, -63)`. Skip 4.

Inner (concave) corners 24-27 hug toward walkable when the floor is on the opposite diagonal from the outer L. `wall.gd` clamp to 27.
