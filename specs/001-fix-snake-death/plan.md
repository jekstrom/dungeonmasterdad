# Implementation Plan: Fix Snake-Mode Death System

**Branch**: `001-fix-snake-death` | **Date**: February 5, 2026 | **Spec**: [Feature Specification](spec.md)
**Input**: Feature specification from `/specs/001-fix-snake-death/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Fix critical multiplayer synchronization issue where items dropped by dying players in snake-mode only appear for the client, not all connected players. The technical approach involves consolidating the dual item drop systems (DeathSystem vs PlayerManager) to use a single server-authoritative RPC-based approach that ensures proper multiplayer synchronization.

## Technical Context

**Language/Version**: GDScript / Godot 4.5 (Forward Plus rendering)  
**Primary Dependencies**: ENet multiplayer on port 42069, Godot's built-in networking system, SignalBus singleton  
**Storage**: Scene (.tscn) files and Resource (.tres) files for game data persistence  
**Testing**: Manual testing with multiple player instances (server + clients) using playground.tscn  
**Target Platform**: Linux desktop (with cross-platform compatibility)  
**Project Type**: Real-time multiplayer game - requires server-authoritative architecture  
**Performance Goals**: Maintain 60 fps with multiple players, <1 second item drop synchronization  
**Constraints**: Server-authoritative model, reliable RPC for critical events, unreliable RPC for frequent updates  
**Scale/Scope**: Small-scale multiplayer (2-8 concurrent players), existing codebase with established patterns

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Initial Check (Pre-Research): ✅ PASSED

**Multiplayer Authority Check**: ✅ PASS - Fix maintains server-authoritative architecture. Server validates all death events and item drops. RPC synchronization ensures all clients receive item spawn notifications. No client predictions affect game state.

**State Machine Impact**: ✅ PASS - Fix works within established state machine patterns. PlayerSnakeState triggers death → PlayerDeathState processes → PlayerRespawnWaitState delays → PlayerIdleState resumes. No state machine changes required.

**Performance Impact**: ✅ PASS - Fix consolidates dual systems, reducing code paths. Item drop quantity is already capped at 50 items. No additional processing overhead. Memory usage reduced by eliminating redundant PlayerManager.drop_all_inventory().

**Code Quality Standards**: ✅ PASS - Implementation follows GDScript typing and naming conventions. Uses established RPC patterns. Maintains file organization in scripts/multiplayer/ for centralized death handling.

**Testing Requirements**: ✅ PASS - Issue is specifically about multiplayer synchronization, requiring server + client testing. Manual testing strategy: Player A dies in snake-mode while Player B observes, verify items appear for both players.

### Post-Design Re-evaluation: ✅ CONFIRMED PASS

**Multiplayer Authority Check**: ✅ CONFIRMED - Design maintains single server authority via DeathSystem. RPC contract clearly specifies server validation and broadcast patterns. No client-side game state modifications introduced.

**State Machine Impact**: ✅ CONFIRMED - Design preserves existing state flow, only changing the routing mechanism. PlayerSnakeState.handle_trail_death() modification doesn't affect state transitions or Enter()/Exit() patterns.

**Performance Impact**: ✅ CONFIRMED - Design eliminates PlayerManager fallback complexity (50+ lines of MultiplayerSpawner detection logic). Single DeathSystem code path reduces CPU overhead. Network traffic identical (same RPC patterns).

**Code Quality Standards**: ✅ CONFIRMED - Solution is minimal 2-line change following established patterns. No new files needed. Maintains type safety and server-authoritative validation.

**Testing Requirements**: ✅ CONFIRMED - Manual testing strategy defined in quickstart.md. Uses playground.tscn with multiple instances. Clear verification criteria established.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# Godot 4.5 Project Structure
_globals/                               # Singleton autoloads
├── player_manager.gd                   # Legacy item drop system
├── signal_bus.gd                      # Global event system
├── trail_manager.gd                   # Snake trail management
└── item_database.gd                   # Item data resources

scripts/multiplayer/                   # Server-authoritative systems  
└── DeathSystem.gd                     # Modern death/item drop system

player/                                # Player character systems
├── scripts/
│   ├── player_snake_state.gd         # Snake mode logic and death triggers
│   ├── player_death_state.gd         # Death state processing
│   └── player_respawn_wait_state.gd  # Respawn delay management
└── inventory/
    └── player_inventory.gd           # Inventory data management

pickups/                              # Item pickup systems
├── pickup.tscn                       # Regular pickup scene
├── scripts/
│   └── item_pickup.gd               # Pickup interaction logic
└── effects/                         # Pickup visual/audio effects

zones/                               # Game area definitions
└── scripts/
    └── zone.gd                      # Reality zone implementation
```

**Structure Decision**: The codebase follows Godot's established directory structure with clear separation between global singletons, character-specific systems, and game objects. The issue involves coordination between the legacy PlayerManager system and the newer DeathSystem.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
