extends Node

const Catalog = preload("res://dm/dm_ability_catalog.gd")
const OverlayScript = preload("res://gui/dm/ability_cooldown_overlay.gd")


func _ready() -> void:
	if not _run_suite():
		return
	print("ability cooldown overlay test passed")
	get_tree().quit(0)


func _run_suite() -> bool:
	DmUnlocks.reset_unlocks()
	DmManager.clear_all_ability_cooldowns()
	if not is_equal_approx(DmManager.ability_cooldown(Catalog.GREMLIN), 0.0):
		return _fail("gremlin cooldown duration must be 0")
	if not is_equal_approx(DmManager.ability_cooldown(Catalog.BEMIDJI_BLIZZARD), 0.0):
		return _fail("blizzard cooldown duration must be 0")
	DmManager.start_ability_cooldown(Catalog.GREMLIN)
	if DmManager.ability_cooldown_remaining(Catalog.GREMLIN) > 0.0:
		return _fail("zero-duration ability must not start a cooldown")
	if not is_equal_approx(DmManager.ability_cooldown(Catalog.FIREBALL), DmManager.FIREBALL_COOLDOWN):
		return _fail("fireball cooldown duration must be baseline")
	if not is_equal_approx(DmManager.ability_cooldown_ratio(Catalog.FIREBALL), 0.0):
		return _fail("fireball ratio must start at 0")
	DmManager.start_ability_cooldown(Catalog.FIREBALL)
	if not is_equal_approx(DmManager.ability_cooldown_ratio(Catalog.FIREBALL), 1.0):
		return _fail("fireball ratio after start must be 1")
	if not is_equal_approx(DmManager.fireball_cooldown_remaining(), DmManager.FIREBALL_COOLDOWN):
		return _fail("fireball remaining wrapper must match duration")
	if DmHud == null:
		return _fail("DmHud autoload missing")
	var slots: Array = [
		[DmHud.spawn_gremlin_button, Catalog.GREMLIN],
		[DmHud.spawn_goblin_button, Catalog.GOBLIN],
		[DmHud.spawn_knight_button, Catalog.KNIGHTLING],
		[DmHud.cast_fireball_button, Catalog.FIREBALL],
		[DmHud.cast_blizzard_button, Catalog.BEMIDJI_BLIZZARD],
	]
	for pair in slots:
		var button: TextureButton = pair[0]
		var ability_id: String = pair[1]
		if button == null:
			return _fail("HUD button missing for %s" % ability_id)
		var overlay: Control = _overlay_on(button)
		if overlay == null:
			return _fail("cooldown overlay missing on %s" % ability_id)
		if overlay.ability_id != ability_id:
			return _fail("overlay ability_id want %s got %s" % [ability_id, overlay.ability_id])
		if overlay.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			return _fail("overlay must ignore mouse on %s" % ability_id)
	var fire_overlay: Control = _overlay_on(DmHud.cast_fireball_button)
	fire_overlay._process(0.0)
	if not is_equal_approx(fire_overlay.cooldown_ratio(), 1.0):
		return _fail("fireball overlay ratio want 1 got %s" % fire_overlay.cooldown_ratio())
	if not fire_overlay.visible:
		return _fail("fireball overlay must show while cooling down")
	var want_text: String = "%.1f" % DmManager.FIREBALL_COOLDOWN
	if fire_overlay.cooldown_text() != want_text:
		return _fail("fireball overlay text want %s got %s" % [want_text, fire_overlay.cooldown_text()])
	var label: Label = fire_overlay.get_node_or_null("Label") as Label
	if label == null:
		for child in fire_overlay.get_children():
			if child is Label:
				label = child
				break
	if label == null:
		return _fail("fireball overlay must host a remaining-time label")
	if label.horizontal_alignment != HORIZONTAL_ALIGNMENT_CENTER:
		return _fail("cooldown label must be horizontally centered")
	if label.vertical_alignment != VERTICAL_ALIGNMENT_CENTER:
		return _fail("cooldown label must be vertically centered")
	if label.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		return _fail("cooldown label must ignore mouse")
	var gremlin_overlay: Control = _overlay_on(DmHud.spawn_gremlin_button)
	gremlin_overlay._process(0.0)
	if not is_equal_approx(gremlin_overlay.cooldown_ratio(), 0.0):
		return _fail("gremlin overlay ratio must stay 0")
	if gremlin_overlay.visible:
		return _fail("gremlin overlay must hide when ready")
	if gremlin_overlay.cooldown_text() != "":
		return _fail("ready overlay must not show remaining text")
	DmManager.clear_fireball_cooldown()
	fire_overlay._process(0.0)
	if not is_equal_approx(fire_overlay.cooldown_ratio(), 0.0):
		return _fail("fireball overlay must clear with cooldown")
	if fire_overlay.visible:
		return _fail("fireball overlay must hide when ready")
	if fire_overlay.cooldown_text() != "":
		return _fail("cleared overlay must not show remaining text")
	return true


func _overlay_on(button: TextureButton) -> Control:
	var slot: Node = button.get_parent()
	if slot == null:
		return null
	for child in slot.get_children():
		if child.get_script() == OverlayScript:
			return child as Control
	return null


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
