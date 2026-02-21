# Dungeon Master Dad

Dungeon Master Dad is a Godot 4.5 multiplayer RPG where a dungeon master and players share a session in a state machine-driven world. The project uses ENet networking on port 42069 and relies on singleton managers for core systems.

## Build (Export)

Godot exports are performed via the CLI. Ensure you have the Godot 4.5 export templates installed first.

```bash
godot --path /path/to/dungeon-master-dad --export-release "Linux/X11"
```

## Run (CLI)

Run the main project directly with Godot:

```bash
godot --path /path/to/dungeon-master-dad
```

Run in headless mode (server):

```bash
godot --path /path/to/dungeon-master-dad --headless
```
