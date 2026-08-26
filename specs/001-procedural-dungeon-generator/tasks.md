# Tasks: Parameterized Procedural Dungeon Generation

**Input**: Design documents from `/specs/001-procedural-dungeon-generator/`  
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/, quickstart.md

**Tests**: No automated test tasks are included because the specification does not explicitly request TDD or an automated test framework. Manual validation tasks are included per user story using project test harness files.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Every task includes an exact file path

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create module scaffolding and shared constants for procedural dungeon work.

- [X] T001 Create procedural dungeon module index and ownership notes in `scripts/procedural_dungeon/README.md`
- [X] T002 Create shared generation constants (limits, defaults, performance budget) in `scripts/procedural_dungeon/dungeon_constants.gd`
- [X] T003 [P] Create shared typed enums/value objects for generation states and failure codes in `scripts/procedural_dungeon/dungeon_generation_types.gd`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish server-authoritative request/response infrastructure required by all user stories.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T004 Add DungeonGenerationManager autoload registration in `project.godot`
- [X] T005 Create server-authoritative manager skeleton with RPC entry points in `_globals/dungeon_generation_manager.gd`
- [X] T006 [P] Add dungeon request/success/failure broadcast signals in `_globals/signal_bus.gd`
- [X] T007 [P] Implement generation request resource model in `scripts/procedural_dungeon/resources/dungeon_generation_request.gd`
- [X] T008 [P] Implement dungeon layout data resource model in `scripts/procedural_dungeon/resources/dungeon_layout_data.gd`
- [X] T009 [P] Implement dungeon spawn set resource model in `scripts/procedural_dungeon/resources/dungeon_spawn_set.gd`
- [X] T010 Implement authoritative request validation + failure response mapping in `_globals/dungeon_generation_manager.gd`
- [X] T011 Create generated dungeon runtime container scene for atomic swap/cleanup in `scenes/generated_dungeon_container.tscn`
- [X] T012 Wire dungeon lifecycle cleanup helper for world replacement in `_globals/level_manager.gd`

**Checkpoint**: Foundation ready; user story implementation can proceed.

---

## Phase 3: User Story 1 - Generate a traversable dungeon path (Priority: P1) 🎯 MVP

**Goal**: Generate a dungeon from explicit start/exit positions with exactly one entrance and one exit and at least one guaranteed walkable route.

**Independent Test**: Trigger generation with valid start/exit coordinates and verify entrance/exit are placed exactly at requested cells and a valid walkable route exists between them.

- [X] T013 [P] [US1] Implement entrance/exit placement and bounds validation helper in `scripts/procedural_dungeon/entrance_exit_resolver.gd`
- [X] T014 [P] [US1] Implement walkable connectivity/path verification helper in `scripts/procedural_dungeon/path_validator.gd`
- [X] T015 [US1] Implement room-backbone graph generation anchored to start/exit in `scripts/procedural_dungeon/room_graph_generator.gd`
- [X] T016 [US1] Implement backbone hallway carving between connected graph nodes in `scripts/procedural_dungeon/hallway_carver.gd`
- [X] T017 [US1] Integrate P1 generation pipeline (request → validated layout) in `_globals/dungeon_generation_manager.gd`
- [X] T018 [US1] Implement contract-equivalent generate handler for `POST /dungeons/generate` in `_globals/dungeon_generation_manager.gd`
- [X] T019 [US1] Implement contract-equivalent layout retrieval handler for `GET /dungeons/{layoutId}` in `_globals/dungeon_generation_manager.gd`
- [X] T020 [US1] Add manual connectivity validation harness script in `test_harness/procedural_dungeon/us1_connectivity_test.gd`

**Checkpoint**: User Story 1 is independently functional and demo-ready.

---

## Phase 4: User Story 2 - Produce maze-like rooms and hallways (Priority: P2)

**Goal**: Ensure generated dungeons include both room regions and hallway regions while preserving a maze-like exploration feel and repeat-run variation.

**Independent Test**: Run repeated generation requests and verify each successful output contains at least one room and one hallway region, with non-identical layout arrangements across runs.

- [X] T021 [P] [US2] Implement maze infill branch generation for non-backbone space in `scripts/procedural_dungeon/maze_infill_generator.gd`
- [X] T022 [P] [US2] Implement room region classification for generated layouts in `scripts/procedural_dungeon/room_region_classifier.gd`
- [X] T023 [P] [US2] Implement hallway region classification for generated layouts in `scripts/procedural_dungeon/hallway_region_classifier.gd`
- [X] T024 [US2] Implement layout composition that merges backbone + maze infill outputs in `scripts/procedural_dungeon/layout_composer.gd`
- [X] T025 [US2] Enforce room/hallway presence validation and retry strategy in `_globals/dungeon_generation_manager.gd`
- [X] T026 [US2] Add repeat-run layout variation policy (seed/attempt strategy) in `_globals/dungeon_generation_manager.gd`
- [X] T027 [US2] Add repeated-generation and region-coverage harness script in `test_harness/procedural_dungeon/us2_layout_variety_test.gd`

**Checkpoint**: User Stories 1 and 2 both function independently.

---

## Phase 5: User Story 3 - Populate with existing game content (Priority: P3)

**Goal**: Build generated dungeons using only existing floor/wall tiles and existing monster scenes, with spawn safety constraints.

**Independent Test**: Generate dungeons and verify all tile placements and monster spawns reference only approved existing asset paths; verify no monster spawns on entrance/exit cells.

- [X] T028 [P] [US3] Implement approved tile catalog resolver for existing dungeon tiles in `scripts/procedural_dungeon/tile_catalog.gd`
- [X] T029 [P] [US3] Implement approved monster catalog resolver for existing monster scenes in `scripts/procedural_dungeon/monster_catalog.gd`
- [X] T030 [US3] Implement layout-to-scene tile instantiation using floor/wall assets in `scripts/procedural_dungeon/dungeon_scene_builder.gd`
- [X] T031 [US3] Implement monster spawn planner with entrance/exit and blocked-cell exclusions in `scripts/procedural_dungeon/monster_spawn_planner.gd`
- [X] T032 [US3] Integrate generated monster spawns with existing multiplayer spawn flow in `scripts/multiplayer_spawner.gd`
- [X] T033 [US3] Apply generated dungeon scene commit/rollback behavior in `_globals/dungeon_generation_manager.gd`
- [X] T034 [US3] Add content-compliance validation harness script in `test_harness/procedural_dungeon/us3_content_compliance_test.gd`

**Checkpoint**: All user stories are independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final hardening across all user stories.

- [X] T035 [P] Add generation timing and failure-code telemetry logging in `_globals/dungeon_generation_manager.gd`
- [X] T036 [P] Document procedural dungeon generation runtime/debug workflow in `README.md`
- [X] T037 Finalize quickstart with completed validation evidence and run notes in `specs/001-procedural-dungeon-generator/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: no dependencies
- **Phase 2 (Foundational)**: depends on Phase 1; blocks all user stories
- **Phase 3 (US1)**: depends on Phase 2; MVP slice
- **Phase 4 (US2)**: depends on Phase 2 and integrates with US1 layout pipeline
- **Phase 5 (US3)**: depends on Phase 2 and uses layout outputs from US1/US2
- **Phase 6 (Polish)**: depends on all completed stories

### User Story Dependency Graph

- **US1 (P1)**: first delivery slice; no dependency on other user stories
- **US2 (P2)**: extends generation behavior built in US1
- **US3 (P3)**: applies content population to validated generation outputs from US1/US2

Graph: `US1 → US2 → US3`

### Within Each User Story

- Data/helpers before orchestration
- Orchestration before manager integration
- Manager integration before manual validation harness

### Parallel Opportunities

- Setup: T003 can run in parallel with T001/T002
- Foundational: T006-T009 can run in parallel once T004-T005 begin
- US1: T013 and T014 can run in parallel
- US2: T021-T023 can run in parallel
- US3: T028 and T029 can run in parallel
- Polish: T035 and T036 can run in parallel

---

## Parallel Example: User Story 1

```bash
Task: "T013 [US1] Implement entrance/exit placement and bounds validation helper in scripts/procedural_dungeon/entrance_exit_resolver.gd"
Task: "T014 [US1] Implement walkable connectivity/path verification helper in scripts/procedural_dungeon/path_validator.gd"
```

## Parallel Example: User Story 2

```bash
Task: "T021 [US2] Implement maze infill branch generation in scripts/procedural_dungeon/maze_infill_generator.gd"
Task: "T022 [US2] Implement room region classification in scripts/procedural_dungeon/room_region_classifier.gd"
Task: "T023 [US2] Implement hallway region classification in scripts/procedural_dungeon/hallway_region_classifier.gd"
```

## Parallel Example: User Story 3

```bash
Task: "T028 [US3] Implement approved tile catalog resolver in scripts/procedural_dungeon/tile_catalog.gd"
Task: "T029 [US3] Implement approved monster catalog resolver in scripts/procedural_dungeon/monster_catalog.gd"
```

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Complete Phase 1 and Phase 2
2. Complete Phase 3 (US1)
3. Run US1 independent connectivity validation (`test_harness/procedural_dungeon/us1_connectivity_test.gd`)
4. Demo/deploy MVP behavior before proceeding

### Incremental Delivery

1. Foundation ready (Phases 1-2)
2. Deliver US1 (traversable start→exit generation)
3. Deliver US2 (maze-like rooms/hallways + variation)
4. Deliver US3 (existing asset-only tiles + monsters)
5. Finish with cross-cutting polish and validation evidence

### Parallel Team Strategy

1. Team aligns on Foundation (Phases 1-2)
2. After Foundation:
   - Developer A: US1 orchestration tasks
   - Developer B: US2 maze/region modules
   - Developer C: US3 catalog/spawn modules
3. Integrate at manager layer (`_globals/dungeon_generation_manager.gd`) and complete harness validation

---

## Notes

- All tasks follow strict checklist format with task ID and file path.
- `[US1]`, `[US2]`, `[US3]` labels are used only in user story phases.
- No automated test framework is assumed; validation tasks target manual harness scripts.
- Keep server-authority checks in all gameplay-affecting generation and spawn paths.
