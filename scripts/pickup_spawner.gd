class_name PickupSpawner extends MultiplayerSpawner

@export
var pickup_scene: PackedScene

func _ready():
	spawn_function = _custom_spawn
	SignalBus.on_item_drop.connect(on_item_drop)

func _custom_spawn(data: Dictionary) -> Node2D:
	var p = pickup_scene.instantiate()
	p.item_data = ItemDatabase.get_item(data.item_type)
	p.position = data.position
	
	return p

func spawn_pickup(data: Dictionary):
	if !multiplayer.is_server(): return
	spawn(data)

func on_item_drop(pickup_data: Dictionary) -> void:
	spawn_pickup(pickup_data)
