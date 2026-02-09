extends Node

var dm_unlocks = {}

func _ready() -> void:
	dm_unlocks = {
		"fireball": false,
		"shadow_zone": false,
	}
	
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
