class_name DamageNumber extends Label

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.animation_finished.connect(on_animation_end)
	
func on_animation_end(_anim_name: String) -> void:
	queue_free()
