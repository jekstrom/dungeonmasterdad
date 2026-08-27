extends MultiplayerSpawner

const MonsterCatalog = preload("res://scripts/procedural_dungeon/monster_catalog.gd")
const TileCatalog = preload("res://scripts/procedural_dungeon/tile_catalog.gd")

const FLOOR_Z_INDEX := -1
const WALL_Z_INDEX := 0

@export var network_player: PackedScene
@export var dm_player: PackedScene
@export var gremlin: PackedScene
@export var fireball_spell: PackedScene
@export var knight: PackedScene

var _monster_catalog: MonsterCatalog = MonsterCatalog.new()
var _tile_catalog: TileCatalog = TileCatalog.new()

func _enter_tree() -> void:
	# Server is always peer 1. Set on every peer in _enter_tree (not only
	# is_server / after the peer exists) so MultiplayerSpawner spawn
	# visibility does not ERR_BUG on clients:
	# scene_replication_interface.cpp _update_spawn_visibility.
	set_multiplayer_authority(1)

func _ready() -> void:
	add_to_group("multiplayer_spawner")
	set_multiplayer_authority(1)

	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.peer_connected.is_connected(_on_peer_connected_authority):
		multiplayer.peer_connected.connect(_on_peer_connected_authority)

	# Only server should handle hosting and spawning
	if multiplayer.is_server():
		Lobby.host_started.connect(spawn_host_player)
		DmManager.spawn_gremlin_cast.connect(spawn_gremlin)
		DmManager.spawn_knight_cast.connect(spawn_knight)

func _on_connected_to_server() -> void:
	set_multiplayer_authority(1)
	on_connected_ok()

func _on_peer_connected_authority(_id: int) -> void:
	set_multiplayer_authority(1)

func on_connected_ok():
	var id = multiplayer.get_unique_id()
	spawn_player.rpc(id, PlayerData.player_name)

@rpc("any_peer", "reliable")
func spawn_player(id: int, player_name: String) -> void:
	if !multiplayer.is_server(): return
	
	# Check if player already exists and remove if so
	var existing_player = get_node(spawn_path).get_node_or_null(str(id))
	if existing_player:
		print("Removing existing player ", id, " before spawning new one")
		existing_player.queue_free()
		await existing_player.tree_exited
	
	await get_tree().process_frame
	
	var player: Node = network_player.instantiate()
	
	if !player_name or player_name.is_empty():
		player_name = "Paper Pusher"
	
	player.name = str(id)
	print("spawning player ", id, " ", player_name)
	player.sync_name = player_name
	
	var name_hash = player_name.hash()
	var rng = RandomNumberGenerator.new()
	rng.seed = name_hash
	var hue = rng.randf() 
	player.sync_color = Color.from_hsv(hue, 0.6, 0.9)
	
	get_node(spawn_path).add_child(player, true)
	player.add_to_group("players")
	PlayerManager.register_player(id, player_name)
	sync_global_state.rpc_id(id, DmManager.fantasy_level)

func spawn_gremlin() -> void:
	if !multiplayer.is_server(): return
	
	print("spawning gremlin")
	
	var new_gremlin: Node = gremlin.instantiate()

	get_node(spawn_path).call_deferred("add_child", new_gremlin, true)

func spawn_knight() -> void:
	if !multiplayer.is_server(): return
	
	print("spawning knight")
	
	var new_knight: Node = knight.instantiate()

	get_node(spawn_path).call_deferred("add_child", new_knight, true)
	
func cast_spell(spell_id: String) -> void:
	if !multiplayer.is_server(): return
	
	print("casting spell ", spell_id)
	
	var spell: Node = fireball_spell.instantiate()

	get_node(spawn_path).call_deferred("add_child", spell, true)

func spawn_monster_from_scene_path(scene_path: String, world_position: Vector2, spawn_id: String = "") -> Node2D:
	if !multiplayer.is_server():
		return null

	if scene_path.is_empty() or not _monster_catalog.is_approved_scene_path(scene_path):
		push_warning("MultiplayerSpawner: monster scene path is not in catalog: %s" % scene_path)
		return null

	var packed_scene: PackedScene = load(scene_path)
	if not packed_scene:
		push_warning("MultiplayerSpawner: failed to load monster scene: %s" % scene_path)
		return null

	var monster: Node2D = packed_scene.instantiate() as Node2D
	if not monster:
		push_warning("MultiplayerSpawner: failed to instantiate monster scene: %s" % scene_path)
		return null

	monster.position = world_position
	if not spawn_id.is_empty():
		monster.set_meta("generated_spawn_id", spawn_id)
	monster.add_to_group("generated_dungeon_monsters")

	# Synchronous add_child so swap-on-success commit/rollback is not racing a deferred spawn.
	get_node(spawn_path).add_child(monster, true)
	return monster

func spawn_tile_from_scene_path(scene_path: String, world_position: Vector2, variant_id: int = -1, wall_frame: int = -1) -> Node2D:
	if !multiplayer.is_server():
		return null

	if scene_path.is_empty() or not _tile_catalog.is_approved_scene_path(scene_path):
		push_warning("MultiplayerSpawner: tile scene path is not in catalog: %s" % scene_path)
		return null

	var packed_scene: PackedScene = load(scene_path)
	if not packed_scene:
		push_warning("MultiplayerSpawner: failed to load tile scene: %s" % scene_path)
		return null

	var tile: Node2D = packed_scene.instantiate() as Node2D
	if not tile:
		push_warning("MultiplayerSpawner: failed to instantiate tile scene: %s" % scene_path)
		return null

	tile.position = world_position
	tile.add_to_group("generated_dungeon_tiles")
	if "wall_type" in tile:
		if variant_id >= 0:
			tile.wall_type = 2 if variant_id == 2 else 1
		if "wall_frame" in tile and wall_frame >= 0:
			tile.wall_frame = wall_frame
		tile.z_index = WALL_Z_INDEX
	elif "floor_type" in tile:
		if variant_id >= 0:
			tile.floor_type = clampi(variant_id, 0, 1)
		tile.z_index = FLOOR_Z_INDEX

	get_node(spawn_path).add_child(tile, true)
	return tile

func spawn_host_player(player_name: String) -> void:
	if !multiplayer.is_server(): return
	
	print("spawning dm player")
	if !player_name or player_name.is_empty():
		player_name = "DM"
	
	var dm: Node = dm_player.instantiate()
	dm.name = "dm"
	DmManager.dm_player_name = player_name
	
	get_node(spawn_path).call_deferred("add_child", dm)
	dm.add_to_group("dm")
	PlayerManager.register_player(1, player_name)
	
	for i in range(0, 10):  # Reduced number for testing
		var item_data = {
			"item_type" = "res://pickups/metal.tres",
			"position" = Vector2(i + 1 * 50, i * 30),  # Spread them out more
		}
		SignalBus.on_item_drop.emit(item_data)
		
	var cloak_data = {
		"item_type" = "res://pickups/cloak.tres",
		"position" = Vector2(-50, 15),  # Spread them out more
	}
	SignalBus.on_item_drop.emit(cloak_data)
		
@rpc("authority", "call_local", "reliable")
func sync_global_state(f: int):
	DmManager.fantasy_level = f
