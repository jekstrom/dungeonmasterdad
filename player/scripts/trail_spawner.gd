class_name TrailSpawner extends MultiplayerSpawner

@export var trail_scene: PackedScene

func _enter_tree():
	if multiplayer.has_multiplayer_peer():
		set_multiplayer_authority(1)

func _ready() -> void:
	spawn_function = _custom_spawn
	if multiplayer.is_server():
		SignalBus.shadow_increased.connect(on_trail_added)
	
func _physics_process(_delta: float) -> void:
	pass
	
func _process(_delta: float) -> void:
	pass
	
func _custom_spawn(data: Dictionary) -> Node2D:
	var p = trail_scene.instantiate()
	p.position = data.position
	p.name = "trail_" + data.player_name + "_" + data.id
	p.player_id = data.player_id
	p.enabled = data.enabled
	p.set_meta("player_id", data.player_id)
	p.set_meta("id", data.id)
	return p

func spawn_trail(data: Dictionary):
	if !multiplayer.is_server(): return
	spawn(data)

func on_trail_added(trail_data: Dictionary) -> void:
	call_deferred("spawn_trail", trail_data)
