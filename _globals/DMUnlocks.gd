extends Node

const SkillTreeCatalogScript = preload("res://dm/skill_tree_catalog.gd")

var dm_unlocks = {}

func _ready() -> void:
	reset_unlocks()
	if not Lobby.host_started.is_connected(_on_host_started):
		Lobby.host_started.connect(_on_host_started)

func _on_host_started(_player_name: String = "") -> void:
	if not Lobby.is_network_server():
		return
	reset_unlocks()
	replicate_unlocks.rpc(snapshot())

func reset_unlocks() -> void:
	dm_unlocks = {
		"fireball": false,
		"shadow_zone": false,
		"knightling": false,
		"bemidji_blizzard": false,
	}
	for node_id in SkillTreeCatalogScript.all_ids():
		dm_unlocks[node_id] = false
	for unlock_name in dm_unlocks.keys():
		SignalBus.on_dm_lock.emit(str(unlock_name))


func is_owned(unlock_name: String) -> bool:
	return bool(dm_unlocks.get(unlock_name, false))

func snapshot() -> Dictionary:
	return dm_unlocks.duplicate()

func apply_replicated_unlocks(unlocks: Dictionary) -> void:
	for key in unlocks.keys():
		var unlock_name: String = str(key)
		var unlocked: bool = bool(unlocks[key])
		dm_unlocks[unlock_name] = unlocked
		if unlocked:
			SignalBus.on_dm_unlock.emit(unlock_name)
		else:
			SignalBus.on_dm_lock.emit(unlock_name)

func unlock(unlock_name: String) -> void:
	dm_unlocks[unlock_name] = true
	on_dm_unlock.rpc(unlock_name)

func lock(unlock_name: String) -> void:
	dm_unlocks[unlock_name] = false
	on_dm_lock.rpc(unlock_name)

@rpc("authority", "call_local", "reliable")
func on_dm_unlock(unlock_name: String) -> void:
	var id = multiplayer.get_unique_id()
	dm_unlocks[unlock_name] = true
	SignalBus.on_dm_unlock.emit(unlock_name)
	print("DM UNLOCKED ", unlock_name , " (heard by mp id ", id, ")")

@rpc("authority", "call_local", "reliable")
func on_dm_lock(unlock_name: String) -> void:
	var id = multiplayer.get_unique_id()
	dm_unlocks[unlock_name] = false
	SignalBus.on_dm_lock.emit(unlock_name)
	print("DM LOCKED ", unlock_name , " (heard by mp id ", id, ")")

@rpc("authority", "call_local", "reliable")
func replicate_unlocks(unlocks: Dictionary) -> void:
	apply_replicated_unlocks(unlocks)
