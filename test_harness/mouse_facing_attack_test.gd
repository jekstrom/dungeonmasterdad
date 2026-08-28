extends Node

func _ready() -> void:
	var down: Vector2 = Player.cardinal_from_aim(Vector2(0, 80))
	var up: Vector2 = Player.cardinal_from_aim(Vector2(0, -80))
	var right: Vector2 = Player.cardinal_from_aim(Vector2(80, 0))
	var left: Vector2 = Player.cardinal_from_aim(Vector2(-80, 0))
	if down != Vector2.DOWN:
		push_error("mouse facing test: expected DOWN, got %s" % down)
		get_tree().quit(1)
		return
	if up != Vector2.UP:
		push_error("mouse facing test: expected UP, got %s" % up)
		get_tree().quit(1)
		return
	if right != Vector2.RIGHT:
		push_error("mouse facing test: expected RIGHT, got %s" % right)
		get_tree().quit(1)
		return
	if left != Vector2.LEFT:
		push_error("mouse facing test: expected LEFT, got %s" % left)
		get_tree().quit(1)
		return

	var hold: Vector2 = Player.cardinal_from_aim(Vector2(2, 2), Vector2.UP)
	if hold != Vector2.UP:
		push_error("mouse facing test: deadzone should keep current facing, got %s" % hold)
		get_tree().quit(1)
		return

	var has_key := false
	var has_mouse := false
	for event in InputMap.action_get_events("attack"):
		if event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_SPACE:
			has_key = true
		if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			has_mouse = true
	if not has_key or not has_mouse:
		push_error("mouse facing test: attack action missing space or mouse1")
		get_tree().quit(1)
		return

	print("mouse facing attack test passed")
	get_tree().quit(0)
