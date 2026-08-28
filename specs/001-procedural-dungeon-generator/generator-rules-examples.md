# Generator Rules v1 — worked examples

Companion to `generator-rules.md`. These are the maps to code against. Do not treat them as snapshots the generator must reproduce cell-for-cell; they show a **legal** layout under the rules (separation, roles, extra edge, dead-end pocket).

Grid is **cell coordinates**, origin top-left, y down. One character per cell. Cell size in world is still 128.

```
>  entrance cell (start room)
<  exit cell (exit room)
S  start room (role=start)
A/B/C or M  mid rooms (role=mid)
E  exit room (role=exit)
D  dead-end pocket (role=deadend)
+  hallway
#  wall
```

---

## 1. Canonical `24×24` (this is also the US1 / US2 payload)

- `generationBounds`: origin `(0,0)`, size `(24,24)`
- `startPosition`: `(2,2)`
- `exitPosition`: `(16,16)`
- `mid_count = floor(24*24 / 180) = 3`

### Centers (Chebyshev ≥ 6 between every pair)

| id | role | center | square (radius 2) |
|---|---|---|---|
| `room_start` | start | `(2,2)` | `(0,0)–(4,4)` |
| `room_mid_a` | mid | `(8,2)` | `(6,0)–(10,4)` |
| `room_mid_b` | mid | `(8,8)` | `(6,6)–(10,10)` |
| `room_mid_c` | mid | `(16,10)` | `(14,8)–(18,12)` |
| `room_exit` | exit | `(16,16)` | `(14,14)–(18,18)` |

`room_mid_b` is the **jittered** mid. It does **not** sit on the start→exit L `(2,2)→(16,2)→(16,16)`. That is what makes the extra edge real.

### Graph

Backbone, sorted by projection on `exit - start = (14,14)`:

```
(2,2) start → (8,2) A → (8,8) B → (16,10) C → (16,16) exit
```

Extra edge (seed even): **A → C**. The L `(8,2)→(16,2)→(16,10)` walks along the top and down the right, which is **not** a subset of the backbone (backbone went south from A to B first). Degenerate extra edges are illegal; this one is legal.

Dead end: root on that extra-edge hall at `(12,2)`, walk south 4, pocket radius 1 at `(12,6)`. Pocket does not overlap any room square.

```
y\x 012345678901234567890123
00  SSSSS#AAAAA#############
01  SSSSS#AAAAA#############
02  SS>SS+AAAAA++++++#######
03  SSSSS#AAAAA#+###+#######
04  SSSSS#AAAAA#+###+#######
05  ########+##DDD##+#######
06  ######BBBBBDDD##+#######
07  ######BBBBBDDD##+#######
08  ######BBBBB+++CCCCC#####
09  ######BBBBB###CCCCC#####
10  ######BBBBB###CCCCC#####
11  ##############CCCCC#####
12  ##############CCCCC#####
13  ################+#######
14  ##############EEEEE#####
15  ##############EEEEE#####
16  ##############EE<EE#####
17  ##############EEEEE#####
18  ##############EEEEE#####
19  ########################
20  ########################
21  ########################
22  ########################
23  ########################
```

Read as a player: 5×5 start, one-tile door, 5×5 A, extra hall along the top with a pocket you can miss, south into B, across into C, one-tile door into the exit room.

### Encounters for this map (one legal roll)

Door cells are the room cells that touch a `+`. No spawns on those, on `>` / `<`, or their 4-neighbors.

| Room | Package | Place on |
|---|---|---|
| start S | `[]` | — |
| mid A | two `goblin` | interior of A, farthest from the east door |
| mid B | `skeleton` + `goblin` | interior of B, farthest from north and east doors |
| mid C | `[]` this roll (knight already used? **no** — say C rolled `90–99` but we already have no knight; **one knight here**, solo, center-ish of C, not on doors) | C interior |
| exit E | one `skeleton` | interior of E, not on the north door or `<` neighborhood |
| deadend D | `[]` | — |
| hallways | all regions here are 1–6 cells, none ≥ 8, so **no** hall goblins | — |

Knight count = 1. Start empty. That is a passing US3.

If C had rolled two goblins instead, still legal. If A, B, and C all rolled knight, only the first knight sticks; the others become two goblins.

---

## 2. Minimum `16×16` (one mid, no loop)

- bounds `(0,0) (16,16)` → `mid_count = 1`
- start `(2,2)`, exit `(13,13)`
- mid `(8,2)` on the L (jitter not required when `mid_count == 1`)
- extra edge skipped (`mid_count < 2`)
- one dead-end pocket off the vertical hall

```
y\x 0123456789012345
00  SSSSS#MMMMM#####
01  SSSSS#MMMMM#####
02  SS>SS+MMMMM+++##
03  SSSSS#MMMMM##+##
04  SSSSS#MMMMM##+##
05  ##########DDD+##
06  ##########DDD+##
07  ##########DDD+##
08  #############+##
09  #############+##
10  #############+##
11  ###########EEEEE
12  ###########EEEEE
13  ###########EE<EE
14  ###########EEEEE
15  ###########EEEEE
```

This is the smallest legal journey: start, one mid, exit, one pocket. Use it as a bounds-floor check, not as US1.

---

## 3. Trap: the old US1 payload cannot pass v1

Current harness: start `(2,2)`, exit `(10,10)`, bounds `20×20`.

Chebyshev(start, exit) = 8. A mid must be ≥ 6 from **both** centers **and** those two are only 8 apart. The feasible band is too thin; greedy placement will burn retries and throw `LAYOUT_INFEASIBLE`.

US1 v1 payload is the canonical `24×24` in section 1. Do not keep the old coordinates.

---

## 4. Extra-edge sanity check (implement this predicate)

Let `backbone_cells` = union of X-then-Y L cells for every backbone edge, minus room interiors (or including them; does not matter).

Candidate extra pair `(u, v)` is legal iff:

```
len(set(l_path(u, v)) - backbone_cells - all_room_cells) >= 1
```

If the set is empty, skip. Do not carve a second copy of the same L.

On the canonical map, `A → C` is legal (new cells along `y=2` for `x=11..16` and down `x=16`). `A → B` is a backbone edge, not extra. `start → C` mostly retraces the extra/top path plus backbone; prefer `A → C` as the extra.

---

## 5. What “sit with Gameplay Programmer” means on this pass

When implementation starts, check in this order against these maps:

1. Session lock clears so a second `generate_dungeon_contract` works.
2. Canonical payload produces **≥ 3 room roles** (`start`, `mid`, `exit`) and rooms do not touch.
3. At least one mid is off the start→exit L (or an extra edge that adds new cells).
4. A `D` pocket exists and has zero spawns.
5. Start room zero spawns; knight ≤ 1; floors 0 vs 1.

If a generated dump does not look *like* map 1 (rooms as 5×5, 1-cell doors, a pocket off a side hall), the rules were not applied. Do not tune combat; do not add HUD.
