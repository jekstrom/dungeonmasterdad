extends CanvasLayer

@onready var color_rect: ColorRect = $MarginContainer/HBoxContainer/FantasyBar

func _ready() -> void:
	DmManager.fantasy_level_changed.connect(update_dm_bar)
	turn_off()

func update_dm_bar() -> void:
	if !multiplayer.is_server():
		print("updating fantasy level to " + str(DmManager.fantasy_level))
	color_rect.size.x = DmManager.fantasy_level

func turn_off() -> void:
	if self.visible:
		print("turned off")
		self.visible = false
		
func turn_on() -> void:
	if !self.visible:
		print("turned on")
		self.visible = true
