# Tasks: Fix Snake-Mode Death System

**Input**: Design documents from `/specs/001-fix-snake-death/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Manual testing using playground.tscn with server + multiple client instances

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Godot project**: Working within existing directory structure
- Scripts in: `_globals/`, `player/`, `pickups/`, `zones/`, `scripts/multiplayer/`
- Scenes in: `pickups/`, `zones/`

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [X] T001 Create multiplayer DeathSystem singleton directory at scripts/multiplayer/
- [X] T002 [P] Create DeathSystem autoload configuration in project.godot
- [X] T003 [P] Setup SignalBus death event signals in _globals/SignalBus.gd

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Create DeathSystem core singleton in scripts/multiplayer/DeathSystem.gd with RPC infrastructure
- [X] T005 Add death event signals to SignalBus singleton in _globals/SignalBus.gd
- [X] T006 [P] Create DroppedItem scene template in pickups/DroppedItem.tscn
- [X] T007 [P] Create DroppedItem script with networking in pickups/DroppedItem.gd
- [X] T008 Enhance RealityZone with spawn point management in zones/RealityZone.gd
- [X] T009 Create PlayerRespawnWaitState for delay handling in player/states/PlayerRespawnWaitState.gd
- [X] T010 Enhance PlayerDeathState with item dropping in player/states/PlayerDeathState.gd

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Item Drop Synchronization (Priority: P1) 🎯 MVP

**Goal**: Fix critical multiplayer issue where items dropped by dying players don't appear for all connected clients

**Independent Test**: Have Player A die in snake-mode while Player B observes, verify items appear for both players and Player B can pick them up

### Implementation for User Story 1

- [X] T011 [US1] Implement request_player_death RPC in scripts/multiplayer/DeathSystem.gd
- [X] T012 [US1] Add death validation and processing logic in scripts/multiplayer/DeathSystem.gd  
- [X] T013 [P] [US1] Implement notify_player_death RPC broadcast in scripts/multiplayer/DeathSystem.gd
- [X] T014 [P] [US1] Implement notify_items_dropped RPC broadcast in scripts/multiplayer/DeathSystem.gd
- [X] T015 [US1] Add inventory item extraction in player/inventory/player_inventory.gd
- [X] T016 [US1] Enhance PlayerDeathState to trigger item drops in player/scripts/player_death_state.gd
- [X] T017 [US1] Implement DroppedItem network synchronization in pickups/DroppedItem.gd
- [X] T018 [US1] Add item pickup request handling in scripts/multiplayer/DeathSystem.gd
- [X] T019 [P] [US1] Implement notify_item_collected RPC in scripts/multiplayer/DeathSystem.gd
- [X] T020 [US1] Add server-side item pickup validation in scripts/multiplayer/DeathSystem.gd
- [X] T021 [US1] Connect death event to inventory system via SignalBus in _globals/SignalBus.gd

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Proper Respawn Location (Priority: P2)

**Goal**: Fix players respawning at death location instead of reality zone

**Independent Test**: Have player die outside reality zone and verify they respawn within reality zone boundaries

### Implementation for User Story 2

- [X] T022 [P] [US2] Add spawn point selection logic in zones/RealityZone.gd
- [X] T023 [P] [US2] Create SpawnManager utility in scripts/multiplayer/SpawnManager.gd
- [X] T024 [US2] Implement reality zone boundary validation in zones/RealityZone.gd
- [X] T025 [US2] Add server-side respawn location determination in scripts/multiplayer/DeathSystem.gd
- [X] T026 [US2] Implement notify_player_respawn_delay RPC in scripts/multiplayer/DeathSystem.gd
- [X] T027 [US2] Add respawn location selection to death processing in scripts/multiplayer/DeathSystem.gd
- [X] T028 [US2] Implement notify_player_respawned RPC broadcast in scripts/multiplayer/DeathSystem.gd
- [X] T029 [US2] Update Player.gd to handle respawn position from server in player/Player.gd
- [X] T030 [US2] Connect respawn system to RealityZone via SignalBus in _globals/SignalBus.gd

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Respawn Timing Control (Priority: P3)

**Goal**: Implement appropriate delay before respawning to create meaningful death consequences

**Independent Test**: Time the respawn process and verify delay meets configured duration requirements

### Implementation for User Story 3

- [X] T031 [P] [US3] Add respawn delay Timer management in scripts/multiplayer/DeathSystem.gd
- [X] T032 [P] [US3] Implement RespawnDelayTimer entity logic in player/scripts/player_respawn_wait_state.gd
- [X] T033 [US3] Add delay configuration constants in scripts/multiplayer/DeathSystem.gd
- [X] T034 [US3] Implement timer cleanup on player disconnect in scripts/multiplayer/DeathSystem.gd
- [X] T035 [US3] Add respawn delay to death processing flow in scripts/multiplayer/DeathSystem.gd
- [X] T036 [US3] Enhance PlayerRespawnWaitState with countdown logic in player/scripts/player_respawn_wait_state.gd
- [X] T037 [US3] Add timer expiration handling in scripts/multiplayer/DeathSystem.gd
- [X] T038 [US3] Connect delay system to respawn flow in scripts/multiplayer/DeathSystem.gd
- [X] T039 [US3] Add client-side respawn countdown UI integration via SignalBus in _globals/SignalBus.gd

**Checkpoint**: All user stories should now be independently functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [X] T040 [P] Add performance optimization: DroppedItem object pooling in pickups/DroppedItem.gd
- [X] T041 [P] Add item timeout and cleanup system in scripts/multiplayer/DeathSystem.gd
- [X] T042 [P] Implement spawn point cooldown management in zones/RealityZone.gd
- [X] T043 Add error handling for edge cases (no spawn points, network failures) in scripts/multiplayer/DeathSystem.gd
- [X] T044 Add rate limiting for death requests in scripts/multiplayer/DeathSystem.gd
- [X] T045 [P] Add logging for death events and debugging in scripts/multiplayer/DeathSystem.gd
- [X] T046 Performance validation: maintain 60 fps during death events
- [X] T047 Run quickstart.md validation with multiple clients ✅ COMPLETED

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - Core item synchronization functionality
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Uses DeathSystem from US1 but independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Builds on respawn system but independently testable

### Within Each User Story

- Core RPC infrastructure before specific implementations
- Server-side validation before client-side processing  
- Data models before service logic
- Service logic before UI integration
- Individual story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- RPC implementations marked [P] can run in parallel within each story
- Different file modifications marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch parallel RPC implementations for User Story 1:
Task: "Implement notify_player_death RPC broadcast in scripts/multiplayer/DeathSystem.gd"
Task: "Implement notify_items_dropped RPC broadcast in scripts/multiplayer/DeathSystem.gd"
Task: "Implement notify_item_collected RPC in scripts/multiplayer/DeathSystem.gd"

# Launch parallel file enhancements for User Story 1:
Task: "Add inventory item extraction in player/inventory/Inventory.gd"
Task: "Implement DroppedItem network synchronization in pickups/DroppedItem.gd"
```

---

## Parallel Example: User Story 2

```bash
# Launch parallel zone system enhancements for User Story 2:
Task: "Add spawn point selection logic in zones/RealityZone.gd"
Task: "Create SpawnManager utility in scripts/multiplayer/SpawnManager.gd"

# Launch parallel RPC implementations for User Story 2:
Task: "Implement notify_player_respawn_delay RPC in scripts/multiplayer/DeathSystem.gd"  
Task: "Update Player.gd to handle respawn position from server in player/Player.gd"
```

---

## Parallel Example: User Story 3

```bash
# Launch parallel timing system implementations for User Story 3:
Task: "Add respawn delay Timer management in scripts/multiplayer/DeathSystem.gd"
Task: "Implement RespawnDelayTimer entity logic in PlayerRespawnWaitState"
Task: "Add delay configuration constants in scripts/multiplayer/DeathSystem.gd"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently with server + 2 client instances
5. Deploy/demo item synchronization fix

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP - item synchronization fixed!)
3. Add User Story 2 → Test independently → Deploy/Demo (respawn location fixed!)
4. Add User Story 3 → Test independently → Deploy/Demo (full death system enhanced!)
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (item synchronization)
   - Developer B: User Story 2 (respawn location)
   - Developer C: User Story 3 (timing control)
3. Stories complete and integrate independently

---

## Manual Testing Protocol

### Testing Setup
- Use playground.tscn for all multiplayer testing
- Launch server: `godot --path . --headless`
- Launch 2-3 client instances for observation and interaction
- Test each user story independently before integration

### User Story 1 Testing
1. Player A dies in snake-mode with items while Player B watches
2. Verify items appear for both Player A and Player B
3. Have Player B pick up items, verify they disappear for both players
4. Have new Player C join game, verify existing items are visible

### User Story 2 Testing  
1. Player dies outside reality zone boundaries
2. Verify player respawns within reality zone (not at death location)
3. Test with multiple simultaneous deaths
4. Verify all players respawn in reality zone

### User Story 3 Testing
1. Time respawn delay from death to respawn
2. Verify delay matches configured duration (3-5 seconds)
3. Test that immediate respawn attempts are prevented
4. Verify automatic respawn after delay completion

### Performance Testing
- Monitor frame rate during death events with multiple players
- Verify system maintains 60 fps target
- Test with maximum concurrent deaths (stress testing)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Manual testing required after each checkpoint
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Focus: server-authoritative architecture with proper RPC usage
- Avoid: client-side authority, breaking state machine patterns