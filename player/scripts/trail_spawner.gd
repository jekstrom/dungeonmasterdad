class_name TrailSpawner extends MultiplayerSpawner

@export var trail_scene: PackedScene

func _enter_tree():
	set_multiplayer_authority(1)

func _ready() -> void:
	spawn_function = _custom_spawn
	set_multiplayer_authority(1)
	if not SignalBus.shadow_increased.is_connected(on_trail_added):
		SignalBus.shadow_increased.connect(on_trail_added)

func _custom_spawn(data: Dictionary) -> Node2D:
	var p = trail_scene.instantiate()
	p.position = data.position
	p.name = TrailManager.trail_node_name(int(data.player_id), str(data.id))
	p.player_id = data.player_id
	p.enabled = data.enabled
	p.set_meta("player_id", data.player_id)
	p.set_meta("id", data.id)
	return p

func spawn_trail(data: Dictionary):
	if not Lobby.is_network_server():
		return
	if trail_scene == null:
		return
	spawn(data)

func on_trail_added(trail_data: Dictionary) -> void:
	call_deferred("spawn_trail", trail_data)
