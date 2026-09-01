extends Node

## US-033 alias autoload for MinimapReveal.
## Kept so project.godot / docs can resolve MinimapFog; state lives on MinimapReveal.

func _ready() -> void:
	set_process(false)


func get_reveal() -> Node:
	return get_node_or_null("/root/MinimapReveal")
