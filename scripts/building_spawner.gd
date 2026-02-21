extends MultiplayerSpawner

func _enter_tree():
	# Set server authority after multiplayer is ready
	if multiplayer.has_multiplayer_peer():
		set_multiplayer_authority(1)

func _ready():
	# Ensure server authority is set when multiplayer is ready
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		set_multiplayer_authority(1)
