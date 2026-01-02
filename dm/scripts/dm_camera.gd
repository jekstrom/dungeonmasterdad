class_name DmCamera extends Camera2D

func _ready() -> void:
	if !is_multiplayer_authority(): return
	
	LevelManager.TilemapBoundsChanged.connect(update_limits)
	update_limits(LevelManager.current_tilemap_bounds)

func update_limits(bounds: Rect2i) -> void:
	if !is_multiplayer_authority(): return
	
	if bounds && bounds.end.x > 0:
		limit_left = int(bounds.position.x)
		limit_top = int(bounds.position.y)
		limit_right = int(bounds.end.x)
		limit_bottom = int(bounds.end.y)
