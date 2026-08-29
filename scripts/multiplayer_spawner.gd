extends MultiplayerSpawner

#const MonsterCatalog = preload("res://scripts/procedural_dungeon/monster_catalog.gd")
#const TileCatalog = preload("res://scripts/procedural_dungeon/tile_catalog.gd")
#const DungeonConstants = preload("res://scripts/procedural_dungeon/dungeon_constants.gd")

const FLOOR_Z_INDEX := DungeonConstants.FLOOR_Z_INDEX
const WALL_Z_INDEX := DungeonConstants.WALL_Z_INDEX

@export var network_player: PackedScene
@export var dm_player: PackedScene
@export var gremlin: PackedScene
@export var fireball_spell: PackedScene
@export var knight: PackedScene

var _monster_catalog: MonsterCatalog = MonsterCatalog.new()
var _tile_catalog: TileCatalog = TileCatalog.new()
var _manual_spawn_seq: int = 0

func _enter_tree() -> void:
	# Server is always peer 1. Set on every peer in _enter_tree (not only
	# is_server / after the peer exists) so MultiplayerSpawner spawn
	# visibility does not ERR_BUG on clients:
	# scene_replication_interface.cpp _update_spawn_visibility.
	set_multiplayer_authority(1)

func _ready() -> void:
	add_to_group("multiplayer_spawner")
	set_multiplayer_authority(1)
	# US-017 T001: register in code so playground.tscn does not have to list the boss.
	add_spawnable_scene("res://monsters/baja_boss.tscn")

	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.peer_connected.is_connected(_on_peer_connected_authority):
		multiplayer.peer_connected.connect(_on_peer_connected_authority)

	# Connect regardless of the default OfflineMultiplayerPeer. Handlers
	# still no-op unless this peer is the real network server.
	if not Lobby.host_started.is_connected(spawn_host_player):
		Lobby.host_started.connect(spawn_host_player)
	if not DmManager.spawn_gremlin_cast.is_connected(spawn_gremlin):
		DmManager.spawn_gremlin_cast.connect(spawn_gremlin)
	if not DmManager.spawn_knight_cast.is_connected(spawn_knight):
		DmManager.spawn_knight_cast.connect(spawn_knight)
	if not SignalBus.dungeon_generation_succeeded.is_connected(_on_dungeon_generation_succeeded):
		SignalBus.dungeon_generation_succeeded.connect(_on_dungeon_generation_succeeded)

func _on_connected_to_server() -> void:
	set_multiplayer_authority(1)
	on_connected_ok()

func _on_peer_connected_authority(id: int) -> void:
	set_multiplayer_authority(1)
	if multiplayer.is_server():
		sync_generated_tiles_to_peer(id)
		_sync_global_state_to_peer(id)
		var dungeon: Node = get_node_or_null("/root/DungeonGenerationManager")
		if dungeon and dungeon.has_method("sync_fountain_to_peer"):
			dungeon.call("sync_fountain_to_peer", id)

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
	player.position = _west_spawn_world()
	get_node(spawn_path).add_child(player, true)
	player.add_to_group("players")
	PlayerManager.register_player(id, player_name)
	_sync_global_state_to_peer(id)

func _west_spawn_world() -> Vector2:
	var level: Node = get_tree().get_first_node_in_group("level_manager")
	if level and level.has_method("take_west_spawn_world"):
		return level.take_west_spawn_world()
	return Vector2(DungeonGrid.CELL_PX * 0.5, DungeonGrid.CELL_PX * 0.5)

func spawn_gremlin() -> void:
	if !multiplayer.is_server(): return
	
	print("spawning gremlin")
	
	var new_gremlin: Node = gremlin.instantiate()
	_manual_spawn_seq += 1
	new_gremlin.name = ("gremlin_%d" % _manual_spawn_seq).validate_node_name()

	get_node(spawn_path).call_deferred("add_child", new_gremlin, true)

func spawn_knight() -> void:
	if !multiplayer.is_server(): return
	
	print("spawning knight")
	
	var new_knight: Node = knight.instantiate()
	_manual_spawn_seq += 1
	new_knight.name = ("knight_%d" % _manual_spawn_seq).validate_node_name()

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

	if RealityClaim.should_reject_skeleton_spawn(get_tree(), scene_path, world_position):
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
		monster.name = spawn_id.validate_node_name()
	monster.add_to_group("generated_dungeon_monsters")

	# Synchronous add_child so swap-on-success commit/rollback is not racing a deferred spawn.
	get_node(spawn_path).add_child(monster, true)
	return monster

func spawn_tile_from_scene_path(scene_path: String, world_position: Vector2, variant_id: int = -1, wall_frame: int = -1) -> Node2D:
	if !multiplayer.is_server():
		return null
	# Generated floor/wall stay off MultiplayerSpawner auto-spawn. Tracking them
	# makes the joining client hit _update_spawn_visibility without authority
	# (ERR_BUG ~once per tile). Server instantiates locally; clients get a
	# replace RPC at commit / peer connect.
	return _instantiate_generated_tile(scene_path, world_position, variant_id, wall_frame)

func _generated_tiles_parent() -> Node:
	var root: Node = get_node(spawn_path)
	var tiles: Node = root.get_node_or_null("GeneratedTiles")
	if tiles:
		return tiles
	var created := Node2D.new()
	created.name = "GeneratedTiles"
	created.y_sort_enabled = true
	root.add_child(created)
	return created


func _generated_tile_name(scene_path: String, world_position: Vector2) -> String:
	var gx := int(round(world_position.x / 128.0))
	var gy := int(round(world_position.y / 128.0))
	var prefix := "gf"
	if scene_path.ends_with("wall.tscn"):
		prefix = "gw"
	elif scene_path.ends_with("dungeon_entrance.tscn"):
		prefix = "ge"
	return "%s_%d_%d" % [prefix, gx, gy]

func _disable_generated_tile_sync(tile: Node) -> void:
	var sync := tile.get_node_or_null("MultiplayerSynchronizer")
	if sync:
		tile.remove_child(sync)
		sync.free()

func _instantiate_generated_tile(scene_path: String, world_position: Vector2, variant_id: int, wall_frame: int) -> Node2D:
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

	tile.name = _generated_tile_name(scene_path, world_position)
	tile.position = world_position
	tile.add_to_group("generated_dungeon_tiles")
	_disable_generated_tile_sync(tile)
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
	elif scene_path.ends_with("dungeon_entrance.tscn"):
		tile.z_index = WALL_Z_INDEX
		tile.add_to_group("entrance")
		tile.add_to_group("room")
	else:
		tile.z_index = FLOOR_Z_INDEX

	var parent: Node = _generated_tiles_parent()
	var existing: Node = parent.get_node_or_null(NodePath(str(tile.name)))
	if existing:
		existing.remove_from_group("generated_dungeon_tiles")
		parent.remove_child(existing)
		existing.queue_free()
	parent.add_child(tile, false)
	_strip_outside_at_world(world_position)
	return tile

func _strip_outside_at_world(world_position: Vector2) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var level: Node = tree.get_first_node_in_group("level_manager")
	var cell: Vector2i = DungeonGrid.from_world(world_position)
	if level and level.has_method("remove_outside_tile_at_cell"):
		level.remove_outside_tile_at_cell(cell)
	if level and level.has_method("remove_scattered_tree_at_cell"):
		level.remove_scattered_tree_at_cell(cell)

func _generated_tiles_payload() -> Array:
	var payload: Array = []
	for node in get_tree().get_nodes_in_group("generated_dungeon_tiles"):
		if not (node is Node2D) or not is_instance_valid(node):
			continue
		var tile: Node2D = node
		var scene_path := tile.scene_file_path
		if scene_path.is_empty():
			continue
		var variant_id := -1
		var wall_frame := -1
		if "wall_type" in tile:
			variant_id = int(tile.wall_type)
			if "wall_frame" in tile:
				wall_frame = int(tile.wall_frame)
		elif "floor_type" in tile:
			variant_id = int(tile.floor_type)
		payload.append({
			"p": scene_path,
			"n": tile.name,
			"x": tile.position.x,
			"y": tile.position.y,
			"v": variant_id,
			"f": wall_frame,
		})
	return payload

func sync_generated_tiles_to_peers() -> void:
	if not multiplayer.is_server():
		return
	_rpc_replace_generated_tiles.rpc(_generated_tiles_payload())

func sync_generated_tiles_to_peer(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	_rpc_replace_generated_tiles.rpc_id(peer_id, _generated_tiles_payload())

func _clear_generated_tiles_local() -> void:
	for node in get_tree().get_nodes_in_group("generated_dungeon_tiles"):
		if not is_instance_valid(node):
			continue
		node.remove_from_group("generated_dungeon_tiles")
		var node_parent: Node = node.get_parent()
		if node_parent:
			node_parent.remove_child(node)
		node.queue_free()

@rpc("authority", "reliable")
func _rpc_replace_generated_tiles(payload: Array) -> void:
	if multiplayer.is_server():
		return
	_clear_generated_tiles_local()
	for item in payload:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var scene_path := str(item.get("p", ""))
		var world_position := Vector2(float(item.get("x", 0.0)), float(item.get("y", 0.0)))
		var variant_id := int(item.get("v", -1))
		var wall_frame := int(item.get("f", -1))
		_instantiate_generated_tile(scene_path, world_position, variant_id, wall_frame)

func _on_dungeon_generation_succeeded(_request_id: String, _layout_id: String) -> void:
	_place_dm_at_entrance()


func _on_dm_entered_tree() -> void:
	_place_dm_at_entrance()

func _place_dm_at_entrance() -> void:
	var dm: Node = get_tree().get_first_node_in_group("dm")
	_place_dm_node_at_entrance(dm)


func _place_dm_node_at_entrance(dm: Node) -> void:
	if not (dm is Node2D):
		return
	var spawn_position: Vector2 = _entrance_world_position()
	if not spawn_position.is_finite():
		return
	(dm as Node2D).position = spawn_position


func _entrance_world_position() -> Vector2:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager == null or not manager.has_method("get_entrance_world_position"):
		return Vector2.INF
	return manager.get_entrance_world_position()


func spawn_host_player(player_name: String) -> void:
	if not Lobby.is_network_server():
		return
	
	print("spawning dm player")
	if !player_name or player_name.is_empty():
		player_name = "DM"
	
	var dm: Node = dm_player.instantiate()
	dm.name = "dm"
	DmManager.dm_player_name = player_name
	dm.add_to_group("dm")
	_place_dm_node_at_entrance(dm)
	if not dm.tree_entered.is_connected(_on_dm_entered_tree):
		dm.tree_entered.connect(_on_dm_entered_tree, CONNECT_ONE_SHOT)
	get_node(spawn_path).call_deferred("add_child", dm, true)
	call_deferred("_place_dm_at_entrance")
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
		
func _sync_global_state_to_peer(id: int) -> void:
	var dm_hp: int = 100
	var dm_max: int = 100
	if DmManager.dm:
		dm_hp = int(DmManager.dm.hitpoints)
		dm_max = int(DmManager.dm.max_hp)
	sync_global_state.rpc_id(id, DmManager.fantasy_level, DmManager.current_mana, DmManager.max_mana, DmUnlocks.snapshot(), int(PlayerManager.reality_level), dm_hp, dm_max)
	DmManager.sync_blizzard_to_peer(id)

@rpc("authority", "call_local", "reliable")
func sync_global_state(f: int, mana: int = 0, mana_max: int = 100, unlocks: Dictionary = {}, reality_lv: int = -1, dm_hp: int = -1, dm_max_hp: int = -1) -> void:
	DmManager.fantasy_level = f
	DmManager.fantasy_level_changed.emit(f)
	DmManager.apply_replicated_mana(mana, mana_max)
	if not unlocks.is_empty():
		DmUnlocks.apply_replicated_unlocks(unlocks)
	if reality_lv >= 0:
		PlayerManager.reality_level = reality_lv
		PlayerManager.reality_level_changed.emit(reality_lv)
	if dm_hp >= 0 and dm_max_hp >= 0:
		DmManager.apply_replicated_health(dm_hp, dm_max_hp)
