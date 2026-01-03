extends CanvasLayer

@onready var fantasy_rect: ColorRect = $MarginContainer/HBoxContainer/FantasyBar
@onready var reality_bar: ColorRect = $MarginContainer/HBoxContainer/RealityBar

func _ready() -> void:
	DmManager.fantasy_level_changed.connect(update_dm_bar)
	PlayerManager.reality_level_changed.connect(update_reality_bar)
	turn_off()

func update_dm_bar() -> void:
	if !multiplayer.is_server():
		print("updating fantasy level to " + str(DmManager.fantasy_level))
	fantasy_rect.size.x = DmManager.fantasy_level
	
func update_reality_bar() -> void:
	if !multiplayer.is_server():
		print("updating reality level to " + str(PlayerManager.reality_level))
	reality_bar.custom_minimum_size.x = PlayerManager.reality_level
	
func turn_off() -> void:
	if self.visible:
		print("turned off")
		self.visible = false
		
func turn_on() -> void:
	if !self.visible:
		print("turned on")
		self.visible = true
