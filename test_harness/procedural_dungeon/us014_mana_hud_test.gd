extends Node

func _ready() -> void:
	DmManager.set_mana(0)
	DmHud.turn_on()
	var label: Label = DmHud.get_node_or_null("%ManaLabel") as Label
	var fill: ColorRect = DmHud.get_node_or_null("%ManaFill") as ColorRect
	var pip: TextureRect = DmHud.get_node_or_null("%ManaPip") as TextureRect
	if label == null or fill == null or pip == null:
		_fail("US-014 T007: DM HUD must have mana label, fill, and dew pip")
		return
	if label.text != "0/100":
		_fail("US-014 T007: visible HUD at 0 mana must show 0/100, got %s" % label.text)
		return
	if fill.offset_right > 0.01:
		_fail("US-014 T007: empty mana bar must have no fill width")
		return
	if pip.texture == null or pip.texture.resource_path != "res://pickups/mtdew/mtdew.png":
		_fail("US-014 T007: pip must reuse pickups/mtdew/mtdew.png")
		return

	DmManager.set_mana(25)
	if label.text != "25/100":
		_fail("US-014 T007: meter must follow mana_changed, got %s" % label.text)
		return
	if abs(fill.offset_right - 30.0) > 0.01:
		_fail("US-014 T007: 25/100 fill width must be 30, got %s" % fill.offset_right)
		return

	DmHud._on_gremlin_button_pressed()
	if label.text != "5/100":
		_fail("US-014 T007: after gremlin spend meter must show 5/100, got %s" % label.text)
		return

	if PlayerHud.get_node_or_null("%ManaLabel") != null:
		_fail("US-014 T007: Paper Pusher HUD must not show the DM mana meter")
		return
	if PlayerHud.has_method("set_mana") or PlayerHud.has_method("add_mana"):
		_fail("US-014 T007: Paper Pusher HUD must not author DM mana")
		return

	var fantasy_label: Label = Hud.get_node_or_null("MarginContainer/HBoxContainer/FantasyBar/Label") as Label
	if fantasy_label == null or fantasy_label.text.find("FANTASY") < 0:
		_fail("US-014 T007: Fantasy Level bar must remain on the shared HUD")
		return

	DmManager.set_mana(0)
	print("US-014 T007 mana HUD test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
