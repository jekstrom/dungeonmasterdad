extends Node

const Catalog = preload("res://dm/skill_tree_catalog.gd")

func _ready() -> void:
	if not await _run_suite():
		return
	print("US-054 skill tree spend test passed")
	get_tree().quit(0)


func _run_suite() -> bool:
	DmUnlocks.reset_unlocks()
	DmManager.fantasy_level = 0
	DmManager.skill_points = 0
	var rewarded_total: Array = [0]
	var on_reward := func(amount: int) -> void:
		rewarded_total[0] = int(rewarded_total[0]) + amount
	if not DmManager.skill_point_rewarded.is_connected(on_reward):
		DmManager.skill_point_rewarded.connect(on_reward)
	if DmManager.skill_points != 0:
		return _fail("US-054 AC1: SP must start 0")
	for node_id in Catalog.all_ids():
		if DmUnlocks.is_owned(node_id):
			return _fail("US-054 AC1: %s must start unowned" % node_id)

	var rl_before: int = int(PlayerManager.reality_level)
	PlayerManager.reality_level = rl_before + 5
	if DmManager.skill_points != 0:
		return _fail("US-054 AC2: Reality Level must not grant SP")
	PlayerManager.reality_level = rl_before

	DmManager.update_fantasy_level(9)
	if DmManager.fantasy_level != 9:
		return _fail("US-054: FL +9 must land at 9, got %d" % DmManager.fantasy_level)
	if DmManager.skill_points != 0:
		return _fail("US-054 AC2: FL 9 must grant 0 SP, got %d" % DmManager.skill_points)

	var reason: String = DmManager.request_purchase(Catalog.TREE_DM, "overcharged")
	if reason != Catalog.REASON_NOT_ENOUGH_SP:
		return _fail("US-054 AC4: Row1 col1 without SP want not_enough_sp got %s" % reason)

	DmManager.update_fantasy_level(1)
	if DmManager.fantasy_level != 10:
		return _fail("US-054: FL to 10 failed, got %d" % DmManager.fantasy_level)
	if DmManager.skill_points != 1:
		return _fail("US-054 AC2: FL 10 must grant 1 SP, got %d" % DmManager.skill_points)
	if int(rewarded_total[0]) != 1:
		return _fail("US-054: FL 10 must reward-toast 1 SP, got %d" % int(rewarded_total[0]))

	reason = DmManager.request_purchase(Catalog.TREE_DM, "overcharged")
	if reason != Catalog.REASON_OK:
		return _fail("US-054 AC4: Row1 col1 buy must succeed, got %s" % reason)
	if not DmUnlocks.is_owned("overcharged"):
		return _fail("US-054 AC4: overcharged must be owned")
	if DmManager.skill_points != 0:
		return _fail("US-054 AC4: 1 SP cost, remaining want 0 got %d" % DmManager.skill_points)
	if int(rewarded_total[0]) != 1:
		return _fail("US-054: spend must not emit skill_point_rewarded")

	reason = DmManager.request_purchase(Catalog.TREE_DM, "overcharged")
	if reason != Catalog.REASON_ALREADY_OWNED:
		return _fail("US-054 AC12: double-buy want already_owned got %s" % reason)
	if DmManager.skill_points != 0:
		return _fail("US-054 AC12: double-buy must not spend")

	DmManager.grant_skill_points(20)
	reason = DmManager.request_purchase(Catalog.TREE_DM, "minions")
	if reason != Catalog.REASON_OK:
		return _fail("US-054 AC8: Row2 at FL 10 must succeed got %s" % reason)

	reason = DmManager.request_purchase(Catalog.TREE_DM, "challenge_rating")
	if reason != Catalog.REASON_ROW_GATED:
		return _fail("US-054 AC9: Row3 before FL 50 want row_gated got %s" % reason)

	reason = DmManager.request_purchase(Catalog.TREE_DM, "spark")
	if reason != Catalog.REASON_OK:
		return _fail("US-054 AC5: col2 cost 2 must succeed got %s" % reason)

	reason = DmManager.request_purchase(Catalog.TREE_DM, "chain_lightning")
	if reason != Catalog.REASON_OK:
		return _fail("US-054 AC5: col3 cost 3 must succeed got %s" % reason)

	reason = DmManager.request_purchase(Catalog.TREE_DM, "challenge_rating")
	if reason != Catalog.REASON_ROW_GATED:
		return _fail("US-054 AC9: Row3 at FL 10 still gated got %s" % reason)

	reason = DmManager.request_purchase(Catalog.TREE_DM, "tsb")
	if reason != Catalog.REASON_ULTIMATE_PREREQ:
		return _fail("US-054 AC13: TSB without Row3 owned want ultimate_prereq got %s" % reason)

	var sp_before_jump: int = DmManager.skill_points
	DmManager.update_fantasy_level(40)
	if DmManager.fantasy_level != 50:
		return _fail("US-054: FL to 50 failed")
	if DmManager.skill_points != sp_before_jump + 4:
		return _fail("US-054 AC2: FL 10→50 must grant 4 SP, got %d want %d" % [DmManager.skill_points, sp_before_jump + 4])

	reason = DmManager.request_purchase(Catalog.TREE_DM, "challenge_rating")
	if reason != Catalog.REASON_OK:
		return _fail("US-054 AC10: Row3 at FL 50 must succeed got %s" % reason)

	reason = DmManager.request_purchase(Catalog.TREE_DM, "tsb")
	if reason != Catalog.REASON_OK:
		return _fail("US-054 AC14: TSB with all rows want ok got %s" % reason)
	if not DmUnlocks.is_owned("tsb"):
		return _fail("US-054 AC14: tsb must be owned")

	var sp_before_dad: int = DmManager.skill_points
	reason = DmManager.request_purchase(Catalog.TREE_DAD, "bemidji_cold")
	if reason != Catalog.REASON_OK:
		return _fail("US-054 AC17: Dad Row1 must succeed got %s" % reason)
	if DmManager.skill_points != sp_before_dad - 1:
		return _fail("US-054 AC3: shared pool must drop by 1, got %d" % DmManager.skill_points)
	if not DmUnlocks.is_owned("bemidji_cold"):
		return _fail("US-054 AC17: bemidji_cold must be owned")

	reason = DmManager.request_purchase(Catalog.TREE_DAD, "dad_all_powerful")
	if reason != Catalog.REASON_ULTIMATE_PREREQ:
		return _fail("US-054 AC13: Dad ult must ignore DM rows, got %s" % reason)

	reason = DmManager.request_purchase(Catalog.TREE_DAD, "stoke")
	if reason != Catalog.REASON_OK:
		return _fail("US-054 AC17: Dad Row2 must succeed got %s" % reason)
	reason = DmManager.request_purchase(Catalog.TREE_DAD, "thermostat_lock")
	if reason != Catalog.REASON_OK:
		return _fail("US-054 AC17: Dad Row3 must succeed got %s" % reason)
	reason = DmManager.request_purchase(Catalog.TREE_DAD, "dad_all_powerful")
	if reason != Catalog.REASON_OK:
		return _fail("US-054 AC17: Dad ult after three rows got %s" % reason)

	var sp_left: int = DmManager.skill_points
	DmManager.skill_points = 0
	reason = DmManager.request_purchase(Catalog.TREE_DM, "plus_one_swords")
	if reason != Catalog.REASON_NOT_ENOUGH_SP:
		return _fail("US-054 AC11: want not_enough_sp got %s" % reason)
	if DmUnlocks.is_owned("plus_one_swords"):
		return _fail("US-054 AC11: must not own plus_one_swords")
	DmManager.skill_points = sp_left

	if not DmUnlocks.is_owned("overcharged"):
		return _fail("US-054 AC19: effect query is_owned overcharged")
	DmUnlocks.dm_unlocks["plus_one_swords"] = true
	if not DmUnlocks.is_owned("plus_one_swords"):
		return _fail("US-054 AC19: force-own must work")

	if (DmManager.dm == null or not is_instance_valid(DmManager.dm)) and DmManager._is_dm_peer(2):
		return _fail("US-054 AC20: peer 2 must not count as DM when no DM body")

	var tree: Control = null
	if DmHud:
		tree = DmHud.skill_tree
	if tree:
		if tree.has_method("_refresh_spend_chrome"):
			tree.call("_refresh_spend_chrome")
		var sp_label: Label = tree.get("_sp_label")
		if sp_label and not str(sp_label.text).begins_with("SP"):
			return _fail("US-054 AC22: SP label missing")
		var over: Button = null
		var dm_btns: Array = tree.get("_dm_buttons")
		if dm_btns.size() > 0:
			over = dm_btns[0]
		if over:
			var badge: Label = over.get_node_or_null("CostBadge") as Label
			if badge == null or badge.text.find("1") == -1:
				return _fail("US-054 FR-019: cost badge missing on col1")
			if not bool(over.get_meta("owned_looking", false)):
				return _fail("US-054: purchased Overcharged should look owned")

	var snap: Dictionary = DmUnlocks.snapshot()
	var saved_sp: int = DmManager.skill_points
	var saved_fl: int = DmManager.fantasy_level
	var rewarded_before_snap: int = int(rewarded_total[0])
	DmUnlocks.reset_unlocks()
	DmManager.skill_points = 0
	DmManager.apply_skill_points(saved_sp)
	DmUnlocks.apply_replicated_unlocks(snap)
	if DmManager.skill_points != saved_sp:
		return _fail("US-054 AC18: late-join SP snapshot failed")
	if not DmUnlocks.is_owned("tsb") or not DmUnlocks.is_owned("dad_all_powerful"):
		return _fail("US-054 AC18: late-join owned snapshot failed")
	if saved_fl < 50:
		return _fail("US-054 AC18: FL snapshot for gates missing")
	if int(rewarded_total[0]) != rewarded_before_snap:
		return _fail("US-054: late-join SP apply must not emit skill_point_rewarded")
	if DmHud:
		var toast_label: Label = DmHud.get_node_or_null("%SkillPointToastLabel") as Label
		if toast_label == null:
			return _fail("US-054: Skill Point toast label missing")
		if toast_label.get_theme_font_size("font_size") != 42:
			return _fail("US-054: Skill Point toast must match respawn font size 42")
		if toast_label.text != "+1 Skill Point":
			return _fail("US-054: Skill Point toast text want '+1 Skill Point'")

	return true


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
