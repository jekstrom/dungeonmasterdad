class_name ItemData extends Resource

const WORLD_RESOURCE_PATHS: Array[String] = [
	"res://pickups/wood.tres",
	"res://pickups/metal.tres",
	"res://pickups/paper.tres",
	"res://pickups/blank_form.tres",
	"res://pickups/filled_form.tres",
	"res://pickups/tax_form.tres",
]

@export var name: String = ""
@export_multiline var description: String = ""
@export var auto_use: bool = false
@export_enum("dm_only", "player_only") var pickup_char: String = ""
@export var pickup_sound: AudioStream
@export_enum("active", "static") var inventory_row: String = "static"
@export var channel_use: bool = false

@export var texture: Texture2D
@export_category("Use Effects")
@export var effects: Array[ItemEffect]

func is_active_row() -> bool:
	return inventory_row == "active"


func is_world_resource() -> bool:
	return WORLD_RESOURCE_PATHS.has(resource_path)


static func is_world_resource_path(item_path: String) -> bool:
	return WORLD_RESOURCE_PATHS.has(item_path)

func use() -> bool:
	if effects.size() == 0:
		return false
	for e in effects:
		if e != null:
			e.use()
		
	return true
