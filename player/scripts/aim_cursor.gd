extends CanvasLayer

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	var body := get_parent()
	var local: bool = body != null and body.is_multiplayer_authority()
	visible = local
	set_process(local)

func _process(_delta: float) -> void:
	if sprite:
		sprite.position = get_viewport().get_mouse_position()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var body := get_parent()
	if body and "current_targeting" in body and body.current_targeting:
		if sprite:
			sprite.visible = false
	elif sprite:
		sprite.visible = true
