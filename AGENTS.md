# AGENTS.md - Development Guidelines for Dungeon Master Dad

This file contains development guidelines, coding standards, and build instructions for AI coding agents working on the **Dungeon Master Dad** Godot 4.5 multiplayer RPG game.

## 🎮 Project Overview

- **Engine**: Godot 4.5 (Forward Plus rendering)
- **Language**: GDScript (primary)
- **Type**: Multiplayer dungeon master/RPG game
- **Network**: ENet multiplayer on port 42069
- **Architecture**: State machine-based with singleton managers

## 🔧 Build & Development Commands

### Running the Game
```bash
# Run the main game scene
godot --path /home/james/dungeon-master-dad

# Run in headless mode (server)
godot --path /home/james/dungeon-master-dad --headless

# Export the project (requires export templates)
godot --path /home/james/dungeon-master-dad --export-release "Linux/X11"
```

### Testing
```bash
# Currently no automated test framework is configured
# Manual testing through running the game scenes:
# - game.tscn (main game)
# - playground.tscn (development testing)
```

### Development Tools
```bash
# Open Godot editor for this project
godot --path /home/james/dungeon-master-dad --editor

# Import/re-import assets
godot --path /home/james/dungeon-master-dad --import
```

## 📝 Code Style Guidelines

### File Organization
- **Global singletons**: `_globals/` directory, loaded via autoload
- **Character systems**: `player/`, `dm/`, `goblin/` directories
- **UI components**: `gui/` with subdirectories for different UIs
- **Game systems**: `buildings/`, `pickups/`, `spells/`, `zones/`
- **Shared utilities**: `scripts/` directory

### Naming Conventions
- **Files**: `snake_case.gd` (e.g., `player_idle_state.gd`)
- **Classes**: `PascalCase` (e.g., `PlayerIdleState`)
- **Variables**: `snake_case` (e.g., `cardinal_direction`, `max_hp`)
- **Functions**: `snake_case` (e.g., `update_animation()`, `set_direction()`)
- **Constants**: `UPPER_SNAKE_CASE` (e.g., `DIR_4`, `PORT`)
- **Signals**: `snake_case` (e.g., `DirectionChanged`, `inventory_updated`)
- **Node paths**: Use `@onready var` with descriptive names

### Class Structure
```gdscript
class_name ClassName extends BaseClass

# Constants first
const CONSTANT_VALUE = 42

# Exported variables
@export var exported_var: int = 10
@export var exported_scene: PackedScene

# Private variables
var private_var: bool = false
var another_var: Vector2 = Vector2.ZERO

# Onready variables
@onready var node_ref: Node2D = $NodePath
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Signals
signal signal_name(parameter: Type)

# Functions in order: _enter_tree, _ready, _process, _physics_process, _input, public, private, RPCs
```

### Variable Declarations
- Always specify types when possible: `var health: int = 100`
- Use descriptive names: `cardinal_direction` not `dir`
- Initialize with defaults: `var invulnerable: bool = false`
- Use `@onready var` for node references

### State Machine Pattern
Follow the established state machine architecture:
```gdscript
# Base state class
class_name StateBase extends Node

func Enter() -> void:
    pass
    
func Exit() -> void:
    pass
    
func Process(_delta: float) -> StateBase:
    return null
    
func Physics(_delta: float) -> StateBase:
    return null
    
func HandleInput(_event: InputEvent) -> StateBase:
    return null
```

### Multiplayer Code
- Use `@rpc()` annotations for networked functions
- Check `is_multiplayer_authority()` for client-specific code
- Validate server-side: `if not multiplayer.is_server(): return`
- Get remote sender: `multiplayer.get_remote_sender_id()`

### Signal Usage
- Connect signals in `_ready()` function
- Use descriptive signal names with parameters typed
- Emit signals for loose coupling between systems
- Use SignalBus singleton for global events

### Error Handling
- Use `@warning_ignore()` for intentional warnings
- Check node existence with `get_node_or_null()`
- Validate resources before use
- Handle multiplayer authority checks

### Comments
- Use `#` for single-line comments
- Document complex algorithms and multiplayer logic
- Explain state machine transitions
- Comment RPC functions and their purpose

### Resource Management
- Use `class_name` for custom resource types
- Store data in `.tres` files for game data
- Preload scenes with `@export var scene: PackedScene`
- Use resource paths consistently: `"res://path/to/resource"`

## 🏗️ Architecture Patterns

### Singleton Managers (Autoloads)
The project uses extensive singleton pattern via Godot's autoload system:
- `SignalBus`: Global signal management
- `PlayerManager`, `DmManager`: Character management
- `ItemDatabase`, `BuildingDatabase`: Game data storage
- `AudioManager`: Centralized audio control
- `BuildingManager`: Building placement logic

### Scene Organization
```
Character scenes (Player, DM, Goblin):
├── CharacterBody2D (main script)
├── Sprite2D (visual representation)
├── CollisionShape2D (physics)
├── Camera2D (for players)
├── StateMachine (state management)
└── UI elements (labels, etc.)
```

### Networking Pattern
- Server authoritative for game logic
- Clients send input via RPC to server
- Server validates and broadcasts state changes
- Use reliable RPCs for critical data, unreliable for frequent updates

## 🧪 Testing Guidelines

Since no automated testing framework is currently set up:
- Test multiplayer by running server + client instances
- Use `playground.tscn` for feature testing
- Validate state machine transitions manually
- Test building placement in reality zones
- Verify inventory and item pickup systems

## 🚨 Critical Notes for AI Agents

### Multiplayer Considerations
- Always check `is_multiplayer_authority()` before client-specific actions
- Validate server authority for game-changing operations
- Use RPC appropriately - don't break client-server authority model
- Test networking code with multiple instances

### State Machine Rules
- Only one state can be active at a time
- State transitions return the next state or null
- Always call `Enter()` and `Exit()` on state changes
- Process input in state's `HandleInput()` method

### Scene Management
- Maintain parent-child relationships carefully
- Use proper node paths with `@onready var`
- Don't hard-code node access - use references
- Clean up resources in `_exit_tree()`

### Performance
- Use `@onready` for node caching
- Minimize `_process()` and `_physics_process()` work
- Pool objects for frequently created/destroyed items
- Cache expensive calculations

### Godot-Specific Best Practices
- Prefer Godot's built-in types (Vector2, PackedScene, etc.)
- Use Godot's signal system over polling
- Leverage scene inheritance for similar objects
- Use Groups for finding nodes by category
- Respect Godot's coordinate system (Y-down for 2D)

## 🎯 Development Priorities

When making changes, consider:
1. **Multiplayer stability** - Don't break networking
2. **State consistency** - Maintain state machine integrity  
3. **Performance** - Game runs smoothly with multiple players
4. **Code organization** - Follow established patterns
5. **Resource management** - Proper cleanup and pooling

Remember: This is a multiplayer game where synchronization and authority are critical. Always test changes in multiplayer scenarios.

## Active Technologies
- GDScript / Godot 4.5 (Forward Plus rendering) + ENet multiplayer on port 42069, Godot's built-in networking system, SignalBus singleton (001-fix-snake-death)
- Scene (.tscn) files and Resource (.tres) files for game data persistence (001-fix-snake-death)
- GDScript / Godot 4.5 (Forward Plus rendering) + ENet multiplayer on port 42069, Godot's built-in networking system, MultiplayerSynchronizer nodes (002-snake-multiplayer-sync)
- GDScript / Godot 4.5 (Forward Plus rendering) + Godot ENet multiplayer (port 42069), existing level scenes (`level/floor.tscn`, `level/wall.tscn`), existing monster scenes under `monsters/`, existing multiplayer spawner flow (`scripts/multiplayer_spawner.gd`) (001-procedural-dungeon-generator)
- In-memory generation output represented in scene graph and existing resources (`.tscn`/`.tres`) (001-procedural-dungeon-generator)

## Recent Changes
- 001-fix-snake-death: Added GDScript / Godot 4.5 (Forward Plus rendering) + ENet multiplayer on port 42069, Godot's built-in networking system, SignalBus singleton
