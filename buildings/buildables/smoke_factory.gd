class_name SmokeFactory extends Building

func _process(delta: float) -> void:
	if is_ghost: return
	timer += delta
	if timer >= interval:
		timer -= interval
		PlayerManager.update_reality_level(1)
