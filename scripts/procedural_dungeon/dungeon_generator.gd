class_name DungeonGenerator extends Node2D

## Drop this into a scene. It asks the dungeon generation manager to build
## a layout from the inspector knobs. Clients never generate locally.

@export_group("When to generate")
@export var generate_on_ready: bool = true
@export var generate_on_host_started: bool = true

@export_group("Layout")
@export var request_id: String = "dungeon"
@export var start_cell: Vector2i = Vector2i(2, 2)
@export var exit_cell: Vector2i = Vector2i(16, 16)
@export var bounds_origin: Vector2i = Vector2i.ZERO
@export var bounds_size: Vector2i = Vector2i(24, 24)
@export var profile_id: String = "standard"

@export_group("Rooms")
@export_range(3, 11, 2) var room_size: int = 5
@export_range(3, 8) var room_count: int = 4

var _requested: bool = false

func _ready() -> void:
	add_to_group("dungeon_generator")
	if generate_on_host_started:
		if not Lobby.host_started.is_connected(_on_host_started):
			Lobby.host_started.connect(_on_host_started)
	if generate_on_ready or generate_on_host_started:
		call_deferred("generate")

func _on_host_started(_player_name: String = "") -> void:
	generate()

func generate() -> void:
	if _requested:
		return
	if not _is_generation_authority():
		return
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager == null or not manager.has_method("request_generate_dungeon"):
		push_warning("DungeonGenerator: DungeonGenerationManager missing; skipped generate")
		return
	_requested = true
	manager.request_generate_dungeon(to_payload())

func regenerate() -> void:
	_requested = false
	generate()

func to_payload() -> Dictionary:
	return {
		"requestId": request_id,
		"startPosition": {"x": start_cell.x, "y": start_cell.y},
		"exitPosition": {"x": exit_cell.x, "y": exit_cell.y},
		"generationBounds": {
			"origin": {"x": bounds_origin.x, "y": bounds_origin.y},
			"size": {"x": bounds_size.x, "y": bounds_size.y}
		},
		"profileId": profile_id,
		"roomSize": room_size,
		"roomCount": room_count
	}

func _is_generation_authority() -> bool:
	if not multiplayer.has_multiplayer_peer():
		return generate_on_ready
	if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		return generate_on_ready
	return multiplayer.is_server()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if start_cell == exit_cell:
		warnings.append("Start cell and exit cell must be different.")
	if bounds_size.x < 16 or bounds_size.y < 16:
		warnings.append("Generation bounds must be at least 16x16.")
	var bounds := Rect2i(bounds_origin, bounds_size)
	if not bounds.has_point(start_cell) or not bounds.has_point(exit_cell):
		warnings.append("Start and exit must sit inside generation bounds.")
	if room_size % 2 == 0:
		warnings.append("Room size should be odd so rooms have a center cell.")
	return warnings
