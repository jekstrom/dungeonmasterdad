extends Label

@export var enabled: bool = false

func _process(_delta):
	if !enabled: return
	var mouse_pos = get_global_mouse_position()
	var reality_zone_pos = get_parent().find_child("RealityZone").global_position
	var reality_zone_radius = get_parent().find_child("RealityZone").radius
	var placement_rect = Rect2(mouse_pos.x - 64, mouse_pos.y - 64, 128, 128)
	var corners = [
		placement_rect.position, # Top-Left
		Vector2(placement_rect.end.x, placement_rect.position.y), # Top-Right
		placement_rect.end, # Bottom-Right
		Vector2(placement_rect.position.x, placement_rect.end.y) # Bottom-Left
	]
	text = str(mouse_pos) + "\n " + str(corners) + "\n " + str(reality_zone_pos) + "\n " + str(reality_zone_radius)
	
	# Keep the label right next to the cursor
	global_position = mouse_pos + Vector2(15, -50)
