extends CanvasLayer

const AbilityCatalog = preload("res://dm/dm_ability_catalog.gd")
const MANA_BAR_WIDTH: float = 120.0

@onready var spawn_gremlin_button: TextureButton = $MarginContainer/HBoxContainer/SpawnGremlin/TextureButton
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
@onready var skill_tree: Control = $SkillTree
@onready var minimap_widget: Control = $MinimapWidget

func _ready() -> void:
	turn_off()
	spawn_gremlin_button.connect("button_down", _on_gremlin_button_pressed)
	spawn_knight_button.connect("button_down", _on_knight_button_pressed)
	cast_fireball_button.connect("button_down", _on_fireball_button_pressed)
	cast_blizzard_button.connect("button_down", _on_blizzard_button_pressed)
	for btn in [spawn_gremlin_button, spawn_knight_button, cast_fireball_button, cast_blizzard_button]:
		if btn:
			btn.focus_mode = Control.FOCUS_NONE
	if not DmManager.mana_changed.is_connected(_on_mana_changed):
		DmManager.mana_changed.connect(_on_mana_changed)
	if not DmManager.respawn_countdown_changed.is_connected(_on_respawn_countdown_changed):
		DmManager.respawn_countdown_changed.connect(_on_respawn_countdown_changed)
	if not SignalBus.on_dm_unlock.is_connected(on_dm_unlock):
		SignalBus.on_dm_unlock.connect(on_dm_unlock)
	if not SignalBus.on_dm_lock.is_connected(on_dm_lock):
		SignalBus.on_dm_lock.connect(on_dm_lock)
	_update_mana_meter(DmManager.current_mana, DmManager.max_mana)
	_apply_unlock_visibility()
	_on_respawn_countdown_changed(-1.0)
	if minimap_widget and minimap_widget.has_method("configure"):
		minimap_widget.configure(1)  # ROLE_DM
	if minimap_widget:
		minimap_widget.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_gremlin_button_pressed() -> void:
	DmManager.request_cast(AbilityCatalog.GREMLIN)

func _on_knight_button_pressed() -> void:
	DmManager.request_cast(AbilityCatalog.KNIGHTLING)
		
func _on_fireball_button_pressed() -> void:
	if not bool(DmUnlocks.dm_unlocks.get(AbilityCatalog.FIREBALL, false)):
		return
	SignalBus.start_spell_cast.emit(AbilityCatalog.FIREBALL)

func _on_blizzard_button_pressed() -> void:
	if not bool(DmUnlocks.dm_unlocks.get(AbilityCatalog.BEMIDJI_BLIZZARD, false)):
		return
	SignalBus.start_spell_cast.emit(AbilityCatalog.BEMIDJI_BLIZZARD)

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

func _on_respawn_countdown_changed(remaining_sec: float) -> void:
	if respawn_overlay == null or respawn_label == null:
		return
	if remaining_sec < 0.0:
		respawn_overlay.visible = false
		return
	respawn_overlay.visible = true
	respawn_label.text = "RESPAWN IN %d" % ceili(remaining_sec)

func on_dm_unlock(_unlock_name: String) -> void:
	_apply_unlock_visibility()

func on_dm_lock(_unlock_name: String) -> void:
	_apply_unlock_visibility()

func _apply_unlock_visibility() -> void:
	if fireball:
		fireball.visible = bool(DmUnlocks.dm_unlocks.get(AbilityCatalog.FIREBALL, false))
	if spawn_knight:
		spawn_knight.visible = bool(DmUnlocks.dm_unlocks.get(AbilityCatalog.KNIGHTLING, false))
	if blizzard:
		blizzard.visible = bool(DmUnlocks.dm_unlocks.get(AbilityCatalog.BEMIDJI_BLIZZARD, false))

func _toggle_skill_tree_hud() -> void:
	skill_tree.visible = !skill_tree.visible
