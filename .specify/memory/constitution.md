<!--
Sync Impact Report:
Version change: Initial constitution → 1.0.0
Modified principles:
- Added I. Multiplayer Authority (NON-NEGOTIABLE)
- Added II. State Machine Integrity
- Added III. Code Quality & Type Safety
- Added IV. Performance First
- Added V. Resource & Scene Management
Added sections:
- Multiplayer Standards
- Development Workflow
- Governance rules
Removed sections: None
Templates requiring updates:
- ✅ plan-template.md (Constitution Check section updated)
- ✅ spec-template.md (verified alignment)
- ✅ tasks-template.md (verified alignment)
- ✅ All command templates (verified alignment)
Follow-up TODOs: None - all placeholders filled
-->

# Dungeon Master Dad Constitution

## Core Principles

### I. Multiplayer Authority (NON-NEGOTIABLE)
Server-authoritative architecture MUST be maintained at all times. All game-changing operations MUST be validated server-side before execution. Clients send input via RPC to server; server validates and broadcasts state changes. Client predictions are permitted ONLY for UI/visual feedback that do not affect game state. RPC usage MUST respect authority model: clients request, server validates and broadcasts results.

**Rationale**: Multiplayer games require authoritative control to prevent cheating and ensure consistent game state across all clients. This is foundational to the game's integrity.

### II. State Machine Integrity
State machines are the foundation of all character behavior and MUST be maintained with strict discipline. Only one state can be active per character at any time. State transitions MUST be explicit with proper Enter() and Exit() calls. All input processing MUST be handled within the state's HandleInput() method. State transitions return the next state or null - no exceptions.

**Rationale**: The established state machine architecture ensures predictable character behavior and simplified debugging in a multiplayer environment.

### III. Code Quality & Type Safety
GDScript types MUST always be specified when possible (`var health: int = 100`). Variable and function names MUST be descriptive (`cardinal_direction` not `dir`). File organization patterns established in AGENTS.md MUST be followed. Class structure MUST be consistent: constants first, then exported variables, private variables, onready variables, signals, and functions in the specified order.

**Rationale**: Type safety prevents runtime errors and improves code maintainability. Consistent structure makes the codebase approachable for all developers.

### IV. Performance First
The game MUST run smoothly with multiple players (60 fps target). Use `@onready` for node caching to avoid repeated lookups. Objects that are frequently created and destroyed MUST be pooled. Work in `_process()` and `_physics_process()` MUST be minimized. Expensive calculations MUST be cached when possible. Performance regressions are considered blocking issues.

**Rationale**: Real-time multiplayer games require consistent performance to provide a good user experience. Performance issues compound with multiple players.

### V. Resource & Scene Management
Node path references MUST use `@onready var` for proper initialization timing. Resources MUST be cleaned up in `_exit_tree()` to prevent memory leaks. Parent-child relationships MUST be maintained carefully - do not hard-code node access. Scene inheritance SHOULD be leveraged for similar objects. Groups SHOULD be used for finding nodes by category rather than manual tree traversal.

**Rationale**: Godot's scene system requires careful resource management. Proper cleanup prevents memory leaks and performance degradation over time.

## Multiplayer Standards

All networked code MUST check `is_multiplayer_authority()` before performing client-specific actions. Server authority MUST be validated for game-changing operations using `if not multiplayer.is_server(): return`. RPC functions MUST be documented with their purpose and authority requirements. Remote sender identification MUST use `multiplayer.get_remote_sender_id()` when needed.

Testing with multiple instances (server + clients) is MANDATORY for any multiplayer functionality changes. Use reliable RPCs for critical data and unreliable RPCs for frequent updates. Network code changes require validation that the client-server authority model remains intact.

## Development Workflow

Manual testing is the current standard as no automated testing framework is configured. Feature testing MUST use `playground.tscn` as the development testing environment. State machine transitions MUST be validated manually for each character type. Building placement MUST be tested in reality zones. Inventory and item pickup systems MUST be verified in multiplayer scenarios.

All multiplayer functionality MUST be tested by running server and client instances. State consistency MUST be verified across all connected clients. Performance testing MUST include multiple players to identify scalability issues.

## Governance

This constitution supersedes all other development practices when conflicts arise. The AGENTS.md file provides implementation details but this constitution defines the non-negotiable principles.

All code changes MUST verify multiplayer stability before merging. Performance regressions are blocking issues that require immediate resolution. State machine changes require careful review to ensure they don't break character behavior integrity.

Amendments to this constitution require documentation of the change rationale, stakeholder approval, and a migration plan for existing code that may be affected. Constitution violations in code reviews MUST be addressed before approval.

**Version**: 1.0.0 | **Ratified**: 2026-02-05 | **Last Amended**: 2026-02-05