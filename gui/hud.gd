extends CanvasLayer

@onready var fantasy_rect: ColorRect = $MarginContainer/HBoxContainer/FantasyBar
@onready var reality_bar: ColorRect = $MarginContainer/HBoxContainer/RealityBar
@onready var fantasy_label: Label = $MarginContainer/HBoxContainer/FantasyBar/Label
@onready var reality_label: Label = $MarginContainer/HBoxContainer/RealityBar/Label

func _ready() -> void:
	DmManager.fantasy_level_changed.connect(update_dm_bar)
	PlayerManager.reality_level_changed.connect(update_reality_bar)
	turn_off()

func update_dm_bar(fantasy_level: int) -> void:
	print("updating dm bar to ", fantasy_level)
	fantasy_rect.custom_minimum_size.x = 150 + fantasy_level
	fantasy_label.text = "FANTASY LEVEL " + str(fantasy_level)
	
func update_reality_bar(reality_level: int) -> void:
	reality_bar.custom_minimum_size.x = 150 + reality_level
	reality_label.text = "REALITY LEVEL " + str(reality_level)
	
func turn_off() -> void:
	if self.visible:
		print("turned off")
		self.visible = false
		
func turn_on() -> void:
	if !self.visible:
		print("turned on")
		self.visible = true
