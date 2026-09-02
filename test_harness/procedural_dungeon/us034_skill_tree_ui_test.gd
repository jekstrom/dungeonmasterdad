extends Node

## US-034 headless harness: open/close via DmHud toggle path, DM+Dad tabs,
## DM labels + TSB tooltips, Dad placeholders, locked/unlocked chrome,
## node clicks must not spend mana / unlock / spawn. Exact pass print required.


func _ready() -> void:
	if not await _run_suite():
		return
	print("US-034 skill tree UI test passed")
	get_tree().quit(0)


func _run_suite() -> bool:
	if DmHud == null:
		return _fail("US-034: DmHud autoload missing")
	var tree: Control = DmHud.skill_tree
	if tree == null:
		return _fail("US-034: DmHud.skill_tree missing")
	if not tree.has_method("get_dm_passive_names"):
		return _fail("US-034: skill_tree script missing (UI not replaced)")

	# Start closed
	if tree.visible:
		tree.visible = false
	await get_tree().process_frame

	# --- Open via live entry path (DmManager → DmHud toggle) ---
	DmHud.turn_on()
	await get_tree().process_frame
	DmManager._show_skill_tree_hud()
	await get_tree().process_frame
	if not tree.visible:
		return _fail("US-034: Skill Tree must open via DmManager._show_skill_tree_hud")

	# Tabs DM + Dad
	if not tree.has_method("current_tab_name"):
		return _fail("US-034: current_tab_name missing")
	if tree.current_tab_name() != "DM":
		return _fail("US-034: default tab must be DM")
	var tab: TabContainer = tree.get_node_or_null("Panel/Margin/VBox/TabContainer") as TabContainer
	if tab == null:
		return _fail("US-034: TabContainer missing")
	var tab_bar = tree.get_node_or_null("Panel/Margin/VBox/HeaderRow/TabBar")
	if tab_bar == null:
		return _fail("US-034: HeaderRow/TabBar missing (top tabs)")
	if tree.get_node_or_null("Panel/Margin/VBox/BodyRow/SideTabRail") != null:
		return _fail("US-034: SideTabRail must be removed")
	var tab_dm: TextureButton = tree.get("tab_dm_btn")
	var tab_dad: TextureButton = tree.get("tab_dad_btn")
	if tab_dm == null or tab_dad == null:
		return _fail("US-034: custom tab buttons missing")
	if tab_dm.custom_minimum_size != Vector2(96, 32) or tab_dad.custom_minimum_size != Vector2(96, 32):
		return _fail("US-034: top tabs must be 96x32 (got %s / %s)" % [tab_dm.custom_minimum_size, tab_dad.custom_minimum_size])
	if tab_dm.texture_normal == null or tab_dad.texture_normal == null:
		return _fail("US-034: tab textures missing")
	var header = tree.get_node_or_null("Panel/Margin/VBox/HeaderRow") as HBoxContainer
	if header == null or header.custom_minimum_size.y < 28:
		return _fail("US-034: HeaderRow missing or too short for title band")
	if tab.get_tab_count() != 2:
		return _fail("US-034: expected exactly 2 tabs, got %d" % tab.get_tab_count())
	if tab.get_tab_title(0) != "DM" or tab.get_tab_title(1) != "Dad":
		return _fail("US-034: tab titles must be DM and Dad")

	# DM labels + TSB in row order
	var expect_dm: Array[String] = [
		"Overcharged", "Spark", "Chain Lightning",
		"Minions", "Blind one-legged monkeys", "Crib Death",
		"Challenge Rating", "+1 Swords", "Random Encounter",
	]
	var got_dm: Array[String] = tree.get_dm_passive_names()
	if got_dm != expect_dm:
		return _fail("US-034: DM passive labels mismatch got %s" % str(got_dm))
	if tree.get_dm_ultimate_name() != "TSB":
		return _fail("US-034: ultimate must be TSB")

	var dm_btns: Array = tree.get("_dm_buttons")
	if dm_btns.size() != 9:
		return _fail("US-034: DM grid must have 9 passives")
	for i in range(9):
		var btn: Button = dm_btns[i]
		if btn == null or btn.text != expect_dm[i]:
			return _fail("US-034: DM button %d text want %s" % [i, expect_dm[i]])
		var tip: String = tree.tooltip_for_button(btn)
		var entry_name: String = expect_dm[i]
		var entry_effect: String = str(tree.DM_PASSIVES[i]["effect"])
		if tip.find(entry_name) == -1 or tip.find(entry_effect) == -1:
			return _fail("US-034: DM tooltip missing name/effect for %s (tip=%s)" % [entry_name, tip])

	var dm_ult: Button = tree.get("dm_ultimate")
	if dm_ult == null or dm_ult.text != "TSB":
		return _fail("US-034: DM ultimate button must read TSB")
	var ult_tip: String = tree.tooltip_for_button(dm_ult)
	if ult_tip.find("TSB") == -1 or ult_tip.find("Summon the TSB.") == -1:
		return _fail("US-034: TSB tooltip must include name + effect")

	# Native/cursor Control tooltips must be disabled; bottom TooltipPanel only.
	for btn in tree.get_all_node_buttons():
		if btn == null:
			continue
		if str(btn.tooltip_text) != "":
			return _fail("US-034: native tooltip_text must be empty on %s" % btn.name)
	var tip_label: Label = tree.get("tooltip_label")
	if tip_label == null:
		return _fail("US-034: TooltipLabel missing")
	var hover_btn: Button = dm_btns[0]
	hover_btn.emit_signal("mouse_entered")
	await get_tree().process_frame
	var panel_tip: String = tip_label.text
	if panel_tip.find("Overcharged") == -1 or panel_tip.find("Increase distance traveled by knightlings.") == -1:
		return _fail("US-034: bottom TooltipPanel must update on hover (got %s)" % panel_tip)

	# Open state: no mock gold — every passive + ult starts locked-grey / unselected.
	for i in range(dm_btns.size()):
		var b: Button = dm_btns[i]
		if tree.is_button_unlocked_looking(b):
			return _fail("US-034: DM passive %s should start locked-grey" % b.name)
		if bool(b.get_meta("owned_looking", false)):
			return _fail("US-034: DM passive %s should start unselected" % b.name)
	if tree.is_button_unlocked_looking(dm_ult):
		return _fail("US-034: ultimate should start locked-grey")
	if bool(dm_ult.get_meta("owned_looking", false)):
		return _fail("US-034: ultimate should start unselected")
	var ult_sb = dm_ult.get_theme_stylebox("normal")
	if ult_sb is StyleBoxTexture:
		var ult_tex: Texture2D = (ult_sb as StyleBoxTexture).texture
		if ult_tex and str(ult_tex.resource_path).find("tsb_bar_fill") != -1:
			return _fail("US-034: TSB must not use tsb_bar_fill until selected")
	var sample: Button = dm_btns[0]
	var sample_sb = sample.get_theme_stylebox("normal")
	if sample_sb:
		if sample_sb.content_margin_left < 7.0:
			return _fail("US-034: skill icons need left inset (content_margin_left>=8)")

	# Dad tab placeholders
	tree.select_tab("Dad")
	await get_tree().process_frame
	if tree.current_tab_name() != "Dad":
		return _fail("US-034: select_tab Dad failed")
	var expect_dad: Array[String] = tree.get_dad_passive_names()
	if expect_dad.size() != 9:
		return _fail("US-034: Dad must have 9 placeholder passives")
	var dad_btns: Array = tree.get("_dad_buttons")
	if dad_btns.size() != 9:
		return _fail("US-034: Dad grid must have 9 buttons")
	for i in range(9):
		var db: Button = dad_btns[i]
		var want := "Dad Passive %d" % (i + 1)
		if db == null or db.text != want:
			return _fail("US-034: Dad button %d want %s" % [i, want])
		var dtip: String = tree.tooltip_for_button(db)
		if dtip.find(want) == -1 or dtip.find("Placeholder effect") == -1:
			return _fail("US-034: Dad tooltip placeholder missing for %s" % want)
	var dad_ult: Button = tree.get("dad_ultimate")
	if dad_ult == null or dad_ult.text != "Dad Ultimate":
		return _fail("US-034: Dad ultimate placeholder missing")
	var dad_ult_tip: String = tree.tooltip_for_button(dad_ult)
	if dad_ult_tip.find("Dad Ultimate") == -1 or dad_ult_tip.find("Placeholder effect") == -1:
		return _fail("US-034: Dad ultimate tooltip missing")

	# Node clicks: no mana spend, no unlock map mutation, no spawn side effects
	var mana_before: int = DmManager.current_mana
	var unlocks_before: Dictionary = DmUnlocks.dm_unlocks.duplicate(true)
	var gremlin_before: int = get_tree().get_nodes_in_group("gremlins").size()
	var knight_before: int = get_tree().get_nodes_in_group("knightlings").size()
	var goblin_before: int = get_tree().get_nodes_in_group("goblins").size()
	var monsters_before: int = get_tree().get_nodes_in_group("monsters").size()

	tree.select_tab("DM")
	await get_tree().process_frame
	for btn in tree.get_all_node_buttons():
		if btn is BaseButton:
			btn.emit_signal("pressed")
	await get_tree().process_frame

	# Selection chrome only after click (UI-only).
	var last: Button = tree.get("_selected_btn")
	if last == null or not bool(last.get_meta("owned_looking", false)):
		return _fail("US-034: clicked node should show selection chrome")
	# Prior passives stay unselected/grey (not mock-unlocked).
	for i in range(dm_btns.size()):
		var b2: Button = dm_btns[i]
		if b2 == last:
			continue
		if bool(b2.get_meta("owned_looking", false)):
			return _fail("US-034: non-selected %s should not keep owned chrome" % b2.name)

	if DmManager.current_mana != mana_before:
		return _fail("US-034: node click must not change mana")
	if DmUnlocks.dm_unlocks != unlocks_before:
		return _fail("US-034: node click must not mutate dm_unlocks")
	if get_tree().get_nodes_in_group("gremlins").size() != gremlin_before:
		return _fail("US-034: node click must not spawn gremlins")
	if get_tree().get_nodes_in_group("knightlings").size() != knight_before:
		return _fail("US-034: node click must not spawn knightlings")
	if get_tree().get_nodes_in_group("goblins").size() != goblin_before:
		return _fail("US-034: node click must not spawn goblins")
	if get_tree().get_nodes_in_group("monsters").size() != monsters_before:
		return _fail("US-034: node click must not spawn monsters/TSB")

	# Close via toggle path
	DmManager._show_skill_tree_hud()
	await get_tree().process_frame
	if tree.visible:
		return _fail("US-034: toggle must close Skill Tree")

	# Re-open and Esc close
	DmManager._show_skill_tree_hud()
	await get_tree().process_frame
	if not tree.visible:
		return _fail("US-034: reopen failed before Esc")
	var esc := InputEventAction.new()
	esc.action = "ui_cancel"
	esc.pressed = true
	tree._unhandled_input(esc)
	await get_tree().process_frame
	if tree.visible:
		return _fail("US-034: Esc must close Skill Tree")

	# PP HUD must not host this panel (DmHud-only)
	var pp_hud := get_node_or_null("/root/PlayerHud")
	if pp_hud != null and pp_hud.get_node_or_null("SkillTree") != null:
		return _fail("US-034: PlayerHud must not host SkillTree panel")

	# HUD still works after close
	if not DmHud.visible:
		return _fail("US-034: DmHud must remain active after Skill Tree close")

	return true


func _fail(msg: String) -> bool:
	push_error(msg)
	print(msg)
	get_tree().quit(1)
	return false
