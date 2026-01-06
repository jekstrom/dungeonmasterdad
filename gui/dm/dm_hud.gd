extends CanvasLayer

@onready var spawn_gremlin_button: TextureButton = $MarginContainer/HBoxContainer/SpawnGremlin/TextureButton
@onready var cast_fireball_button: TextureButton = $MarginContainer/HBoxContainer/Fireball/TextureButton
@onready var inventory_ui: Control = $MarginContainer/InventoryUi
@onready var fireball: ColorRect = $MarginContainer/HBoxContainer/Fireball

func _ready() -> void:
	turn_off()
	spawn_gremlin_button.connect("button_down", _on_gremlin_button_pressed)
	cast_fireball_button.connect("button_down", _on_fireball_button_pressed)

func _on_gremlin_button_pressed() -> void:
	if multiplayer.is_server() and DmManager.fantasy_level >= 150:
		print("spawn gremlin")
		DmManager.update_fantasy_level(-150)
		DmManager.spawn_gremlin()
		
func _on_fireball_button_pressed() -> void:
	if multiplayer.is_server() and DmUnlocks.dm_unlocks["fireball"]:
		print("casting fireball")
		DmManager.update_fantasy_level(15)
		SignalBus.start_spell_cast.emit("fireball")

func turn_on() -> void:
	self.visible = true
	inventory_ui.show()
	SignalBus.on_dm_unlock.connect(on_dm_unlock)
	
func turn_off() -> void:
	self.visible = false
	inventory_ui.hide()

func on_dm_unlock(unlock_name: String) -> void:
	if is_multiplayer_authority():
		print("unlocked ", unlock_name)
		fireball.visible = true
		
