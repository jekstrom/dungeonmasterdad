extends MultiplayerSpawner

func _enter_tree():
	set_multiplayer_authority(1)

func _ready():
	set_multiplayer_authority(1)
