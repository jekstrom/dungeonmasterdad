extends Node

const TAX := "res://pickups/tax_form.tres"
const FILLED := "res://pickups/filled_form.tres"

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.max_inv_slots = 8
	PlayerManager.reality_level = 0
	PlayerManager.tax_file_rl = 10
	PlayerManager.register_player(1, "Paper Pusher")
	var tax: ItemData = load(TAX) as ItemData
	PlayerManager.add_item_to_inventory(1, tax, 1)

	var player: Player = Player.new()
	player.name = "1"
	add_child(player)
	player.set_process(false)
	player.set_physics_process(false)
	await get_tree().process_frame

	if player._host_try_file_tax():
		_fail("US-009 T006: file must fail with no IRS")
		return
	if PlayerManager.get_item_count(1, TAX) != 1:
		_fail("US-009 T006: no IRS must leave the tax form")
		return
	if PlayerManager.reality_level != 0:
		_fail("US-009 T006: no IRS must not raise Reality")
		return

	var irs: IrsBuilding = load("res://buildings/buildables/irs.tscn").instantiate() as IrsBuilding
	irs.position = Vector2(80, 0)
	irs.is_ghost = false
	add_child(irs)
	irs.enable()
	await get_tree().process_frame
	FactoryStatusHud._process(0.0)
	if not FactoryStatusHud.tax_visible(irs):
		_fail("US-009 T006: idle IRS must throb a tax-form input icon")
		return
	player.position = Vector2(400, 0)
	if irs.try_file_tax(1):
		_fail("US-009 T006: out of range must fail")
		return
	player.position = irs.position + Vector2(90, 0)
	if irs.in_file_range(player):
		_fail("US-009 T006: IRS file range must not reach a nearby factory cell")
		return

	player.position = irs.position
	if PlayerManager.tax_file_rl <= PlayerManager.standard_form_rl:
		_fail("US-009 T006: tax RL must beat a standard form")
		return
	if not irs.can_prompt_file(player):
		_fail("US-009 T006: in-range tax form must prompt F")
		return
	if not player.can_prompt_building_interact():
		_fail("US-009 T006: player must show F when filing is possible")
		return
	player.try_interact()
	if PlayerManager.get_item_count(1, TAX) != 0:
		_fail("US-009 T006: interact must consume the tax form")
		return
	if PlayerManager.reality_level != 10:
		_fail("US-009 T006: filing must grant +10 Reality, got %d" % PlayerManager.reality_level)
		return

	PlayerManager.add_item_to_inventory(1, tax, 1)
	var tax_slot := -1
	var slots: Array = PlayerManager.get_slots(1)
	for i in 4:
		if str(slots[i].get("path", "")) == TAX:
			tax_slot = i
			break
	if tax_slot < 0:
		_fail("US-009 T006: tax form must land in an active slot")
		return
	if not player.use_active_slot(tax_slot):
		_fail("US-009 T006: using the tax slot at the IRS must file")
		return
	if PlayerManager.get_item_count(1, TAX) != 0:
		_fail("US-009 T006: tax slot use must consume the tax form")
		return
	if PlayerManager.reality_level != 20:
		_fail("US-009 T006: second file must grant another +10, got %d" % PlayerManager.reality_level)
		return

	var filled: ItemData = load(FILLED) as ItemData
	PlayerManager.add_item_to_inventory(1, filled, 1)
	var rl: int = PlayerManager.reality_level
	if irs.try_file_tax(1):
		_fail("US-009 T006: standard form must not file")
		return
	if PlayerManager.reality_level != rl:
		_fail("US-009 T006: standard form must not raise Reality at IRS")
		return

	irs.is_ghost = true
	FactoryStatusHud._process(0.0)
	if FactoryStatusHud.tax_visible(irs):
		_fail("US-009 T006: ghost IRS must not show the tax input icon")
		return
	PlayerManager.add_item_to_inventory(1, tax, 1)
	if irs.try_file_tax(1):
		_fail("US-009 T006: ghost IRS must not file")
		return
	player.try_interact()
	if PlayerManager.get_item_count(1, TAX) != 1:
		_fail("US-009 T006: interact at ghost IRS must leave the tax form")
		return

	var root := Node2D.new()
	root.add_to_group("building_root")
	add_child(root)
	irs.get_parent().remove_child(irs)
	root.add_child(irs)
	irs.is_ghost = true
	player.position = irs.position
	if not irs.try_file_tax(1, player):
		_fail("US-009 T006: world IRS must file even if is_ghost stuck true")
		return
	if PlayerManager.get_item_count(1, TAX) != 0:
		_fail("US-009 T006: world IRS file must consume the tax form")
		return

	print("US-009 T006 file tax test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
