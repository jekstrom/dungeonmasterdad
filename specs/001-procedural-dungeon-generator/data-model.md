# Data Model: Parameterized Procedural Dungeon Generation

## Core Entities

### 1) DungeonGenerationRequest
**Purpose**: Defines one generation attempt with explicit entrance and exit intent.

**Fields**:
- `request_id` (string): Unique identifier for traceability.
- `start_position` (Vector2i): Requested entrance position.
- `exit_position` (Vector2i): Requested exit position.
- `generation_bounds` (Rect2i): Area where generation is allowed.
- `profile_id` (string): Size/density profile identifier for generation parameters.
- `request_time` (datetime): Submission timestamp.
- `requested_by_peer_id` (int): Multiplayer sender for authority/audit.

**Validation Rules**:
- `start_position` and `exit_position` must be inside `generation_bounds`.
- `start_position` and `exit_position` must be different.
- Bounds must be large enough for at least one room plus corridor path.
- Request is accepted only by authoritative server.

### 2) DungeonLayout
**Purpose**: Canonical generated dungeon geometry and navigability result.

**Fields**:
- `layout_id` (string): Unique generated layout identifier.
- `grid_size` (Vector2i): Width/height in grid cells.
- `entrance_cell` (Vector2i): Final entrance cell (must match request start).
- `exit_cell` (Vector2i): Final exit cell (must match request exit).
- `walkable_cells` (Array<Vector2i>): Cells players can traverse.
- `blocked_cells` (Array<Vector2i>): Non-walkable wall/solid cells.
- `room_regions` (Array<RoomRegion>): Room partitions.
- `hallway_regions` (Array<HallwayRegion>): Hallway partitions.
- `main_path_cells` (Array<Vector2i>): Verified route from entrance to exit.
- `generation_seed` (int): Seed used for deterministic replay/debug.

**Validation Rules**:
- Exactly one entrance and one exit.
- Entrance/exit are walkable and connected by at least one path.
- At least one room region and one hallway region.
- No overlap conflicts between blocked and walkable cells.

### 3) RoomRegion
**Purpose**: Represents a contiguous room area in the layout.

**Fields**:
- `room_id` (string)
- `cells` (Array<Vector2i>)
- `bounds` (Rect2i)
- `door_cells` (Array<Vector2i>)

**Validation Rules**:
- Must be contiguous.
- Must include at least one doorway to a hallway or main path.

### 4) HallwayRegion
**Purpose**: Represents corridor segments linking rooms and traversal branches.

**Fields**:
- `hallway_id` (string)
- `cells` (Array<Vector2i>)
- `connected_room_ids` (Array<string>)

**Validation Rules**:
- Must connect to at least one room or the main entrance/exit path.

### 5) DungeonTilePlacement
**Purpose**: Binds generated cells to existing tile catalog entries.

**Fields**:
- `cell` (Vector2i)
- `tile_role` (enum: `floor`, `wall`, `entrance`, `exit`)
- `tile_source_path` (string): Existing tile scene/resource path.
- `variant_id` (int): Optional style variant index.

**Validation Rules**:
- `tile_source_path` must exist in the approved existing tile catalog.
- Entrance/exit placements must map to walkable cells.

### 6) DungeonSpawnSet
**Purpose**: Captures monster placements for a generated layout.

**Fields**:
- `layout_id` (string)
- `spawns` (Array<MonsterSpawn>)
- `spawn_ruleset_id` (string)

**Validation Rules**:
- No spawn on entrance or exit cells.
- Each spawn references an existing monster definition.
- Spawn positions must be walkable and valid.

### 7) MonsterSpawn
**Purpose**: One monster placement record.

**Fields**:
- `spawn_id` (string)
- `monster_type_id` (string)
- `monster_scene_path` (string)
- `position` (Vector2i)

**Validation Rules**:
- `monster_scene_path` must belong to approved monster catalog.
- Position cannot overlap blocked cells, entrance, or exit.

## Relationships

- `DungeonGenerationRequest` (1) → (0..1) `DungeonLayout`
- `DungeonLayout` (1) → (1..N) `RoomRegion`
- `DungeonLayout` (1) → (1..N) `HallwayRegion`
- `DungeonLayout` (1) → (N) `DungeonTilePlacement`
- `DungeonLayout` (1) → (0..1) `DungeonSpawnSet`
- `DungeonSpawnSet` (1) → (0..N) `MonsterSpawn`

## State Transitions

### Generation Lifecycle

1. `Received` → request accepted by authoritative server.
2. `Validated` → positions and bounds validated.
3. `GeneratingLayout` → rooms/hallways/path produced.
4. `ValidatedLayout` → connectivity and constraints checks pass.
5. `PopulatingSpawns` → monster placements generated from existing catalog.
6. `Committed` → layout and spawns become active world state and are broadcast.

Failure branches:
- `Received/Validated/GeneratingLayout` → `Rejected` (invalid input/constraints impossible)
- `PopulatingSpawns` → `Rejected` (catalog or placement validation failure)

## Invariants

- There is never more than one entrance or more than one exit per generated dungeon.
- Successful generation always yields an entrance-to-exit path.
- Generated output never uses non-catalog tiles or monsters.
- Multiplayer clients must observe the same committed layout/spawn set for a given `request_id`.
