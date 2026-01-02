extends CanvasLayer

@onready var spawn_gremlin_button: TextureButton = $MarginContainer/HBoxContainer/ColorRect/TextureButton
@onready var inventory_ui: Control = $MarginContainer/InventoryUi

func _ready() -> void:
	turn_off()
	spawn_gremlin_button.connect("button_down", _on_gremlin_button_pressed)

func _on_gremlin_button_pressed() -> void:
	if multiplayer.is_server() and DmManager.fantasy_level >= 150:
		print("spawn gremlin")
		DmManager.update_fantasy_level(-150)
		DmManager.spawn_gremlin()

func turn_on() -> void:
	self.visible = true
	inventory_ui.show()
	
func turn_off() -> void:
	self.visible = false
	inventory_ui.hide()
