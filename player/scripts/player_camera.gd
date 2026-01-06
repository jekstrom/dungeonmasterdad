class_name PlayerCamera extends Camera2D

func _ready() -> void:
	if !is_multiplayer_authority(): return
