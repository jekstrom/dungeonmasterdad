# Research: Parameterized Procedural Dungeon Generation

## Generation Algorithm Strategy

### Decision
Use a hybrid generation approach: room graph backbone (for guaranteed connectivity and start/exit anchoring) plus maze-style corridor infill (for exploration feel).

### Rationale
- Room graph backbone makes it straightforward to enforce explicit entrance/exit positions and guaranteed traversability.
- Maze infill in unused space preserves the requested "like a maze" experience without sacrificing reliability.
- Hybrid strategy balances deterministic validation requirements (multiplayer-safe) with layout variety.

### Alternatives considered
- Pure BSP room partitioning: strong control, but layouts can feel too regular without heavy post-processing.
- Pure maze-first with room carving: strong maze feel, but more difficult to preserve room quality and predictable pacing.
- Simple random-walk corridors: easy to implement but weaker control over guarantees and repeated quality.

## Multiplayer Authority Model

### Decision
Generate and validate dungeon content server-side only; clients receive finalized authoritative dungeon layout and spawn results.

### Rationale
- Prevents client desync and cheating vectors for game-changing world state.
- Matches project constitution requirements for server-authoritative gameplay.
- Ensures invalid requests fail consistently for all players (no partial world commits).

### Alternatives considered
- Client-local generation from shared seed only: rejected due to divergence risk and weaker authority guarantees.
- Hybrid client/server generation with reconciliation: rejected as unnecessary complexity for this feature scope.

## Existing Asset Integration

### Decision
Reuse scene-based assets already present in the project for tiles and monsters:
- Tiles: `level/floor.tscn`, `level/wall.tscn`
- Monsters: `monsters/goblin.tscn`, `monsters/skeleton/skeleton.tscn`, `monsters/knight/knight.tscn`

### Rationale
- Directly satisfies requirement to use existing tiles and monsters.
- Aligns with current repository organization and avoids introducing new content pipelines.
- Keeps generated content visually and behaviorally consistent with the rest of the game.

### Alternatives considered
- New dedicated dungeon tile/monster assets: rejected (out of scope and violates feature requirement).
- Migrating to a new TileMap-only pipeline first: rejected as a large architectural change not required for this feature.

## Request Validation and Failure Handling

### Decision
Perform input and feasibility validation before committing generated content to the world; return explicit failure state when start/exit are invalid or layout constraints cannot be met.

### Rationale
- Ensures stable multiplayer outcomes.
- Prevents partial generation artifacts and cleanup complexity.
- Makes edge-case behavior testable and predictable.

### Alternatives considered
- Best-effort partial generation: rejected due to desync risk and unclear player-facing behavior.
- Silent fallback to default positions: rejected because it violates explicit caller-provided entrance/exit intent.

## Performance and Scalability Boundaries

### Decision
Constrain generation by bounded attempts and target completion budget (2 seconds for standard size in ≥95% of requests), with no long frame stalls.

### Rationale
- Matches spec performance requirements.
- Prevents generation spikes from reducing multiplayer responsiveness.
- Keeps repeated in-session generation reliable.

### Alternatives considered
- Unbounded search for "perfect" layouts: rejected due to unpredictable latency.
- Synchronous heavy generation without constraints: rejected due to frame hitching risk.
