extends Node2D

const TREE_TYPE_COUNT := 10

@export var tree_scatter_density: float = 0.08

var damage_numbers_scene: PackedScene = preload("res://spells/damage_number.tscn")
var is_shadow_zone: bool = false
var generated_dungeon_container: Node2D = null
var map_bounds: MapBounds = MapBounds.new()
var _cliff_catalog: CliffCatalog = CliffCatalog.new()
var _cliff_scene: PackedScene = preload("res://level/cliff.tscn")
var _outside_scene: PackedScene = preload("res://level/outside_tile.tscn")
var _outside_catalog: OutsideCatalog = OutsideCatalog.new()
var _tree_scene: PackedScene = preload("res://doodads/tree.tscn")
var _overworld_dungeon_aabb: Rect2i = Rect2i()
var _overworld_exit_cell: Vector2i = DungeonGrid.SENTINEL
var _west_spawn_cursor: int = 0

# Live dungeon stays until a replacement fully succeeds (swap-on-success).
var _live_generated_nodes: Array[Node] = []
var _staged_generated_nodes: Array[Node] = []

# Handle global level-based events such as projectiles

func _ready() -> void:
	if not is_in_group("level_manager"):
		add_to_group("level_manager")

	if !SignalBus.on_explosion.is_connected(on_explosion):
		SignalBus.on_explosion.connect(on_explosion)
	if not multiplayer.peer_connected.is_connected(_on_map_peer_connected):
		multiplayer.peer_connected.connect(_on_map_peer_connected)

	# Set up periodic cleanup of invalid nodes to prevent RPC errors
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 5.0  # Clean up every 5 seconds
	cleanup_timer.timeout.connect(_periodic_cleanup)
	cleanup_timer.autostart = true
	add_child(cleanup_timer)
	if get_node_or_null("RealityTileDrift") == null:
		var drift := RealityTileDrift.new()
		drift.name = "RealityTileDrift"
		add_child(drift)

func on_explosion(proj_position: Vector2, explosion_data: Dictionary) -> void:
	if !multiplayer.is_server(): return
	explosion_data["position"] = proj_position
	handle_explosion(explosion_data)

func handle_explosion(explosion_data: Dictionary) -> void:
	if !multiplayer.is_server(): return
	for player_id in PlayerManager.players_data.keys():
		var player_node = get_node_or_null(str(player_id)) as Node2D
		if !player_node or !player_node is Player: continue
		if player_node.position.distance_to(explosion_data.position) <= explosion_data.radius:
			print("player ", player_id, " hit!")
			if explosion_data.damage:
				show_damage_number.rpc(explosion_data.damage, player_node.global_position, player_node.sync_color)
				PlayerManager.update_reality_level(-explosion_data.damage)

@rpc("any_peer", "call_local", "reliable")
func show_damage_number(damage: int, spawn_pos: Vector2, color: Color):
	var dmg_numbers = damage_numbers_scene.instantiate() as Node2D
	dmg_numbers.global_position = spawn_pos
	dmg_numbers.get_node("DamageNumber").text = str(damage)
	dmg_numbers.get_node("DamageNumber").self_modulate = color
	get_tree().current_scene.add_child(dmg_numbers)

func _periodic_cleanup():
	"""Periodic cleanup to prevent RPC errors on deleted nodes"""
	if multiplayer.is_server():
		# Clean up any pickup spawners' invalid references
		var pickup_spawners = get_tree().get_nodes_in_group("multiplayer_pickup_spawner")
		for spawner in pickup_spawners:
			if spawner.has_method("cleanup_invalid_pickups"):
				spawner.cleanup_invalid_pickups()

func has_map_bounds() -> bool:
	return map_bounds.has_committed_bounds()

func get_map_bounds() -> MapBounds:
	return map_bounds

func clamp_world_to_interior(world: Vector2) -> Vector2:
	return map_bounds.clamp_world_to_interior(world)

func _dungeon_occupied_cells() -> Dictionary:
	var occupied: Dictionary = {}
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager and manager.has_method("get_dungeon_occupied_cells"):
		var from_layout: Variant = manager.get_dungeon_occupied_cells()
		if typeof(from_layout) == TYPE_DICTIONARY and not from_layout.is_empty():
			return from_layout
	var tree := get_tree()
	if tree == null:
		return occupied
	for node in tree.get_nodes_in_group("generated_dungeon_tiles"):
		if not (node is Node2D) or not is_instance_valid(node):
			continue
		occupied[DungeonGrid.from_world((node as Node2D).position)] = true
	return occupied

func _is_dungeon_cell_for_overworld(cell: Vector2i, occupied: Dictionary, dungeon: Rect2i) -> bool:
	if occupied.has(cell):
		return true
	if occupied.is_empty() and dungeon.size.x > 0 and dungeon.size.y > 0 and dungeon.has_point(cell):
		return true
	return false

func is_outside_build_cell(cell: Vector2i) -> bool:
	if _is_dungeon_cell_for_overworld(cell, _dungeon_occupied_cells(), dungeon_cell_bounds()):
		return false
	var tree := get_tree()
	if tree == null:
		return false
	for node in tree.get_nodes_in_group("outside_tiles"):
		if not (node is Node2D) or not is_instance_valid(node):
			continue
		if DungeonGrid.from_world((node as Node2D).position) == cell:
			return true
	return false


func dungeon_cell_bounds() -> Rect2i:
	if _overworld_dungeon_aabb.size.x > 0 and _overworld_dungeon_aabb.size.y > 0:
		return _overworld_dungeon_aabb
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager and manager.has_method("get_dungeon_cell_bounds"):
		return manager.get_dungeon_cell_bounds()
	return Rect2i()

func dungeon_exit_cell() -> Vector2i:
	return _resolve_exit_cell()

func west_spawn_cells() -> Array[Vector2i]:
	return map_bounds.west_spawn_strip_cells(dungeon_cell_bounds())

func take_west_spawn_world() -> Vector2:
	var pos: Vector2 = map_bounds.west_spawn_world(_west_spawn_cursor, dungeon_cell_bounds())
	_west_spawn_cursor += 1
	return pos

func enforce_body_interior(body: Node2D) -> void:
	if body == null or not is_instance_valid(body):
		return
	if not has_map_bounds():
		return
	var clamped: Vector2 = map_bounds.clamp_world_to_interior(body.global_position)
	if clamped.is_equal_approx(body.global_position):
		return
	body.global_position = clamped
	if body is CharacterBody2D:
		(body as CharacterBody2D).velocity = Vector2.ZERO
	if not Lobby.is_network_server():
		return
	if not body.has_method("apply_interior_clamp"):
		return
	var owner_id: int = body.get_multiplayer_authority()
	if owner_id <= 0 or owner_id == multiplayer.get_unique_id():
		return
	body.apply_interior_clamp.rpc_id(owner_id, clamped)

func _physics_process(_delta: float) -> void:
	if not has_map_bounds():
		return
	if not Lobby.is_network_server():
		return
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("players"):
		if node is Node2D:
			enforce_body_interior(node)
	var dm_node: Node = tree.get_first_node_in_group("dm")
	if dm_node is Node2D:
		enforce_body_interior(dm_node)
	for node in tree.get_nodes_in_group("generated_dungeon_monsters"):
		if node is Node2D:
			enforce_body_interior(node)

func commit_map_interior(interior: Rect2i) -> void:
	if not Lobby.is_network_server():
		return
	apply_map_interior(interior, dungeon_cell_bounds(), _resolve_exit_cell())
	SignalBus.map_bounds_committed.emit(interior)
	_rpc_replace_overworld_map.rpc(build_map_sync_payload())

func apply_map_interior(interior: Rect2i, dungeon: Rect2i = Rect2i(), exit_cell: Vector2i = DungeonGrid.SENTINEL) -> void:
	map_bounds.commit_interior(interior)
	if dungeon.size.x > 0 and dungeon.size.y > 0:
		_overworld_dungeon_aabb = dungeon
	else:
		_overworld_dungeon_aabb = dungeon_cell_bounds()
	if exit_cell != DungeonGrid.SENTINEL:
		_overworld_exit_cell = exit_cell
	else:
		_overworld_exit_cell = _exit_from_manager()
	rebuild_cliff_ring()
	rebuild_outside_fill()
	strip_outside_tiles_from_dungeon_cells()
	rebuild_tree_scatter()

func clear_map_interior() -> void:
	if not Lobby.is_network_server():
		return
	_rpc_clear_map_interior.rpc()

func build_map_sync_payload() -> Dictionary:
	var interior: Rect2i = map_bounds.get_interior()
	var dungeon: Rect2i = dungeon_cell_bounds()
	var exit_cell: Vector2i = _resolve_exit_cell()
	return {
		"ix": interior.position.x,
		"iy": interior.position.y,
		"iw": interior.size.x,
		"ih": interior.size.y,
		"dx": dungeon.position.x,
		"dy": dungeon.position.y,
		"dw": dungeon.size.x,
		"dh": dungeon.size.y,
		"ex": exit_cell.x,
		"ey": exit_cell.y,
		"cliffs": _cliff_sync_items(),
		"out": _outside_sync_items(),
		"trees": _tree_sync_items(),
	}

func apply_map_sync_payload(payload: Dictionary) -> void:
	if payload.is_empty():
		return
	var interior := Rect2i(
		int(payload.get("ix", 0)),
		int(payload.get("iy", 0)),
		int(payload.get("iw", 0)),
		int(payload.get("ih", 0))
	)
	if interior.size.x <= 0 or interior.size.y <= 0:
		return
	var dungeon := Rect2i(
		int(payload.get("dx", 0)),
		int(payload.get("dy", 0)),
		int(payload.get("dw", 0)),
		int(payload.get("dh", 0))
	)
	var exit_cell := Vector2i(int(payload.get("ex", DungeonGrid.SENTINEL.x)), int(payload.get("ey", DungeonGrid.SENTINEL.y)))
	map_bounds.commit_interior(interior)
	_overworld_dungeon_aabb = dungeon
	_overworld_exit_cell = exit_cell
	_apply_cliffs_from_payload(payload.get("cliffs", []))
	_apply_outside_from_payload(payload.get("out", []))
	_apply_trees_from_payload(payload.get("trees", []))
	strip_outside_tiles_from_dungeon_cells()
	SignalBus.map_bounds_committed.emit(interior)

@rpc("authority", "reliable")
func _rpc_replace_overworld_map(payload: Dictionary) -> void:
	if Lobby.is_network_server():
		return
	apply_map_sync_payload(payload)

@rpc("authority", "call_local", "reliable")
func _rpc_clear_map_interior() -> void:
	map_bounds.clear()
	_overworld_dungeon_aabb = Rect2i()
	_overworld_exit_cell = DungeonGrid.SENTINEL
	rebuild_cliff_ring()
	rebuild_outside_fill()
	rebuild_tree_scatter()
	SignalBus.map_bounds_cleared.emit()

func _on_map_peer_connected(peer_id: int) -> void:
	if not Lobby.is_network_server():
		return
	if not has_map_bounds():
		return
	_rpc_replace_overworld_map.rpc_id(peer_id, build_map_sync_payload())

func broadcast_outside_presentation(cell: Vector2i, presentation: int) -> void:
	if not Lobby.is_network_server():
		return
	_rpc_set_outside_presentation.rpc(cell.x, cell.y, presentation)

@rpc("authority", "reliable")
func _rpc_set_outside_presentation(cell_x: int, cell_y: int, presentation: int) -> void:
	if Lobby.is_network_server():
		return
	apply_outside_presentation(Vector2i(cell_x, cell_y), presentation)

func apply_outside_presentation(cell: Vector2i, presentation: int) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("outside_tiles"):
		if not (node is OutsideTile) or not is_instance_valid(node):
			continue
		if DungeonGrid.from_world((node as OutsideTile).position) != cell:
			continue
		(node as OutsideTile).element_presentation = presentation
		return

func rebuild_cliff_ring() -> void:
	var parent: Node2D = _cliff_tiles_parent()
	_clear_cliff_tiles(parent)
	if not map_bounds.has_committed_bounds():
		return
	if _cliff_scene == null:
		return
	var interior: Rect2i = map_bounds.get_interior()
	for cell in map_bounds.cliff_cells():
		_place_cliff_at(parent, cell, _cliff_catalog.cliff_frame_for_cell(interior, cell))

func _cliff_tiles_parent() -> Node2D:
	var existing: Node = get_node_or_null("CliffTiles")
	if existing is Node2D:
		return existing
	var created := Node2D.new()
	created.name = "CliffTiles"
	created.y_sort_enabled = true
	add_child(created)
	return created

func _clear_cliff_tiles(parent: Node) -> void:
	var doomed: Array[Node] = []
	for child in parent.get_children():
		doomed.append(child)
	for node in doomed:
		if node.is_in_group("cliff_tiles"):
			node.remove_from_group("cliff_tiles")
		parent.remove_child(node)
		node.queue_free()

func rebuild_outside_fill() -> void:
	var parent: Node2D = _outside_tiles_parent()
	_clear_named_tile_children(parent, "outside_tiles")
	if not map_bounds.has_committed_bounds():
		return
	if _outside_scene == null:
		return
	var dungeon: Rect2i = dungeon_cell_bounds()
	var occupied: Dictionary = _dungeon_occupied_cells()
	var rng := RandomNumberGenerator.new()
	rng.seed = _outside_fill_seed(map_bounds.get_interior(), dungeon)
	var interior: Rect2i = map_bounds.get_interior()
	for y in range(interior.position.y, interior.end.y):
		for x in range(interior.position.x, interior.end.x):
			var cell := Vector2i(x, y)
			if map_bounds.is_cliff_cell(cell):
				continue
			if _is_dungeon_cell_for_overworld(cell, occupied, dungeon):
				continue
			var tile: Node2D = _outside_scene.instantiate() as Node2D
			if tile == null:
				continue
			tile.name = ("out_%d_%d" % [cell.x, cell.y]).validate_node_name()
			tile.position = DungeonGrid.to_world(cell)
			tile.add_to_group("outside_tiles")
			parent.add_child(tile)
			_outside_catalog.apply_random_neutral(tile, rng)

func remove_outside_tile_at_cell(cell: Vector2i) -> void:
	var doomed: Array[Node] = []
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("outside_tiles"):
		if not (node is Node2D) or not is_instance_valid(node):
			continue
		if DungeonGrid.from_world((node as Node2D).position) == cell:
			doomed.append(node)
	_free_outside_nodes(doomed)

func strip_outside_tiles_from_dungeon_cells() -> void:
	var dungeon: Rect2i = dungeon_cell_bounds()
	var occupied: Dictionary = _dungeon_occupied_cells()
	var tree := get_tree()
	if tree == null:
		return
	var doomed: Array[Node] = []
	for node in tree.get_nodes_in_group("outside_tiles"):
		if not (node is Node2D) or not is_instance_valid(node):
			continue
		var cell: Vector2i = DungeonGrid.from_world((node as Node2D).position)
		var blocked := false
		if map_bounds.has_committed_bounds() and map_bounds.is_cliff_cell(cell):
			blocked = true
		if _is_dungeon_cell_for_overworld(cell, occupied, dungeon):
			blocked = true
		if blocked:
			doomed.append(node)
	_free_outside_nodes(doomed)

func _free_outside_nodes(nodes: Array[Node]) -> void:
	for node in nodes:
		if node == null or not is_instance_valid(node):
			continue
		if node.is_in_group("outside_tiles"):
			node.remove_from_group("outside_tiles")
		var parent: Node = node.get_parent()
		if parent:
			parent.remove_child(node)
		node.queue_free()

func _outside_fill_seed(interior: Rect2i, dungeon: Rect2i) -> int:
	return int(hash("%d,%d,%d,%d|%d,%d,%d,%d" % [
		interior.position.x, interior.position.y, interior.size.x, interior.size.y,
		dungeon.position.x, dungeon.position.y, dungeon.size.x, dungeon.size.y
	]))

func _tree_scatter_seed(interior: Rect2i, dungeon: Rect2i, exit_cell: Vector2i) -> int:
	return int(hash("trees|%d,%d,%d,%d|%d,%d,%d,%d|%d,%d" % [
		interior.position.x, interior.position.y, interior.size.x, interior.size.y,
		dungeon.position.x, dungeon.position.y, dungeon.size.x, dungeon.size.y,
		exit_cell.x, exit_cell.y
	]))

func _resolve_exit_cell() -> Vector2i:
	if _overworld_exit_cell != DungeonGrid.SENTINEL:
		return _overworld_exit_cell
	return _exit_from_manager()

func _exit_from_manager() -> Vector2i:
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager and manager.has_method("get_exit_cell"):
		return manager.get_exit_cell()
	return DungeonGrid.SENTINEL

func rebuild_tree_scatter() -> void:
	var parent: Node2D = _scattered_trees_parent()
	_clear_named_tile_children(parent, "scattered_trees")
	if not map_bounds.has_committed_bounds():
		return
	if _tree_scene == null:
		return
	var eligible: Array[Vector2i] = tree_scatter_eligible_cells()
	if eligible.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = _tree_scatter_seed(map_bounds.get_interior(), dungeon_cell_bounds(), dungeon_exit_cell())
	_shuffle_cells(eligible, rng)
	var density: float = clampf(tree_scatter_density, 0.0, 1.0)
	var count: int = int(round(float(eligible.size()) * density))
	count = mini(count, eligible.size())
	for i in range(count):
		var cell: Vector2i = eligible[i]
		var doodad: Node2D = _tree_scene.instantiate() as Node2D
		if doodad == null:
			continue
		if "tree_type" in doodad:
			doodad.tree_type = rng.randi_range(0, TREE_TYPE_COUNT - 1)
		doodad.name = ("tree_%d_%d" % [cell.x, cell.y]).validate_node_name()
		doodad.position = DungeonGrid.to_world_center(cell)
		doodad.add_to_group("scattered_trees")
		parent.add_child(doodad)
	strip_scattered_trees_from_blocked_cells()

func tree_scatter_eligible_cells() -> Array[Vector2i]:
	var dungeon: Rect2i = dungeon_cell_bounds()
	var blocked: Dictionary = _tree_scatter_blocked_cells()
	var cells: Array[Vector2i] = []
	for cell in map_bounds.tree_scatter_candidate_cells(dungeon):
		if blocked.has(cell):
			continue
		cells.append(cell)
	return cells

func _tree_scatter_blocked_cells() -> Dictionary:
	var blocked: Dictionary = {}
	var exit_cell: Vector2i = dungeon_exit_cell()
	if exit_cell != DungeonGrid.SENTINEL:
		blocked[exit_cell] = true
		for neighbor in DungeonGrid.neighbors(exit_cell):
			blocked[neighbor] = true
	for cell in _building_blocked_cells():
		blocked[cell] = true
	return blocked

func _building_blocked_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var scene_tree := get_tree()
	if scene_tree == null:
		return cells
	var seen: Dictionary = {}
	var roots: Array = scene_tree.get_nodes_in_group("building_root")
	for root in roots:
		if root == null:
			continue
		for child in root.get_children():
			if not (child is Node2D) or not is_instance_valid(child):
				continue
			var cell: Vector2i = DungeonGrid.from_world((child as Node2D).global_position)
			if seen.has(cell):
				continue
			seen[cell] = true
			cells.append(cell)
	return cells

func _shuffle_cells(cells: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(cells.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: Vector2i = cells[i]
		cells[i] = cells[j]
		cells[j] = swap

func remove_scattered_tree_at_cell(cell: Vector2i) -> void:
	var doomed: Array[Node] = []
	var scene_tree := get_tree()
	if scene_tree == null:
		return
	for node in scene_tree.get_nodes_in_group("scattered_trees"):
		if not (node is Node2D) or not is_instance_valid(node):
			continue
		if DungeonGrid.from_world((node as Node2D).position) == cell:
			doomed.append(node)
	_free_scattered_trees(doomed)

func strip_scattered_trees_from_blocked_cells() -> void:
	var dungeon: Rect2i = dungeon_cell_bounds()
	var blocked: Dictionary = _tree_scatter_blocked_cells()
	var west: Dictionary = {}
	for cell in map_bounds.west_spawn_strip_cells(dungeon):
		west[cell] = true
	var scene_tree := get_tree()
	if scene_tree == null:
		return
	var doomed: Array[Node] = []
	for node in scene_tree.get_nodes_in_group("scattered_trees"):
		if not (node is Node2D) or not is_instance_valid(node):
			continue
		var cell: Vector2i = DungeonGrid.from_world((node as Node2D).position)
		var banned := false
		if map_bounds.has_committed_bounds() and not map_bounds.is_interior_cell(cell):
			banned = true
		if map_bounds.has_committed_bounds() and map_bounds.is_cliff_cell(cell):
			banned = true
		if dungeon.size.x > 0 and dungeon.size.y > 0 and dungeon.has_point(cell):
			banned = true
		if west.has(cell) or blocked.has(cell):
			banned = true
		if banned:
			doomed.append(node)
	_free_scattered_trees(doomed)

func _free_scattered_trees(nodes: Array[Node]) -> void:
	for node in nodes:
		if node == null or not is_instance_valid(node):
			continue
		if node.is_in_group("scattered_trees"):
			node.remove_from_group("scattered_trees")
		var parent: Node = node.get_parent()
		if parent:
			parent.remove_child(node)
		node.queue_free()

func _scattered_trees_parent() -> Node2D:
	var existing: Node = get_node_or_null("ScatteredTrees")
	if existing is Node2D:
		return existing
	var created := Node2D.new()
	created.name = "ScatteredTrees"
	created.y_sort_enabled = true
	add_child(created)
	return created

func _outside_tiles_parent() -> Node2D:
	var existing: Node = get_node_or_null("OutsideTiles")
	if existing is Node2D:
		return existing
	var created := Node2D.new()
	created.name = "OutsideTiles"
	created.y_sort_enabled = true
	created.z_index = -1
	add_child(created)
	return created

func _clear_named_tile_children(parent: Node, group_name: String) -> void:
	var doomed: Array[Node] = []
	for child in parent.get_children():
		doomed.append(child)
	for node in doomed:
		if node.is_in_group(group_name):
			node.remove_from_group(group_name)
		parent.remove_child(node)
		node.queue_free()

func _cliff_sync_items() -> Array:
	var items: Array = []
	var parent: Node = get_node_or_null("CliffTiles")
	if parent == null:
		return items
	for child in parent.get_children():
		if not (child is Node2D):
			continue
		var world: Vector2 = (child as Node2D).position
		if child.has_method("grid_world_position"):
			world = child.grid_world_position()
		var cell: Vector2i = DungeonGrid.from_world(world)
		var frame := -1
		if "cliff_frame" in child:
			frame = int(child.cliff_frame)
		items.append({"x": cell.x, "y": cell.y, "f": frame})
	return items

func _outside_sync_items() -> Array:
	var items: Array = []
	var parent: Node = get_node_or_null("OutsideTiles")
	if parent == null:
		return items
	for child in parent.get_children():
		if not (child is OutsideTile):
			continue
		var tile: OutsideTile = child
		var cell: Vector2i = DungeonGrid.from_world(tile.position)
		items.append({
			"x": cell.x,
			"y": cell.y,
			"k": int(tile.ground_kind),
			"v": int(tile.variety),
			"p": int(tile.element_presentation),
		})
	return items

func _tree_sync_items() -> Array:
	var items: Array = []
	var parent: Node = get_node_or_null("ScatteredTrees")
	if parent == null:
		return items
	for child in parent.get_children():
		if not (child is Node2D):
			continue
		var cell: Vector2i = DungeonGrid.from_world((child as Node2D).position)
		var tree_type := -1
		if "tree_type" in child:
			tree_type = int(child.tree_type)
		items.append({"x": cell.x, "y": cell.y, "t": tree_type})
	return items

func _apply_cliffs_from_payload(items: Variant) -> void:
	var parent: Node2D = _cliff_tiles_parent()
	_clear_cliff_tiles(parent)
	if typeof(items) != TYPE_ARRAY:
		rebuild_cliff_ring()
		return
	var listed: Array = items
	if listed.is_empty():
		rebuild_cliff_ring()
		return
	var interior: Rect2i = map_bounds.get_interior()
	for item in listed:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var cell := Vector2i(int(item.get("x", 0)), int(item.get("y", 0)))
		var frame: int = int(item.get("f", _cliff_catalog.cliff_frame_for_cell(interior, cell)))
		_place_cliff_at(parent, cell, frame)

func _apply_outside_from_payload(items: Variant) -> void:
	var parent: Node2D = _outside_tiles_parent()
	_clear_named_tile_children(parent, "outside_tiles")
	if typeof(items) != TYPE_ARRAY:
		return
	for item in items:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var cell := Vector2i(int(item.get("x", 0)), int(item.get("y", 0)))
		_place_outside_at(parent, cell, int(item.get("k", 0)), int(item.get("v", 0)), int(item.get("p", 0)))

func _apply_trees_from_payload(items: Variant) -> void:
	var parent: Node2D = _scattered_trees_parent()
	_clear_named_tile_children(parent, "scattered_trees")
	if typeof(items) != TYPE_ARRAY:
		return
	for item in items:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var cell := Vector2i(int(item.get("x", 0)), int(item.get("y", 0)))
		_place_tree_at(parent, cell, int(item.get("t", 0)))

func _place_cliff_at(parent: Node2D, cell: Vector2i, frame: int) -> void:
	if _cliff_scene == null:
		return
	var cliff: Node2D = _cliff_scene.instantiate() as Node2D
	if cliff == null:
		return
	cliff.name = ("cliff_%d_%d" % [cell.x, cell.y]).validate_node_name()
	cliff.position = DungeonGrid.to_world(cell)
	cliff.add_to_group("cliff_tiles")
	_strip_tile_sync(cliff)
	parent.add_child(cliff)
	if "cliff_frame" in cliff:
		cliff.cliff_frame = frame

func _place_outside_at(parent: Node2D, cell: Vector2i, ground_kind: int, variety: int, presentation: int = 0) -> void:
	if _outside_scene == null:
		return
	var tile: Node2D = _outside_scene.instantiate() as Node2D
	if tile == null:
		return
	tile.name = ("out_%d_%d" % [cell.x, cell.y]).validate_node_name()
	tile.position = DungeonGrid.to_world(cell)
	tile.add_to_group("outside_tiles")
	_strip_tile_sync(tile)
	parent.add_child(tile)
	if "ground_kind" in tile:
		tile.ground_kind = ground_kind
	if "variety" in tile:
		tile.variety = variety
	if "element_presentation" in tile:
		tile.element_presentation = presentation

func _place_tree_at(parent: Node2D, cell: Vector2i, tree_type: int) -> void:
	if _tree_scene == null:
		return
	var doodad: Node2D = _tree_scene.instantiate() as Node2D
	if doodad == null:
		return
	if "tree_type" in doodad:
		doodad.tree_type = tree_type
	doodad.name = ("tree_%d_%d" % [cell.x, cell.y]).validate_node_name()
	doodad.position = DungeonGrid.to_world_center(cell)
	doodad.add_to_group("scattered_trees")
	_strip_tile_sync(doodad)
	parent.add_child(doodad)

func _strip_tile_sync(node: Node) -> void:
	var sync := node.get_node_or_null("MultiplayerSynchronizer")
	if sync:
		node.remove_child(sync)
		sync.free()

func begin_generated_dungeon_stage() -> void:
	if not multiplayer.is_server():
		return
	_free_node_list(_staged_generated_nodes)
	_staged_generated_nodes.clear()

func register_staged_generated_node(node: Node) -> void:
	if node == null:
		return
	_staged_generated_nodes.append(node)

func commit_generated_dungeon_stage() -> void:
	if not multiplayer.is_server():
		return
	# Only discard the last good dungeon after the replacement is fully spawned.
	_free_node_list(_live_generated_nodes)
	_live_generated_nodes = _staged_generated_nodes.duplicate()
	_staged_generated_nodes.clear()
	generated_dungeon_container = _first_valid_node(_live_generated_nodes)
	_sync_generated_tiles_to_clients()

func rollback_generated_dungeon_stage() -> void:
	if not multiplayer.is_server():
		return
	_free_node_list(_staged_generated_nodes)
	_staged_generated_nodes.clear()

func replace_generated_dungeon_container(new_container: Node2D) -> void:
	if not multiplayer.is_server():
		return
	# Do not wipe the live dungeon unless a replacement node exists.
	if not new_container:
		return
	begin_generated_dungeon_stage()
	if new_container.get_parent():
		new_container.get_parent().remove_child(new_container)
	get_tree().current_scene.add_child(new_container)
	register_staged_generated_node(new_container)
	commit_generated_dungeon_stage()

func clear_generated_dungeon_container() -> void:
	if not multiplayer.is_server():
		return
	_free_node_list(_live_generated_nodes)
	_free_node_list(_staged_generated_nodes)
	_live_generated_nodes.clear()
	_staged_generated_nodes.clear()
	if generated_dungeon_container and is_instance_valid(generated_dungeon_container):
		generated_dungeon_container.queue_free()
	generated_dungeon_container = null

func _sync_generated_tiles_to_clients() -> void:
	var spawners: Array = get_tree().get_nodes_in_group("multiplayer_spawner")
	if spawners.is_empty():
		return
	var spawner: Node = spawners[0]
	if spawner.has_method("sync_generated_tiles_to_peers"):
		spawner.sync_generated_tiles_to_peers()

func _first_valid_node(nodes: Array[Node]) -> Node2D:
	for node in nodes:
		if node and is_instance_valid(node) and node is Node2D:
			return node
	return null

func _free_node_list(nodes: Array[Node]) -> void:
	# Leave generated groups and the tree immediately. queue_free is deferred,
	# so a same-session regenerate would otherwise stack tiles in
	# generated_dungeon_tiles and in the world until the next idle frame.
	for node in nodes:
		if node == null or not is_instance_valid(node):
			continue
		if node.is_in_group("generated_dungeon_tiles"):
			node.remove_from_group("generated_dungeon_tiles")
		if node.is_in_group("generated_dungeon_monsters"):
			node.remove_from_group("generated_dungeon_monsters")
		var parent: Node = node.get_parent()
		if parent:
			parent.remove_child(node)
		node.queue_free()
