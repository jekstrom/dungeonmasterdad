extends Node

var dm_unlocks = {}

func _ready() -> void:
	dm_unlocks = {
		"fireball": false
	}
	
func unlock_fireball() -> void:
	dm_unlocks["fireball"] = true
	on_dm_unlock.rpc("fireball")
	SignalBus.on_dm_unlock.emit("fireball")

@rpc("authority", "call_local", "reliable")
func on_dm_unlock(unlock_name: String) -> void:
	var id = multiplayer.get_unique_id()
	print("DM UNLOCKED ", unlock_name , " (heard by mp id ", id, ")")
