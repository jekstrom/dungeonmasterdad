# AGENTS.md - Development Guidelines for Dungeon Master Dad

This file is **project conventions** for the **Dungeon Master Dad** Godot 4.7 multiplayer RPG: naming, architecture, multiplayer rules, and build commands. Do not copy skill procedures into this file.

For **general work**, follow the Grok skills in `.grok/skills/` (and Grok's bundled skills they name). Read the matching skill before implementing. Slash commands: `/<skill-name>` or `/skills <skill-name>`. Add a skill by copying `.grok/templates/skill/SKILL.md`. Docs: https://docs.x.ai/build/features/skills-plugins-marketplaces

| Skill | Use when |
|---|---|
| `/game-dev` | gameplay, content, feel, vertical slice |
| `/godot` | GDScript, `.tscn`, spawners, y-sort, dungeon generator |
| `/testing` | headless contract tests, host+client join, QA |
| `/create-sprite-animation` | 128px character sheets: down/side/up × 4 frames |
| `/setup-godot-2d-sprite-animation` | wire Sprite2D / AnimationPlayer / SpriteFrames |
| `/generate-2d-sprite-sheet` | generic 3/4 64/128 sheets (not the 3-dir 4-frame contract) |

Default art/animation for this game is `/create-sprite-animation`, then `/setup-godot-2d-sprite-animation` to hook it up. `/game-dev` also points at bundled `game-asset-core` specialists for tiles, UI, and identity.

## 🎮 Project Overview

- **Engine**: Godot 4.7 (Forward Plus rendering)
- **Language**: GDScript (primary)
- **Type**: Multiplayer dungeon master/RPG game
- **Network**: ENet multiplayer on port 42069
- **Architecture**: State machine-based with singleton managers
- **Main scene**: `playground.tscn` (lobby Start/Join, then generated dungeon)

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
# Procedural dungeon contract test (headless)
godot --path /home/james/dungeon-master-dad --headless --quit-after 20 \
  test_harness/procedural_dungeon/room_knobs_test.tscn

# Two-instance playtest: editor Run Multiple Instances, or:
./start_server.sh    # terminal 1
./start_client.sh    # terminal 2

# Network harness (not playground):
cd test_harness && ./run_tests.sh quick
```

Use `/testing` for which check matches a change and for join-log failures.

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
- **Character systems**: `player/`, `dm/`, `monsters/`
- **UI components**: `gui/` with subdirectories for different UIs
- **Game systems**: `buildings/`, `pickups/`, `spells/`, `zones/`, `level/`
- **Procedural dungeon**: `scripts/procedural_dungeon/`, scene node `scenes/dungeon_generator.tscn`
- **Shared utilities**: `scripts/` directory
- **Grok skills (general workflows)**: `.grok/skills/` — see the table at the top of this file

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
- Never use comments

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

- Headless contract tests: `test_harness/procedural_dungeon/` (attach the `.gd` to a `.tscn`; do not use a bare `.gd` as the main scene).
- Playground host+client: `DungeonGenerator.generate_on_ready` must stay false so both instances do not generate on `OfflineMultiplayerPeer`.
- Treat client-join `_update_spawn_visibility ERR_BUG`, `on_spawn_receive has_node`, and invalid `on_delta_receive` as failures.
- Use `Lobby.is_network_server()` when "are we the real host?" matters; `multiplayer.is_server()` is true for the default offline peer.
- Playtest movement/y-sort/collision in `playground.tscn`; test buildings in reality zones.

## 🚨 Critical Notes for AI Agents

### Multiplayer Considerations
- Always check `is_multiplayer_authority()` before client-specific actions
- Validate server authority for game-changing operations
- Use RPC appropriately - don't break client-server authority model
- Test networking code with multiple instances
- `MultiplayerSpawner` only auto-replicates **direct** children of `spawn_path`
- Do not generate dungeons or spawn catalog scenes on a client; tiles live under `GeneratedTiles`

### Godot 4.7
- No `Node2D.y_sort_origin`. Sort at the node origin (south foot) with sprite `offset`.
- Dungeon layout knobs: `DungeonGenerator` inspector (`room_size`, `room_count`, start/exit, bounds), not `level_manager.gd`.

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
- GDScript / Godot 4.7 (Forward Plus rendering) + ENet multiplayer on port 42069, Godot's built-in networking system, SignalBus singleton (001-fix-snake-death)
- Scene (.tscn) files and Resource (.tres) files for game data persistence (001-fix-snake-death)
- GDScript / Godot 4.7 (Forward Plus rendering) + ENet multiplayer on port 42069, Godot's built-in networking system, MultiplayerSynchronizer nodes (002-snake-multiplayer-sync)
- GDScript / Godot 4.7 (Forward Plus rendering) + Godot ENet multiplayer (port 42069), existing level scenes (`level/floor.tscn`, `level/wall.tscn`), existing monster scenes under `monsters/`, existing multiplayer spawner flow (`scripts/multiplayer_spawner.gd`) (001-procedural-dungeon-generator)
- In-memory generation output represented in scene graph and existing resources (`.tscn`/`.tres`) (001-procedural-dungeon-generator)
- `DungeonGenerator` node (`scenes/dungeon_generator.tscn`) for per-scene layout knobs (001-procedural-dungeon-generator)

## Recent Changes
- 001-fix-snake-death: Added GDScript / Godot 4.5 (Forward Plus rendering) + ENet multiplayer on port 42069, Godot's built-in networking system, SignalBus singleton
