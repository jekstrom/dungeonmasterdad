class_name SmokeFactory extends Building
@onready var sprite_2d_3: Sprite2D = $Sprite2D3
@onready var sprite_2d_2: Sprite2D = $Sprite2D2

func _ready() -> void:
	if sprite_2d_3 and sprite_2d_2:
		sprite_2d_2.visible = false
		sprite_2d_3.visible = false
	animation_player.play("smoke")
		
func _process(delta: float) -> void:
	if not multiplayer.is_server(): return
	if is_ghost: return
	sync_blizzard_interval()
	timer += delta
	if timer >= interval:
		timer -= interval
		PlayerManager.add_smoke(1)
