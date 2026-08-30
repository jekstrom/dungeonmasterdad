class_name SmokeFactory extends Building
@onready var sprite_2d_3: Sprite2D = $Sprite2D3
@onready var sprite_2d_2: Sprite2D = $Sprite2D2

func _ready() -> void:
	super._ready()
	if sprite_2d_3 and sprite_2d_2:
		sprite_2d_2.visible = false
		sprite_2d_3.visible = false
	if not destroyed and animation_player:
		animation_player.play("smoke")

func _process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	if not is_operating():
		return
	sync_blizzard_interval()
	timer += delta
	if timer >= interval:
		if not is_operating():
			return
		timer -= interval
		PlayerManager.add_smoke(1)
