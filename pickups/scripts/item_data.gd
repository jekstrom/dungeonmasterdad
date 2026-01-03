class_name ItemData extends Resource

@export var name: String = ""
@export_multiline var description: String = ""
@export var auto_use: bool = false
@export_enum("dm_only", "player_only") var pickup_char: String = ""
@export var pickup_sound: AudioStream

@export var texture: Texture2D
@export_category("Use Effects")
@export var effects: Array[ItemEffect]

func use() -> bool:
	if effects.size() == 0:
		return false
	for e in effects:
		if e != null:
			e.use()
		
	return true
