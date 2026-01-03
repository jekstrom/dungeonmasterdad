extends Node

@onready var join_button: Button = $Control/VBoxContainer/HBoxContainer/join
@onready var start_button: Button = $Control/VBoxContainer/HBoxContainer/start
@onready var line_edit: LineEdit = $Control/VBoxContainer/LineEdit

var scene: PackedScene

func _ready():
	Hud.turn_off()
	start_button.pressed.connect(start_game)
	join_button.pressed.connect(join)
	line_edit.text_changed.connect(on_name_changed)
	
func on_name_changed(new_text: String) -> void:
	SignalBus.on_name_changed.emit(new_text)

func start_game():
	print("start game")
	if multiplayer.is_server():
		Lobby.start_host()
		Hud.turn_on()
		if multiplayer.is_server():
			DmHud.turn_on()
		self.queue_free()
	
func join():
	print("join")
	Lobby.start_client()
	Hud.turn_on()
	if !multiplayer.is_server():
		PlayerHud.turn_on()
	self.queue_free()
