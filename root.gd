extends Node

@onready var join_button: Button = $Control/VBoxContainer/HBoxContainer/join
@onready var start_button: Button = $Control/VBoxContainer/HBoxContainer/start
@onready var line_edit: LineEdit = $Control/VBoxContainer/LineEdit

var scene: PackedScene

func _ready():
	Hud.turn_off()
	start_button.pressed.connect(start_game)
	join_button.pressed.connect(join)
	
func start_game():
	print("start game")
	if multiplayer.is_server():
		PlayerData.player_name = line_edit.text
		Lobby.start_host(PlayerData.player_name)
		Hud.turn_on()
		if multiplayer.is_server():
			DmHud.turn_on()
		self.queue_free()
	
func join():
	print("join")
	PlayerData.player_name = line_edit.text
	Lobby.start_client()
	Hud.turn_on()
	if !multiplayer.is_server():
		PlayerHud.turn_on()
	self.queue_free()
