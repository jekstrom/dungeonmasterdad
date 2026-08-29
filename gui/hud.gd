# Hud
extends CanvasLayer

const HEALTH_BAR_WIDTH: float = 150.0

@onready var fantasy_rect: ColorRect = $MarginContainer/HBoxContainer/FantasyColumn/FantasyBar
@onready var reality_bar: ColorRect = $MarginContainer/HBoxContainer/RealityBar
@onready var fantasy_label: Label = $MarginContainer/HBoxContainer/FantasyColumn/FantasyBar/Label
@onready var reality_label: Label = $MarginContainer/HBoxContainer/RealityBar/Label
@onready var mode_container: MarginContainer = $ModeContainer
@onready var mode_display: Label = $ModeContainer/CenterContainer/ModeDisplay
@onready var dm_health_bar: ColorRect = $MarginContainer/HBoxContainer/FantasyColumn/DmHealthBar
@onready var dm_health_fill: ColorRect = $MarginContainer/HBoxContainer/FantasyColumn/DmHealthBar/DmHealthFill
@onready var dm_health_label: Label = $MarginContainer/HBoxContainer/FantasyColumn/DmHealthBar/DmHealthLabel

func _ready() -> void:
	DmManager.fantasy_level_changed.connect(update_dm_bar)
	PlayerManager.reality_level_changed.connect(update_reality_bar)
	if not DmManager.health_changed.is_connected(update_dm_health):
		DmManager.health_changed.connect(update_dm_health)
	SignalBus.on_dm_unlock.connect(_on_dm_unlock)
	SignalBus.on_dm_lock.connect(_on_dm_lock)
	turn_off()
	# Top bar Spacer is a full-width Control; do not swallow world LMB.
	var spacer: Control = get_node_or_null("MarginContainer/HBoxContainer/Spacer") as Control
	if spacer:
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar: Control = get_node_or_null("MarginContainer") as Control
	if bar:
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
func _on_dm_unlock(unlock: String) -> void:
	if unlock == "shadow_zone":
		mode_container.visible = true
		mode_display.text = "SHADOW ZONE"
		
func _on_dm_lock(lock: String) -> void:
	if lock == "shadow_zone":
		mode_container.visible = false
		mode_display.text = ""
		
func update_dm_bar(fantasy_level: int) -> void:
	var bar_w: float = HEALTH_BAR_WIDTH + float(fantasy_level)
	fantasy_rect.custom_minimum_size.x = bar_w
	fantasy_label.text = "FANTASY LEVEL " + str(fantasy_level)
	if dm_health_bar:
		dm_health_bar.custom_minimum_size.x = bar_w
	_refresh_health_fill_width()

func update_dm_health(hp: int, max_hp: int) -> void:
	if dm_health_label:
		dm_health_label.text = "HEALTH %d/%d" % [hp, max_hp]
	_refresh_health_fill_width(hp, max_hp)

func _refresh_health_fill_width(hp: int = -1, max_hp: int = -1) -> void:
	if dm_health_fill == null or dm_health_bar == null:
		return
	if max_hp < 1:
		max_hp = 100
		if DmManager.dm:
			max_hp = maxi(1, int(DmManager.dm.max_hp))
	if hp < 0:
		hp = max_hp
		if DmManager.dm:
			hp = clampi(int(DmManager.dm.hitpoints), 0, max_hp)
	else:
		hp = clampi(hp, 0, max_hp)
	var bar_w: float = dm_health_bar.custom_minimum_size.x
	if bar_w <= 0.0:
		bar_w = HEALTH_BAR_WIDTH
	var ratio: float = clampf(float(hp) / float(max_hp), 0.0, 1.0)
	dm_health_fill.offset_left = 0.0
	dm_health_fill.offset_top = 0.0
	dm_health_fill.offset_bottom = 16.0
	dm_health_fill.offset_right = bar_w * ratio
	
func update_reality_bar(reality_level: int) -> void:
	reality_bar.custom_minimum_size.x = 150 + reality_level
	reality_label.text = "REALITY LEVEL " + str(reality_level)
	
func turn_off() -> void:
	if self.visible:
		print("turned off")
		self.visible = false
	_set_dm_health_visible(false)
		
func turn_on() -> void:
	if !self.visible:
		print("turned on")
		self.visible = true
	_set_dm_health_visible(_local_is_dm())
	if DmManager.dm:
		update_dm_health(int(DmManager.dm.hitpoints), int(DmManager.dm.max_hp))
	else:
		update_dm_health(100, 100)

func _local_is_dm() -> bool:
	return multiplayer.has_multiplayer_peer() and multiplayer.is_server()

func _set_dm_health_visible(should_show: bool) -> void:
	if dm_health_bar:
		dm_health_bar.visible = should_show
