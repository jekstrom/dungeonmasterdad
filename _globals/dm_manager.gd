extends Node

#const __DM__ = preload("uid://e1aypo2ysyyc")
#const INVENTORY_DATA: InventoryData = preload("res://gui/pause_menu/inventory/player_inventory.tres")

#signal interact_pressed

const AbilityCatalog = preload("res://dm/dm_ability_catalog.gd")
const DEFAULT_MAX_MANA: int = 100
const BLIZZARD_DURATION: float = 8.0
const BLIZZARD_SLOW_FACTOR: float = 0.5
const BLIZZARD_POCKET_CELLS: Vector2i = Vector2i(3, 3)

var dm: DM
@export var fantasy_level: int = 0
@export var max_mana: int = DEFAULT_MAX_MANA
var current_mana: int = 0
signal fantasy_level_changed(new_fantasy_level: int)
signal mana_changed(new_current: int, new_max: int)
signal spawn_gremlin_cast
signal spawn_knight_cast
var player_spawned: bool = false
var _blizzard_effects: Array[Dictionary] = []
var dm_player_name: String = "DM"

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
	_host_set_mana(0)

func add_player_instance() -> void:
	pass

func set_player_pos(new_pos: Vector2) -> void:
	dm.global_position = new_pos

func set_player_health(hp: int, max_hp: int) -> void:
	dm.max_hp = max_hp
	dm.hitpoints = hp

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
	if ability_id != AbilityCatalog.GREMLIN and ability_id != AbilityCatalog.KNIGHTLING:
		return
	if not try_cast(ability_id):
		return
	if ability_id == AbilityCatalog.GREMLIN:
		spawn_gremlin()
	elif ability_id == AbilityCatalog.KNIGHTLING:
		spawn_knight()

func launch_fireball(spell_data: Dictionary) -> bool:
	if not multiplayer.is_server():
		return false
	if not try_cast(AbilityCatalog.FIREBALL):
		return false
	update_fantasy_level(15)
	SignalBus.spell_cast.emit(AbilityCatalog.FIREBALL, spell_data)
	return true

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
	var duration: float = float(spell_data.get("duration", BLIZZARD_DURATION))
	if duration <= 0.0:
		duration = BLIZZARD_DURATION
	var slow_factor: float = float(spell_data.get("slow_factor", BLIZZARD_SLOW_FACTOR))
	if slow_factor <= 0.0:
		slow_factor = BLIZZARD_SLOW_FACTOR
	var proposed: Rect2i = _blizzard_rect_from_spell(spell_data)
	var clipped: Rect2i = fantasy.clip_pocket_rect(proposed)
	if clipped.size.x <= 0 or clipped.size.y <= 0:
		return false
	if not try_cast(AbilityCatalog.BEMIDJI_BLIZZARD):
		return false
	var pocket_id: int = fantasy.spawn_pocket(clipped.position, clipped.size, duration)
	if pocket_id < 0:
		return false
	var pocket: Dictionary = fantasy.get_pocket(pocket_id)
	var rect: Rect2i = clipped
	var expires_at: float = fantasy.claim_now() + duration
	if not pocket.is_empty():
		rect = pocket["rect"]
		expires_at = float(pocket["expires_at"])
	_blizzard_effects.append({
		"pocket_id": pocket_id,
		"rect": rect,
		"expires_at": expires_at,
		"slow_factor": slow_factor,
	})
	SignalBus.spell_cast.emit(AbilityCatalog.BEMIDJI_BLIZZARD, spell_data)
	return true

func _can_try_cast(ability_id: String) -> bool:
	if not multiplayer.is_server():
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

func blizzard_slow_factor_at(world: Vector2) -> float:
	var factor: float = 1.0
	for effect in _blizzard_effects:
		var cell_rect: Rect2i = effect["rect"]
		if cell_rect.size.x <= 0 or cell_rect.size.y <= 0:
			continue
		var world_rect := Rect2(
			DungeonGrid.to_world(cell_rect.position),
			Vector2(cell_rect.size) * DungeonGrid.CELL_PX
		)
		if world_rect.has_point(world):
			factor = minf(factor, float(effect["slow_factor"]))
	return factor

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

func clear_blizzard_effects() -> void:
	_blizzard_effects.clear()

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
	if fantasy == null:
		return
	for pocket_id in expired_ids:
		fantasy.expire_pocket(pocket_id)

func _on_fantasy_pocket_expired(pocket_id: int) -> void:
	drop_blizzard_for_pocket(pocket_id)

func _on_map_bounds_cleared_blizzard() -> void:
	clear_blizzard_effects()

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
		fantasy_level = maxi(0, fantasy_level + level_inc)
		request_fantasy_level_incrase.rpc(fantasy_level)
		
func unlock(unlock_name: String) -> void:
	if multiplayer.is_server():
		DmUnlocks.unlock(unlock_name)
		request_fantasy_level_incrase.rpc(fantasy_level)
		
func spawn_gremlin() -> void:
	if multiplayer.is_server():
		spawn_gremlin_cast.emit()
		
func spawn_knight() -> void:
	if multiplayer.is_server():
		spawn_knight_cast.emit()
		
@rpc("authority", "call_local", "reliable")
func request_fantasy_level_incrase(new_fantasy_level: int):
		fantasy_level = new_fantasy_level
		fantasy_level_changed.emit(new_fantasy_level)

@rpc("authority", "call_local", "reliable")
func request_mana_sync(new_current: int, new_max: int) -> void:
	apply_replicated_mana(new_current, new_max)

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
