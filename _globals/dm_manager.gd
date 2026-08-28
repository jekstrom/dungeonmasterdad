extends Node

#const __DM__ = preload("uid://e1aypo2ysyyc")
#const INVENTORY_DATA: InventoryData = preload("res://gui/pause_menu/inventory/player_inventory.tres")

#signal interact_pressed

const AbilityCatalog = preload("res://dm/dm_ability_catalog.gd")
const DEFAULT_MAX_MANA: int = 100

var dm: DM
@export var fantasy_level: int = 0
@export var max_mana: int = DEFAULT_MAX_MANA
var current_mana: int = 0
signal fantasy_level_changed(new_fantasy_level: int)
signal mana_changed(new_current: int, new_max: int)
signal spawn_gremlin_cast
signal spawn_knight_cast
var player_spawned: bool = false
var dm_player_name: String = "DM"

func _ready() -> void:
	if not Lobby.host_started.is_connected(_on_host_started):
		Lobby.host_started.connect(_on_host_started)
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
