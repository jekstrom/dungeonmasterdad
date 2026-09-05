extends Node

#const __DM__ = preload("uid://e1aypo2ysyyc")
#const INVENTORY_DATA: InventoryData = preload("res://gui/pause_menu/inventory/player_inventory.tres")

signal interact_pressed

const AbilityCatalog = preload("res://dm/dm_ability_catalog.gd")
const DmNearSpawnPickerScript = preload("res://scripts/dm_near_spawn_picker.gd")
const SkillTreeCatalogScript = preload("res://dm/skill_tree_catalog.gd")
const BlizzardIceDrawScript = preload("res://spells/blizzard/blizzard_ice_draw.gd")
const DEFAULT_MAX_MANA: int = 100
const BLIZZARD_DURATION: float = 8.0
const BLIZZARD_COLD_DURATION_SCALE: float = 1.5
const BLIZZARD_SLOW_FACTOR: float = 0.5
const FROST_TRAIL_DURATION: float = 3.0
const FROST_TRAIL_SIZE: float = 32.0
const FROST_TRAIL_SPACING: float = 16.0
const BLIZZARD_FACTORY_INTERVAL_FACTOR: float = 2.0
const BLIZZARD_POCKET_CELLS: Vector2i = Vector2i(3, 3)
const CRIB_DEATH_INTERVAL_SEC: float = 60.0
const CRIB_DEATH_LIFETIME_SEC: float = 60.0
const FANTASY_PER_SKILL_POINT: int = 10

var dm: DM
@export var fantasy_level: int = 0
@export var max_mana: int = DEFAULT_MAX_MANA
var current_mana: int = 0
var skill_points: int = 0
signal fantasy_level_changed(new_fantasy_level: int)
signal mana_changed(new_current: int, new_max: int)
signal skill_points_changed(new_skill_points: int)
signal skill_point_rewarded(amount: int)
signal skill_purchase_finished(node_id: String, reason: String)
signal health_changed(new_hp: int, new_max_hp: int)
signal respawn_countdown_changed(remaining_sec: float)
signal spawn_gremlin_cast
signal spawn_knight_cast
signal spawn_goblin_cast
var player_spawned: bool = false
var _blizzard_effects: Array[Dictionary] = []
var _blizzard_broadcast_queued: bool = false
var _frost_trail: Array[Dictionary] = []
var _frost_last_world: Vector2 = Vector2.INF
var dm_player_name: String = "DM"
var _crib_death_elapsed: float = 0.0

func _ready() -> void:
	if not Lobby.host_started.is_connected(_on_host_started):
		Lobby.host_started.connect(_on_host_started)
	if not SignalBus.fantasy_pocket_expired.is_connected(_on_fantasy_pocket_expired):
		SignalBus.fantasy_pocket_expired.connect(_on_fantasy_pocket_expired)
	if not SignalBus.map_bounds_cleared.is_connected(_on_map_bounds_cleared_blizzard):
		SignalBus.map_bounds_cleared.connect(_on_map_bounds_cleared_blizzard)
	add_player_instance()
	await get_tree().create_timer(0.2).timeout
	player_spawned = true

func _on_host_started(_player_name: String = "") -> void:
	if not Lobby.is_network_server():
		return
	_crib_death_elapsed = 0.0
	_host_set_mana(0)
	_host_set_skill_points(0)
	clear_frost_trail()

func _process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	_tick_frost_trail()
	if not is_crib_death_owned():
		_crib_death_elapsed = 0.0
		return
	_crib_death_elapsed += delta
	if _crib_death_elapsed < CRIB_DEATH_INTERVAL_SEC:
		return
	_crib_death_elapsed = 0.0
	try_spawn_crib_death_gremlin()

func add_player_instance() -> void:
	pass

func set_player_pos(new_pos: Vector2) -> void:
	dm.global_position = new_pos

func set_player_health(hp: int, max_hp: int) -> void:
	if dm:
		dm.max_hp = max_hp
		dm.hitpoints = hp
	health_changed.emit(hp, max_hp)

func broadcast_health(hp: int, max_hp: int) -> void:
	if not multiplayer.is_server():
		return
	request_health_sync.rpc(hp, max_hp)

func notify_respawn_countdown(remaining_sec: float) -> void:
	respawn_countdown_changed.emit(remaining_sec)

func apply_replicated_health(hp: int, max_hp: int) -> void:
	if dm:
		dm.max_hp = maxi(1, max_hp)
		dm.hitpoints = clampi(hp, 0, dm.max_hp)
		health_changed.emit(dm.hitpoints, dm.max_hp)
	else:
		health_changed.emit(clampi(hp, 0, maxi(1, max_hp)), maxi(1, max_hp))

func set_as_parent(p: Node2D) -> void:
	if dm.get_parent():
		dm.get_parent().remove_child(dm)
	p.add_child(dm)

func unparent_player(p: Node2D) -> void:
	p.remove_child(dm)

func add_mana(amount: int) -> void:
	if not multiplayer.is_server():
		return
	_host_set_mana(current_mana + amount)

func set_mana(value: int) -> void:
	if not multiplayer.is_server():
		return
	_host_set_mana(value)

func try_cast(ability_id: String) -> bool:
	if not multiplayer.is_server():
		return false
	if dm and dm.has_method("is_downed") and bool(dm.call("is_downed")):
		return false
	if not AbilityCatalog.is_known(ability_id):
		return false
	var required_unlock: String = AbilityCatalog.unlock_id(ability_id)
	if not required_unlock.is_empty() and not bool(DmUnlocks.dm_unlocks.get(required_unlock, false)):
		return false
	var cost: int = AbilityCatalog.cost(ability_id)
	if current_mana < cost:
		return false
	_host_set_mana(current_mana - cost)
	return true

func request_cast(ability_id: String) -> void:
	if multiplayer.is_server():
		_server_request_cast(ability_id)
	else:
		request_cast_rpc.rpc_id(1, ability_id)

func _server_request_cast(ability_id: String) -> void:
	if (
		ability_id != AbilityCatalog.GREMLIN
		and ability_id != AbilityCatalog.KNIGHTLING
		and ability_id != AbilityCatalog.GOBLIN
	):
		return
	# US-055: fail closed — pick near-DM cells before spending mana.
	if not _can_try_cast(ability_id):
		return
	var spawner: Node = _multiplayer_spawner()
	var spawned: int = 0
	if spawner != null and spawner.has_method("try_spawn_gremlin_near_dm"):
		if ability_id == AbilityCatalog.GREMLIN:
			if bool(spawner.call("try_spawn_gremlin_near_dm")):
				spawned = 1
		elif ability_id == AbilityCatalog.KNIGHTLING:
			spawned = int(spawner.call("try_spawn_knights_near_dm"))
		elif ability_id == AbilityCatalog.GOBLIN:
			if bool(spawner.call("try_spawn_goblin_near_dm")):
				spawned = 1
	else:
		# Headless / no spawner (US-014): gate on picker only, then signal.
		spawned = _headless_near_dm_spawn_count(ability_id)
	if spawned <= 0:
		return
	if not try_cast(ability_id):
		return
	if ability_id == AbilityCatalog.GREMLIN:
		spawn_gremlin_cast.emit()
	elif ability_id == AbilityCatalog.KNIGHTLING:
		spawn_knight_cast.emit()
	elif ability_id == AbilityCatalog.GOBLIN:
		spawn_goblin_cast.emit()

func launch_fireball(spell_data: Dictionary) -> bool:
	if not multiplayer.is_server():
		return false
	if not try_cast(AbilityCatalog.FIREBALL):
		return false
	update_fantasy_level(15)
	SignalBus.spell_cast.emit(AbilityCatalog.FIREBALL, spell_data)
	return true

func blizzard_duration() -> float:
	if DmUnlocks.is_owned("bemidji_cold"):
		return BLIZZARD_DURATION * BLIZZARD_COLD_DURATION_SCALE
	return BLIZZARD_DURATION


func request_launch_blizzard(spell_data: Dictionary) -> void:
	if multiplayer.is_server():
		launch_blizzard(spell_data)
	else:
		request_launch_blizzard_rpc.rpc_id(1, spell_data)

func launch_blizzard(spell_data: Dictionary) -> bool:
	if not multiplayer.is_server():
		return false
	if not _can_try_cast(AbilityCatalog.BEMIDJI_BLIZZARD):
		return false
	var fantasy: FantasyZone = _fantasy_zone()
	if fantasy == null:
		return false
	var duration: float = blizzard_duration()
	var slow_factor: float = float(spell_data.get("slow_factor", BLIZZARD_SLOW_FACTOR))
	if slow_factor <= 0.0:
		slow_factor = BLIZZARD_SLOW_FACTOR
	var proposed: Rect2i = _blizzard_rect_from_spell(spell_data)
	var clipped: Rect2i = fantasy.clip_pocket_rect(proposed)
	if clipped.size.x <= 0 or clipped.size.y <= 0:
		return false
	var pocket_id: int = fantasy.spawn_pocket(clipped.position, clipped.size, duration, "blizzard")
	if pocket_id < 0:
		return false
	if not try_cast(AbilityCatalog.BEMIDJI_BLIZZARD):
		fantasy.expire_pocket(pocket_id)
		return false
	var pocket: Dictionary = fantasy.get_pocket(pocket_id)
	var rect: Rect2i = clipped
	var expires_at: float = fantasy.claim_now() + duration
	if not pocket.is_empty():
		rect = pocket["rect"]
		expires_at = float(pocket["expires_at"])
	var world_rect: Rect2 = _blizzard_patch_from_spell(spell_data, rect)
	if not pocket.is_empty():
		pocket["world_rect"] = world_rect
		fantasy._rebuild_home_overlay()
	_blizzard_effects.append({
		"pocket_id": pocket_id,
		"rect": rect,
		"world_rect": world_rect,
		"expires_at": expires_at,
		"slow_factor": slow_factor,
	})
	SignalBus.spell_cast.emit(AbilityCatalog.BEMIDJI_BLIZZARD, spell_data)
	_queue_blizzard_broadcast()
	return true

func _can_try_cast(ability_id: String) -> bool:
	if not multiplayer.is_server():
		return false
	if dm and dm.has_method("is_downed") and bool(dm.call("is_downed")):
		return false
	if not AbilityCatalog.is_known(ability_id):
		return false
	var required_unlock: String = AbilityCatalog.unlock_id(ability_id)
	if not required_unlock.is_empty() and not bool(DmUnlocks.dm_unlocks.get(required_unlock, false)):
		return false
	return current_mana >= AbilityCatalog.cost(ability_id)

func _blizzard_rect_from_spell(spell_data: Dictionary) -> Rect2i:
	if spell_data.get("rect") is Rect2i:
		return spell_data["rect"]
	var size: Vector2i = BLIZZARD_POCKET_CELLS
	if spell_data.get("size") is Vector2i:
		size = spell_data["size"]
	elif spell_data.has("size_x") or spell_data.has("size_y"):
		size = Vector2i(int(spell_data.get("size_x", size.x)), int(spell_data.get("size_y", size.y)))
	if size.x <= 0 or size.y <= 0:
		size = BLIZZARD_POCKET_CELLS
	var origin := Vector2i.ZERO
	if spell_data.get("origin") is Vector2i:
		origin = spell_data["origin"]
	elif spell_data.has("origin_x") or spell_data.has("origin_y"):
		origin = Vector2i(int(spell_data.get("origin_x", 0)), int(spell_data.get("origin_y", 0)))
	elif spell_data.get("target") is Vector2:
		var cell: Vector2i = DungeonGrid.from_world(spell_data["target"])
		origin = cell - Vector2i(int(size.x / 2), int(size.y / 2))
	elif spell_data.get("target") is Vector2i:
		origin = spell_data["target"] - Vector2i(int(size.x / 2), int(size.y / 2))
	else:
		return Rect2i()
	return Rect2i(origin, size)

func _fantasy_zone() -> FantasyZone:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("FantasyZone") as FantasyZone

func _blizzard_world_rect(cell_rect: Rect2i) -> Rect2:
	return Rect2(
		DungeonGrid.to_world(cell_rect.position),
		Vector2(cell_rect.size) * DungeonGrid.CELL_PX
	)

func _blizzard_patch_from_spell(spell_data: Dictionary, cell_rect: Rect2i) -> Rect2:
	var world_size: Vector2 = Vector2(cell_rect.size) * DungeonGrid.CELL_PX
	if world_size.x <= 0.0 or world_size.y <= 0.0:
		world_size = Vector2(BLIZZARD_POCKET_CELLS) * DungeonGrid.CELL_PX
	if spell_data.get("target") is Vector2:
		var center: Vector2 = spell_data["target"]
		return Rect2(center - world_size * 0.5, world_size)
	return _blizzard_world_rect(cell_rect)

func _effect_world_rect(effect: Dictionary) -> Rect2:
	if effect.get("world_rect") is Rect2:
		var world_rect: Rect2 = effect["world_rect"]
		if world_rect.size.x > 0.0 and world_rect.size.y > 0.0:
			return world_rect
	var cell_rect: Rect2i = effect.get("rect", Rect2i())
	return _blizzard_world_rect(cell_rect)

func blizzard_slow_factor_at(world: Vector2) -> float:
	var factor: float = 1.0
	for effect in _blizzard_effects:
		if _effect_world_rect(effect).has_point(world):
			factor = minf(factor, float(effect["slow_factor"]))
	for patch in _frost_trail:
		if _frost_patch_rect(patch).has_point(world):
			factor = minf(factor, float(patch.get("slow_factor", BLIZZARD_SLOW_FACTOR)))
	return factor

func is_in_blizzard_slow_rect(world: Vector2, ignore_pocket_id: int = -1) -> bool:
	for effect in _blizzard_effects:
		if ignore_pocket_id >= 0 and int(effect["pocket_id"]) == ignore_pocket_id:
			continue
		if _effect_world_rect(effect).has_point(world):
			return true
	return false

func blizzard_factory_interval_factor_at(world: Vector2, ignore_pocket_id: int = -1) -> float:
	if is_in_blizzard_slow_rect(world, ignore_pocket_id):
		return BLIZZARD_FACTORY_INTERVAL_FACTOR
	return 1.0

func live_blizzard_count() -> int:
	return _blizzard_effects.size()

func live_blizzard_rects() -> Array[Rect2i]:
	var rects: Array[Rect2i] = []
	for effect in _blizzard_effects:
		rects.append(effect["rect"])
	return rects

func drop_blizzard_for_pocket(pocket_id: int) -> void:
	var remaining: Array[Dictionary] = []
	for effect in _blizzard_effects:
		if int(effect["pocket_id"]) != pocket_id:
			remaining.append(effect)
	_blizzard_effects = remaining
	_queue_blizzard_broadcast()

func clear_blizzard_effects() -> void:
	_blizzard_effects.clear()
	_queue_blizzard_broadcast()


func frost_trail_count() -> int:
	return _frost_trail.size()


func frost_trail_covers_world(world: Vector2) -> bool:
	for patch in _frost_trail:
		if _frost_patch_rect(patch).has_point(world):
			return true
	return false


func clear_frost_trail() -> void:
	_frost_trail.clear()
	_frost_last_world = Vector2.INF
	_sync_frost_trail_visuals()
	_queue_blizzard_broadcast()


func stamp_frost_world(world: Vector2) -> bool:
	if not DmUnlocks.is_owned("tshirt_in_december"):
		return false
	_stamp_frost_world(world, blizzard_now())
	_frost_last_world = world
	_sync_frost_trail_visuals()
	_queue_blizzard_broadcast()
	return true


func _frost_patch_rect(patch: Dictionary) -> Rect2:
	var origin: Vector2 = patch.get("world", Vector2.ZERO)
	var half: float = FROST_TRAIL_SIZE * 0.5
	return Rect2(origin - Vector2(half, half), Vector2(FROST_TRAIL_SIZE, FROST_TRAIL_SIZE))


func _tick_frost_trail() -> void:
	var now: float = blizzard_now()
	var expired: bool = _expire_frost_trail(now)
	if not DmUnlocks.is_owned("tshirt_in_december"):
		if not _frost_trail.is_empty() or is_finite(_frost_last_world.x):
			clear_frost_trail()
		return
	if dm == null or not is_instance_valid(dm) or bool(dm.is_downed()):
		if expired:
			_sync_frost_trail_visuals()
			_queue_blizzard_broadcast()
		return
	var world: Vector2 = dm.global_position
	if not is_finite(_frost_last_world.x):
		_frost_last_world = world
		if expired:
			_sync_frost_trail_visuals()
			_queue_blizzard_broadcast()
		return
	if world.distance_to(_frost_last_world) < FROST_TRAIL_SPACING:
		if expired:
			_sync_frost_trail_visuals()
			_queue_blizzard_broadcast()
		return
	_stamp_frost_world(world, now)
	_frost_last_world = world
	_sync_frost_trail_visuals()
	_queue_blizzard_broadcast()


func _stamp_frost_world(world: Vector2, now: float) -> void:
	_frost_trail.append({
		"world": world,
		"expires_at": now + FROST_TRAIL_DURATION,
		"slow_factor": BLIZZARD_SLOW_FACTOR,
	})


func _expire_frost_trail(now: float) -> bool:
	var remaining: Array[Dictionary] = []
	var dropped := false
	for patch in _frost_trail:
		if float(patch.get("expires_at", 0.0)) <= now:
			dropped = true
			continue
		remaining.append(patch)
	_frost_trail = remaining
	return dropped


func pack_frost_trail(now: float = -1.0) -> Array:
	var t: float = blizzard_now() if now < 0.0 else now
	var packed: Array = []
	for patch in _frost_trail:
		var remaining: float = maxf(0.0, float(patch.get("expires_at", 0.0)) - t)
		if remaining <= 0.0:
			continue
		var world: Vector2 = patch.get("world", Vector2.INF)
		if not is_finite(world.x):
			continue
		packed.append({
			"x": world.x,
			"y": world.y,
			"remaining": remaining,
			"slow_factor": float(patch.get("slow_factor", BLIZZARD_SLOW_FACTOR)),
		})
	return packed


func apply_frost_trail(packed: Array, now: float = -1.0) -> void:
	var t: float = blizzard_now() if now < 0.0 else now
	var patches: Array[Dictionary] = []
	for item in packed:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var remaining: float = float(item.get("remaining", 0.0))
		if remaining <= 0.0:
			continue
		patches.append({
			"world": Vector2(float(item.get("x", 0.0)), float(item.get("y", 0.0))),
			"expires_at": t + remaining,
			"slow_factor": float(item.get("slow_factor", BLIZZARD_SLOW_FACTOR)),
		})
	_frost_trail = patches
	_sync_frost_trail_visuals()


func _sync_frost_trail_visuals() -> void:
	var root: Node2D = _ensure_frost_overlay_root()
	if root == null:
		return
	for child in root.get_children():
		root.remove_child(child)
		child.queue_free()
	var scale: float = FROST_TRAIL_SIZE / BlizzardIceDrawScript.TILE_PX
	for patch in _frost_trail:
		var world: Vector2 = patch.get("world", Vector2.INF)
		if not is_finite(world.x):
			continue
		var sprite: Sprite2D = BlizzardIceDrawScript.make_tile(Vector2i.ONE, Vector2i.ZERO)
		sprite.scale = Vector2(scale, scale)
		sprite.z_index = -1
		sprite.position = world - root.global_position
		root.add_child(sprite)


func _ensure_frost_overlay_root() -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	var host: Node = tree.get_first_node_in_group("level_manager")
	if host == null:
		host = tree.current_scene
	if host == null:
		host = self
	var existing: Node = host.get_node_or_null("FrostTrailOverlay")
	if existing is Node2D:
		return existing as Node2D
	var root := Node2D.new()
	root.name = "FrostTrailOverlay"
	root.z_index = -1
	root.z_as_relative = false
	root.y_sort_enabled = false
	host.add_child(root)
	return root

func expire_blizzard_due(now: float) -> void:
	var remaining: Array[Dictionary] = []
	var expired_ids: Array[int] = []
	for effect in _blizzard_effects:
		if float(effect["expires_at"]) <= now:
			expired_ids.append(int(effect["pocket_id"]))
		else:
			remaining.append(effect)
	_blizzard_effects = remaining
	var fantasy: FantasyZone = _fantasy_zone()
	if fantasy != null:
		for pocket_id in expired_ids:
			fantasy.expire_pocket(pocket_id)
	elif not expired_ids.is_empty():
		_queue_blizzard_broadcast()

func _on_fantasy_pocket_expired(pocket_id: int) -> void:
	drop_blizzard_for_pocket(pocket_id)

func _on_map_bounds_cleared_blizzard() -> void:
	clear_blizzard_effects()
	clear_frost_trail()

func blizzard_now() -> float:
	var fantasy: FantasyZone = _fantasy_zone()
	if fantasy:
		return fantasy.claim_now()
	return float(Time.get_ticks_msec()) / 1000.0

func pack_blizzard_slows(now: float = -1.0) -> Array:
	var t: float = blizzard_now() if now < 0.0 else now
	var packed: Array = []
	for effect in _blizzard_effects:
		var remaining: float = maxf(0.0, float(effect["expires_at"]) - t)
		if remaining <= 0.0:
			continue
		var cell_rect: Rect2i = effect["rect"]
		if cell_rect.size.x <= 0 or cell_rect.size.y <= 0:
			continue
		var world_rect: Rect2 = _effect_world_rect(effect)
		packed.append({
			"pocket_id": int(effect["pocket_id"]),
			"x": cell_rect.position.x,
			"y": cell_rect.position.y,
			"w": cell_rect.size.x,
			"h": cell_rect.size.y,
			"wx": world_rect.position.x,
			"wy": world_rect.position.y,
			"ww": world_rect.size.x,
			"wh": world_rect.size.y,
			"remaining": remaining,
			"slow_factor": float(effect["slow_factor"]),
		})
	return packed

func apply_blizzard_slows(packed: Array, now: float = -1.0) -> void:
	var t: float = blizzard_now() if now < 0.0 else now
	var effects: Array[Dictionary] = []
	for item in packed:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var remaining: float = float(item.get("remaining", 0.0))
		if remaining <= 0.0:
			continue
		var cell_rect := Rect2i(
			int(item.get("x", 0)),
			int(item.get("y", 0)),
			int(item.get("w", 0)),
			int(item.get("h", 0))
		)
		if cell_rect.size.x <= 0 or cell_rect.size.y <= 0:
			continue
		var slow_factor: float = float(item.get("slow_factor", BLIZZARD_SLOW_FACTOR))
		if slow_factor <= 0.0:
			slow_factor = BLIZZARD_SLOW_FACTOR
		var world_rect := Rect2(
			float(item.get("wx", 0.0)),
			float(item.get("wy", 0.0)),
			float(item.get("ww", 0.0)),
			float(item.get("wh", 0.0))
		)
		if world_rect.size.x <= 0.0 or world_rect.size.y <= 0.0:
			world_rect = _blizzard_world_rect(cell_rect)
		effects.append({
			"pocket_id": int(item.get("pocket_id", 0)),
			"rect": cell_rect,
			"world_rect": world_rect,
			"expires_at": t + remaining,
			"slow_factor": slow_factor,
		})
	_blizzard_effects = effects

func pack_slowed_players() -> Array:
	var slowed: Array = []
	var tree := get_tree()
	if tree == null:
		return slowed
	for node in tree.get_nodes_in_group("players"):
		if not (node is Node2D) or not is_instance_valid(node):
			continue
		var body: Node2D = node
		var factor: float = blizzard_slow_factor_at(body.global_position)
		if factor >= 1.0:
			continue
		slowed.append({
			"name": str(body.name),
			"x": body.global_position.x,
			"y": body.global_position.y,
			"slow_factor": factor,
		})
	return slowed

func pack_factory_timers() -> Array:
	var packed: Array = []
	var tree := get_tree()
	if tree == null:
		return packed
	for node in tree.get_nodes_in_group("factories"):
		if not is_instance_valid(node) or not node.has_method("to_timer_sync_dict"):
			continue
		if bool(node.get("is_ghost")):
			continue
		packed.append(node.to_timer_sync_dict())
	return packed

func apply_factory_timers(packed: Array) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var by_name: Dictionary = {}
	var factories: Array = []
	for node in tree.get_nodes_in_group("factories"):
		if not is_instance_valid(node):
			continue
		by_name[str(node.name)] = node
		factories.append(node)
	for item in packed:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var factory: Node = by_name.get(str(item.get("name", "")), null)
		if factory == null:
			factory = _match_factory_by_position(factories, item)
		if factory and factory.has_method("apply_timer_sync_dict"):
			factory.apply_timer_sync_dict(item)

func _match_factory_by_position(factories: Array, item: Dictionary) -> Node:
	var want := Vector2(float(item.get("x", 0.0)), float(item.get("y", 0.0)))
	var best: Node = null
	var best_d: float = 4.0
	for node in factories:
		if not (node is Node2D):
			continue
		var d: float = (node as Node2D).global_position.distance_squared_to(want)
		if d <= best_d:
			best_d = d
			best = node
	return best

func late_join_blizzard_snapshot() -> Dictionary:
	var claim_payload: Dictionary = {}
	var fantasy: FantasyZone = _fantasy_zone()
	if fantasy:
		claim_payload = fantasy.build_claim_sync_payload()
	return {
		"unlocks": DmUnlocks.snapshot(),
		"claim": claim_payload,
		"slows": pack_blizzard_slows(),
		"frost": pack_frost_trail(),
		"slowed": pack_slowed_players(),
		"factories": pack_factory_timers(),
	}

func apply_late_join_blizzard_snapshot(payload: Dictionary) -> void:
	if payload.has("unlocks") and typeof(payload["unlocks"]) == TYPE_DICTIONARY:
		var unlocks: Dictionary = payload["unlocks"]
		if not unlocks.is_empty():
			DmUnlocks.apply_replicated_unlocks(unlocks)
	var fantasy: FantasyZone = _fantasy_zone()
	if fantasy and payload.has("claim") and typeof(payload["claim"]) == TYPE_DICTIONARY:
		var claim_payload: Dictionary = payload["claim"]
		if not claim_payload.is_empty():
			fantasy.apply_claim_sync_payload(claim_payload)
	if payload.has("slows") and typeof(payload["slows"]) == TYPE_ARRAY:
		apply_blizzard_slows(payload["slows"])
	if payload.has("frost") and typeof(payload["frost"]) == TYPE_ARRAY:
		apply_frost_trail(payload["frost"])
	if payload.has("factories") and typeof(payload["factories"]) == TYPE_ARRAY:
		apply_factory_timers(payload["factories"])

func sync_blizzard_to_peer(peer_id: int) -> void:
	if not Lobby.is_network_server():
		return
	replicate_blizzard_state.rpc_id(peer_id, late_join_blizzard_snapshot())

func _queue_blizzard_broadcast() -> void:
	if not Lobby.is_network_server():
		return
	if _blizzard_broadcast_queued:
		return
	_blizzard_broadcast_queued = true
	call_deferred("_flush_blizzard_broadcast")

func _flush_blizzard_broadcast() -> void:
	_blizzard_broadcast_queued = false
	if not Lobby.is_network_server():
		return
	replicate_blizzard_state.rpc(late_join_blizzard_snapshot())

@rpc("authority", "reliable")
func replicate_blizzard_state(payload: Dictionary) -> void:
	if Lobby.is_network_server():
		return
	apply_late_join_blizzard_snapshot(payload)

func _is_dm_peer(peer_id: int) -> bool:
	if peer_id <= 0:
		return false
	if dm != null and is_instance_valid(dm):
		return peer_id == dm.get_multiplayer_authority()
	return peer_id == 1

func apply_replicated_mana(new_current: int, new_max: int) -> void:
	max_mana = maxi(0, new_max)
	current_mana = clampi(new_current, 0, max_mana)
	mana_changed.emit(current_mana, max_mana)

func _host_set_mana(value: int) -> void:
	current_mana = clampi(value, 0, max_mana)
	request_mana_sync.rpc(current_mana, max_mana)

func update_fantasy_level(level_inc: int) -> void:
	if multiplayer.is_server():
		request_fantasy_level_incrase.rpc(maxi(0, fantasy_level + level_inc))
		
func unlock(unlock_name: String) -> void:
	if multiplayer.is_server():
		DmUnlocks.unlock(unlock_name)


func _host_set_skill_points(value: int) -> void:
	skill_points = maxi(0, value)
	apply_skill_points.rpc(skill_points)


func grant_skill_points(amount: int) -> void:
	if not multiplayer.is_server():
		return
	if amount <= 0:
		return
	skill_points = maxi(0, skill_points + amount)
	apply_skill_points.rpc(skill_points, amount)


func request_purchase(tree: String, node_id: String) -> String:
	if multiplayer.is_server():
		return _host_try_purchase(tree, node_id)
	request_purchase_rpc.rpc_id(1, tree, node_id)
	return ""


func purchase_status(node_id: String) -> String:
	var entry: Dictionary = SkillTreeCatalogScript.node_for(node_id)
	if entry.is_empty():
		return SkillTreeCatalogScript.REASON_UNKNOWN
	if DmUnlocks.is_owned(node_id):
		return "owned"
	var reason: String = _gate_reason(entry)
	if reason != SkillTreeCatalogScript.REASON_OK:
		return reason
	if skill_points < int(entry.get("cost", 0)):
		return SkillTreeCatalogScript.REASON_NOT_ENOUGH_SP
	return "available"


func _host_try_purchase(tree: String, node_id: String) -> String:
	var entry: Dictionary = SkillTreeCatalogScript.node_for(node_id)
	var reason: String = SkillTreeCatalogScript.REASON_UNKNOWN
	if not entry.is_empty():
		if tree != "" and str(entry.get("tree", "")) != tree:
			reason = SkillTreeCatalogScript.REASON_UNKNOWN
		elif DmUnlocks.is_owned(node_id):
			reason = SkillTreeCatalogScript.REASON_ALREADY_OWNED
		else:
			reason = _gate_reason(entry)
			if reason == SkillTreeCatalogScript.REASON_OK:
				var cost: int = int(entry.get("cost", 0))
				if skill_points < cost:
					reason = SkillTreeCatalogScript.REASON_NOT_ENOUGH_SP
				else:
					skill_points -= cost
					DmUnlocks.unlock(node_id)
					apply_skill_points.rpc(skill_points)
					reason = SkillTreeCatalogScript.REASON_OK
	notify_purchase_result.rpc(node_id, reason)
	return reason


func _gate_reason(entry: Dictionary) -> String:
	if bool(entry.get("ultimate", false)):
		var tree: String = str(entry.get("tree", ""))
		for row in range(1, 4):
			var covered := false
			for pid in SkillTreeCatalogScript.ids_in_tree_row(tree, row):
				if DmUnlocks.is_owned(pid):
					covered = true
					break
			if not covered:
				return SkillTreeCatalogScript.REASON_ULTIMATE_PREREQ
		return SkillTreeCatalogScript.REASON_OK
	var row: int = int(entry.get("row", 0))
	var need_fl: int = SkillTreeCatalogScript.fl_gate_for_row(row)
	if fantasy_level < need_fl:
		return SkillTreeCatalogScript.REASON_ROW_GATED
	return SkillTreeCatalogScript.REASON_OK


@rpc("any_peer", "reliable")
func request_purchase_rpc(tree: String, node_id: String) -> void:
	if not multiplayer.is_server():
		return
	if not _is_dm_peer(multiplayer.get_remote_sender_id()):
		return
	_host_try_purchase(tree, node_id)


@rpc("authority", "call_local", "reliable")
func notify_purchase_result(node_id: String, reason: String) -> void:
	skill_purchase_finished.emit(node_id, reason)


@rpc("authority", "call_local", "reliable")
func apply_skill_points(value: int, rewarded: int = 0) -> void:
	skill_points = maxi(0, value)
	skill_points_changed.emit(skill_points)
	if rewarded > 0:
		skill_point_rewarded.emit(rewarded)
		
func is_crib_death_owned() -> bool:
	return bool(DmUnlocks.dm_unlocks.get("crib_death", false))

func crib_death_exit_world() -> Vector2:
	var tree := get_tree()
	if tree == null:
		return Vector2.INF
	var level: Node = tree.get_first_node_in_group("level_manager")
	if level != null and level.has_method("dungeon_exit_landing_world"):
		var landing: Vector2 = level.call("dungeon_exit_landing_world")
		if landing.is_finite():
			return landing
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager != null and manager.has_method("get_exit_cell"):
		var cell: Vector2i = manager.get_exit_cell()
		if cell != DungeonGrid.SENTINEL:
			return DungeonGrid.to_world_center(cell)
	return Vector2.INF

func try_spawn_crib_death_gremlin() -> Node:
	if not multiplayer.is_server():
		return null
	if not is_crib_death_owned():
		return null
	print ("spawning crib de")
	var world_position: Vector2 = crib_death_exit_world()
	if not world_position.is_finite():
		return null
	var spawner: Node = _multiplayer_spawner()
	if spawner == null or not spawner.has_method("spawn_gremlin_at"):
		return null
	var node: Node = spawner.call("spawn_gremlin_at", world_position)
	if node is Gremlin:
		(node as Gremlin).lifetime_sec = CRIB_DEATH_LIFETIME_SEC
	elif node != null:
		node.set("lifetime_sec", CRIB_DEATH_LIFETIME_SEC)
	return node

func spawn_gremlin() -> void:
	if multiplayer.is_server():
		spawn_gremlin_cast.emit()
		
func spawn_knight() -> void:
	if multiplayer.is_server():
		spawn_knight_cast.emit()

func spawn_goblin() -> void:
	if multiplayer.is_server():
		spawn_goblin_cast.emit()


func _headless_near_dm_spawn_count(ability_id: String) -> int:
	var tree := get_tree()
	if tree == null:
		return 0
	var anchor: Vector2 = DmNearSpawnPickerScript.dm_anchor_world()
	if ability_id == AbilityCatalog.KNIGHTLING:
		var n: int = 3 if DmUnlocks.is_owned("chain_lightning") else 1
		var ok := 0
		for _i in range(n):
			var pick: Dictionary = DmNearSpawnPickerScript.pick_near_dm(tree, anchor)
			if bool(pick.get("ok", false)):
				ok += 1
		return ok
	var pick: Dictionary = DmNearSpawnPickerScript.pick_near_dm(tree, anchor)
	return 1 if bool(pick.get("ok", false)) else 0


func _multiplayer_spawner() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("multiplayer_spawner")
		
@rpc("authority", "call_local", "reliable")
func request_fantasy_level_incrase(new_fantasy_level: int):
	if fantasy_level == new_fantasy_level:
		return
	var old_level: int = fantasy_level
	fantasy_level = new_fantasy_level
	fantasy_level_changed.emit(new_fantasy_level)
	if multiplayer.is_server() and new_fantasy_level > old_level:
		var earned: int = int(new_fantasy_level / FANTASY_PER_SKILL_POINT) - int(old_level / FANTASY_PER_SKILL_POINT)
		grant_skill_points(earned)

@rpc("authority", "call_local", "reliable")
func request_mana_sync(new_current: int, new_max: int) -> void:
	apply_replicated_mana(new_current, new_max)

@rpc("authority", "call_local", "reliable")
func request_health_sync(new_hp: int, new_max_hp: int) -> void:
	apply_replicated_health(new_hp, new_max_hp)

@rpc("any_peer", "reliable")
func request_cast_rpc(ability_id: String) -> void:
	if not multiplayer.is_server():
		return
	if not _is_dm_peer(multiplayer.get_remote_sender_id()):
		return
	_server_request_cast(ability_id)

@rpc("any_peer", "reliable")
func request_launch_blizzard_rpc(spell_data: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	if not _is_dm_peer(multiplayer.get_remote_sender_id()):
		return
	launch_blizzard(spell_data)
	
func _show_skill_tree_hud() -> void:
	DmHud._toggle_skill_tree_hud()
