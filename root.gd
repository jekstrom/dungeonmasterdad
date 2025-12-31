extends Node

@onready var join_button: Button = $VBoxContainer/HBoxContainer/join
@onready var start_button: Button = $VBoxContainer/HBoxContainer/start

func _ready():
	# Preconfigure game.
	#Lobby.player_info = {"name": "poop"}
	
	#Lobby.player_loaded.rpc_id(1) # Tell the server that this peer has loaded.
	start_button.pressed.connect(start_game)
	#create_button.pressed.connect(create)
	join_button.pressed.connect(join)
	#line_edit.text_changed.connect(_name_changed)
	#Lobby.player_connected.connect(joined)

func joined(peer_id, player_info):
	print("player joined")
	print("player " + str(peer_id) + " info: " + str(player_info))

# Called only on the server.
func start_game():
	# All peers are ready to receive RPCs in this scene.
	print("start")
	if multiplayer.is_server():
		Lobby.start_host()
		# Lobby.load_game.rpc("res://playground.tscn")
	
func join():
	print("join")
	Lobby.start_client()
	#Lobby.join_game("localhost")
	
#func create():
	#print("create")
	#Lobby.create_game()

#func _name_changed(_new_text: String):
	#if _new_text:
		#Lobby.player_info = {"name": _new_text}
