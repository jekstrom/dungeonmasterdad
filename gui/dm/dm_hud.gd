extends CanvasLayer

const AbilityCatalog = preload("res://dm/dm_ability_catalog.gd")
const MANA_BAR_WIDTH: float = 120.0

@onready var spawn_gremlin_button: TextureButton = $MarginContainer/HBoxContainer/SpawnGremlin/TextureButton
@onready var cast_fireball_button: TextureButton = $MarginContainer/HBoxContainer/Fireball/TextureButton
@onready var spawn_knight_button: TextureButton = $MarginContainer/HBoxContainer/SpawnKnight/TextureButton
@onready var inventory_ui: Control = $MarginContainer/InventoryUi
@onready var fireball: ColorRect = $MarginContainer/HBoxContainer/Fireball
@onready var mana_fill: ColorRect = $MarginContainer/HBoxContainer/ManaMeter/BarColumn/Bar/ManaFill
@onready var mana_label: Label = $MarginContainer/HBoxContainer/ManaMeter/BarColumn/ManaLabel

func _ready() -> void:
	turn_off()
	spawn_gremlin_button.connect("button_down", _on_gremlin_button_pressed)
	spawn_knight_button.connect("button_down", _on_knight_button_pressed)
	cast_fireball_button.connect("button_down", _on_fireball_button_pressed)
	if not DmManager.mana_changed.is_connected(_on_mana_changed):
		DmManager.mana_changed.connect(_on_mana_changed)
	_update_mana_meter(DmManager.current_mana, DmManager.max_mana)

func _on_gremlin_button_pressed() -> void:
	DmManager.request_cast(AbilityCatalog.GREMLIN)

func _on_knight_button_pressed() -> void:
	DmManager.request_cast(AbilityCatalog.KNIGHTLING)
		
func _on_fireball_button_pressed() -> void:
	if not bool(DmUnlocks.dm_unlocks.get(AbilityCatalog.FIREBALL, false)):
		return
	SignalBus.start_spell_cast.emit(AbilityCatalog.FIREBALL)

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
	if not SignalBus.on_dm_unlock.is_connected(on_dm_unlock):
		SignalBus.on_dm_unlock.connect(on_dm_unlock)
	_update_mana_meter(DmManager.current_mana, DmManager.max_mana)
	
func turn_off() -> void:
	self.visible = false
	inventory_ui.hide()

func on_dm_unlock(unlock_name: String) -> void:
	if is_multiplayer_authority():
		print("unlocked ", unlock_name)
		if (unlock_name == "fireball"):
			fireball.visible = true
		
