extends CanvasLayer

@onready var build_smoke_factory_button: TextureButton = $MarginContainer/HBoxContainer/ColorRect/TextureButton

func _ready() -> void:
	turn_off()
	build_smoke_factory_button.connect("button_down", on_build_smoke_factory_button_pressed)

func turn_on() -> void:
	self.visible = true
	
func turn_off() -> void:
	self.visible = false
	
func on_build_smoke_factory_button_pressed():
	SignalBus.build_smoke_building_pressed.emit()
