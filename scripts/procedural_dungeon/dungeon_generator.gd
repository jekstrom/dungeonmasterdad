class_name DungeonGenerator extends Node2D

## Drop this into a scene. It asks the dungeon generation manager to build
## a layout from the inspector knobs. Clients never generate locally.

@export_group("When to generate")
@export var generate_on_ready: bool = true
@export var generate_on_host_started: bool = true

@export_group("Layout")
@export var request_id: String = "dungeon"
@export var start_cell: Vector2i = Vector2i(21, 12)
@export var exit_cell: Vector2i = Vector2i(2, 12)
@export var bounds_origin: Vector2i = Vector2i.ZERO
@export var bounds_size: Vector2i = Vector2i(24, 24)
@export_range(0, 128) var overworld_size: int = DungeonConstants.DEFAULT_OVERWORLD_SIZE
@export var profile_id: String = "standard"

@export_group("Rooms")
@export_range(3, 11, 2) var room_size: int = 5
@export_range(3, 8) var room_count: int = 4
@export var auto_place_portals: bool = false
@export_range(0.0, 1.0, 0.05) var braid_rate: float = DungeonConstants.DEFAULT_BRAID_RATE

@export_group("Pickups")
@export_range(0, 16) var start_room_dew_count: int = DungeonConstants.DEFAULT_START_ROOM_DEW_COUNT
@export_range(0, 16) var extra_dew_count: int = DungeonConstants.DEFAULT_EXTRA_DEW_COUNT
@export_range(0, 16) var d6_count: int = DungeonConstants.DEFAULT_D6_COUNT
@export_range(0, 16) var d20_count: int = DungeonConstants.DEFAULT_D20_COUNT

var _requested: bool = false

func _ready() -> void:
	add_to_group("dungeon_generator")
	if generate_on_host_started:
		if not Lobby.host_started.is_connected(_on_host_started):
			Lobby.host_started.connect(_on_host_started)
	if not SignalBus.dungeon_generation_failed.is_connected(_on_generation_failed):
		SignalBus.dungeon_generation_failed.connect(_on_generation_failed)
	if not SignalBus.dungeon_generation_succeeded.is_connected(_on_generation_succeeded):
		SignalBus.dungeon_generation_succeeded.connect(_on_generation_succeeded)
	if generate_on_ready or generate_on_host_started:
		call_deferred("generate")

func _on_host_started(_player_name: String = "") -> void:
	generate()


func _on_generation_succeeded(_request_id: String, _layout_id: String) -> void:
	_requested = true


func _on_generation_failed(_request_id: String, _error_code: String, _message: String) -> void:
	_requested = false

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
		"roomCount": room_count,
		"startRoomDewCount": start_room_dew_count,
		"extraDewCount": extra_dew_count,
		"d6Count": d6_count,
		"d20Count": d20_count,
		"braidRate": braid_rate,
		"autoPlacePortals": auto_place_portals,
		"overworldSize": overworld_size
	}

func _is_generation_authority() -> bool:
	if not multiplayer.has_multiplayer_peer():
		return generate_on_ready
	if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		return generate_on_ready
	return multiplayer.is_server()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if bounds_size.x < 16 or bounds_size.y < 16:
		warnings.append("Generation bounds must be at least 16x16.")
	var bounds := Rect2i(bounds_origin, bounds_size)
	if not auto_place_portals:
		if start_cell == exit_cell:
			warnings.append("Start cell and exit cell must be different.")
		if not bounds.has_point(start_cell) or not bounds.has_point(exit_cell):
			warnings.append("Start and exit must sit inside generation bounds.")
	if room_size % 2 == 0:
		warnings.append("Room size should be odd so rooms have a center cell.")
	if overworld_size != 0 and overworld_size < DungeonConstants.MIN_OVERWORLD_SIZE:
		warnings.append("Overworld size must be 0 (auto) or at least 16.")
	return warnings
