extends CanvasLayer

const AbilityCatalog = preload("res://dm/dm_ability_catalog.gd")
const AbilityCooldownOverlay = preload("res://gui/dm/ability_cooldown_overlay.gd")
const MANA_BAR_WIDTH: float = 120.0

@onready var spawn_gremlin_button: TextureButton = $MarginContainer/HBoxContainer/SpawnGremlin/TextureButton
@onready var spawn_goblin_button: TextureButton = $MarginContainer/HBoxContainer/SpawnGoblin/TextureButton
@onready var spawn_goblin: ColorRect = $MarginContainer/HBoxContainer/SpawnGoblin
@onready var cast_fireball_button: TextureButton = $MarginContainer/HBoxContainer/Fireball/TextureButton
@onready var spawn_knight_button: TextureButton = $MarginContainer/HBoxContainer/SpawnKnight/TextureButton
@onready var spawn_knight: ColorRect = $MarginContainer/HBoxContainer/SpawnKnight
@onready var cast_blizzard_button: TextureButton = $MarginContainer/HBoxContainer/Blizzard/TextureButton
@onready var blizzard: ColorRect = $MarginContainer/HBoxContainer/Blizzard
@onready var inventory_ui: Control = $MarginContainer/InventoryUi
@onready var fireball: ColorRect = $MarginContainer/HBoxContainer/Fireball
@onready var mana_fill: ColorRect = $MarginContainer/HBoxContainer/ManaMeter/BarColumn/Bar/ManaFill
@onready var mana_label: Label = $MarginContainer/HBoxContainer/ManaMeter/BarColumn/ManaLabel
@onready var respawn_overlay: Control = $RespawnOverlay
@onready var respawn_label: Label = $RespawnOverlay/DmRespawnCountdown
@onready var skill_point_toast: Control = $SkillPointToast
@onready var skill_point_toast_label: Label = $SkillPointToast/SkillPointToastLabel
@onready var skill_tree: Control = $SkillTree
@onready var minimap_widget: Control = $MinimapWidget

var _skill_point_toast_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	turn_off()
	spawn_gremlin_button.connect("button_down", _on_gremlin_button_pressed)
	if spawn_goblin_button:
		spawn_goblin_button.connect("button_down", _on_goblin_button_pressed)
	spawn_knight_button.connect("button_down", _on_knight_button_pressed)
	cast_fireball_button.connect("button_down", _on_fireball_button_pressed)
	cast_blizzard_button.connect("button_down", _on_blizzard_button_pressed)
	for btn in [spawn_gremlin_button, spawn_goblin_button, spawn_knight_button, cast_fireball_button, cast_blizzard_button]:
		if btn:
			btn.focus_mode = Control.FOCUS_NONE
	if not DmManager.mana_changed.is_connected(_on_mana_changed):
		DmManager.mana_changed.connect(_on_mana_changed)
	if not DmManager.respawn_countdown_changed.is_connected(_on_respawn_countdown_changed):
		DmManager.respawn_countdown_changed.connect(_on_respawn_countdown_changed)
	if not DmManager.skill_point_rewarded.is_connected(_on_skill_point_rewarded):
		DmManager.skill_point_rewarded.connect(_on_skill_point_rewarded)
	if not SignalBus.on_dm_unlock.is_connected(on_dm_unlock):
		SignalBus.on_dm_unlock.connect(on_dm_unlock)
	if not SignalBus.on_dm_lock.is_connected(on_dm_lock):
		SignalBus.on_dm_lock.connect(on_dm_lock)
	_update_mana_meter(DmManager.current_mana, DmManager.max_mana)
	_apply_unlock_visibility()
	_on_respawn_countdown_changed(-1.0)
	if minimap_widget and minimap_widget.has_method("configure"):
		minimap_widget.configure(true)
	if minimap_widget:
		minimap_widget.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_attach_cooldown_overlays()
	_ensure_debug_skill_action()

func _on_gremlin_button_pressed() -> void:
	if not _hud_ability_ready(AbilityCatalog.GREMLIN):
		return
	DmManager.request_cast(AbilityCatalog.GREMLIN)

func _on_goblin_button_pressed() -> void:
	if not _hud_ability_ready(AbilityCatalog.GOBLIN):
		return
	DmManager.request_cast(AbilityCatalog.GOBLIN)

func _on_knight_button_pressed() -> void:
	if not _hud_ability_ready(AbilityCatalog.KNIGHTLING):
		return
	DmManager.request_cast(AbilityCatalog.KNIGHTLING)
		
func _on_fireball_button_pressed() -> void:
	if not _hud_ability_ready(AbilityCatalog.FIREBALL):
		return
	SignalBus.start_spell_cast.emit(AbilityCatalog.FIREBALL)

func _on_blizzard_button_pressed() -> void:
	if not _hud_ability_ready(AbilityCatalog.BEMIDJI_BLIZZARD):
		return
	SignalBus.start_spell_cast.emit(AbilityCatalog.BEMIDJI_BLIZZARD)

func _hud_ability_ready(ability_id: String) -> bool:
	var required_unlock: String = AbilityCatalog.unlock_id(ability_id)
	if not required_unlock.is_empty() and not bool(DmUnlocks.dm_unlocks.get(required_unlock, false)):
		return false
	if DmManager.ability_cooldown_remaining(ability_id) > 0.0:
		return false
	return true

func _attach_cooldown_overlays() -> void:
	_bind_cooldown_overlay(spawn_gremlin_button, AbilityCatalog.GREMLIN)
	_bind_cooldown_overlay(spawn_goblin_button, AbilityCatalog.GOBLIN)
	_bind_cooldown_overlay(spawn_knight_button, AbilityCatalog.KNIGHTLING)
	_bind_cooldown_overlay(cast_fireball_button, AbilityCatalog.FIREBALL)
	_bind_cooldown_overlay(cast_blizzard_button, AbilityCatalog.BEMIDJI_BLIZZARD)

func _bind_cooldown_overlay(button: TextureButton, ability_id: String) -> void:
	if button == null:
		return
	var slot: Control = button.get_parent() as Control
	if slot == null:
		return
	for child in slot.get_children():
		if child.get_script() == AbilityCooldownOverlay:
			child.ability_id = ability_id
			return
	var overlay = AbilityCooldownOverlay.new()
	overlay.ability_id = ability_id
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(overlay)

func _on_mana_changed(new_current: int, new_max: int) -> void:
	_update_mana_meter(new_current, new_max)

func _update_mana_meter(current: int, max_mana: int) -> void:
	if mana_label:
		mana_label.text = "%d/%d" % [current, max_mana]
	if mana_fill == null:
		return
	var ratio: float = 0.0
	if max_mana > 0:
		ratio = clampf(float(current) / float(max_mana), 0.0, 1.0)
	mana_fill.offset_left = 0.0
	mana_fill.offset_top = 0.0
	mana_fill.offset_bottom = 16.0
	mana_fill.offset_right = MANA_BAR_WIDTH * ratio

func turn_on() -> void:
	self.visible = true
	inventory_ui.show()
	_update_mana_meter(DmManager.current_mana, DmManager.max_mana)
	_apply_unlock_visibility()
	
func turn_off() -> void:
	self.visible = false
	inventory_ui.hide()
	_on_respawn_countdown_changed(-1.0)
	_hide_skill_point_toast()

func _on_respawn_countdown_changed(remaining_sec: float) -> void:
	if respawn_overlay == null or respawn_label == null:
		return
	if remaining_sec < 0.0:
		respawn_overlay.visible = false
		return
	respawn_overlay.visible = true
	respawn_label.text = "RESPAWN IN %d" % ceili(remaining_sec)

func _on_skill_point_rewarded(amount: int) -> void:
	if amount <= 0:
		return
	if not visible:
		return
	if skill_point_toast == null or skill_point_toast_label == null:
		return
	skill_point_toast_label.text = "+1 Skill Point"
	skill_point_toast.visible = true
	skill_point_toast.modulate = Color(1, 1, 1, 1)
	if _skill_point_toast_tween != null and _skill_point_toast_tween.is_valid():
		_skill_point_toast_tween.kill()
	_skill_point_toast_tween = create_tween()
	_skill_point_toast_tween.tween_interval(0.8)
	_skill_point_toast_tween.tween_property(skill_point_toast, "modulate:a", 0.0, 1.2)
	_skill_point_toast_tween.finished.connect(_hide_skill_point_toast)

func _hide_skill_point_toast() -> void:
	if _skill_point_toast_tween != null and _skill_point_toast_tween.is_valid():
		_skill_point_toast_tween.kill()
	_skill_point_toast_tween = null
	if skill_point_toast:
		skill_point_toast.visible = false
		skill_point_toast.modulate = Color(1, 1, 1, 0)

func on_dm_unlock(_unlock_name: String) -> void:
	_apply_unlock_visibility()

func on_dm_lock(_unlock_name: String) -> void:
	_apply_unlock_visibility()

func _apply_unlock_visibility() -> void:
	if fireball:
		fireball.visible = bool(DmUnlocks.dm_unlocks.get(AbilityCatalog.FIREBALL, false))
	if spawn_knight:
		spawn_knight.visible = bool(DmUnlocks.dm_unlocks.get(AbilityCatalog.KNIGHTLING, false))
	if spawn_goblin:
		spawn_goblin.visible = bool(DmUnlocks.dm_unlocks.get(AbilityCatalog.UNLOCK_GOBLIN, false))
	if blizzard:
		blizzard.visible = bool(DmUnlocks.dm_unlocks.get(AbilityCatalog.BEMIDJI_BLIZZARD, false))

func _toggle_skill_tree_hud() -> void:
	if skill_tree == null:
		return
	if skill_tree.has_method("toggle_panel"):
		skill_tree.toggle_panel()
	else:
		skill_tree.visible = not skill_tree.visible


func open_skill_tree_hud() -> void:
	if not visible:
		turn_on()
	if skill_tree == null:
		return
	if skill_tree.has_method("open_panel"):
		skill_tree.open_panel()
	else:
		skill_tree.visible = true


func _ensure_debug_skill_action() -> void:
	const ACTION := "debug_skill_cheat"
	if not InputMap.has_action(ACTION):
		InputMap.add_action(ACTION)
	var has_f9 := false
	var has_shift_f9 := false
	for ev in InputMap.action_get_events(ACTION):
		if not (ev is InputEventKey):
			continue
		var key: InputEventKey = ev
		var is_f9: bool = key.keycode == KEY_F9 or key.physical_keycode == KEY_F9
		if not is_f9:
			continue
		if key.shift_pressed:
			has_shift_f9 = true
		else:
			has_f9 = true
	if not has_f9:
		var bind := InputEventKey.new()
		bind.keycode = KEY_F9
		bind.physical_keycode = KEY_F9
		InputMap.action_add_event(ACTION, bind)
	if not has_shift_f9:
		var shift_bind := InputEventKey.new()
		shift_bind.keycode = KEY_F9
		shift_bind.physical_keycode = KEY_F9
		shift_bind.shift_pressed = true
		InputMap.action_add_event(ACTION, shift_bind)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).echo:
		return
	if event.is_action_pressed("debug_skill_cheat"):
		var tree := get_tree()
		if tree:
			tree.paused = false
		DmManager.debug_open_skills_and_grant_sp(100)
		get_viewport().set_input_as_handled()
		return
	if not visible:
		return
	if not event.is_action_pressed("toggle_minimap_debug_reveal"):
		return
	if minimap_widget and minimap_widget.has_method("toggle_debug_reveal"):
		minimap_widget.toggle_debug_reveal()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("toggle_minimap"):
		if minimap_widget and minimap_widget.has_method("toggle_map"):
			minimap_widget.toggle_map()
			get_viewport().set_input_as_handled()
