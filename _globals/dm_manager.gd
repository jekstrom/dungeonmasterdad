extends Node

#const __DM__ = preload("uid://e1aypo2ysyyc")
#const INVENTORY_DATA: InventoryData = preload("res://gui/pause_menu/inventory/player_inventory.tres")

#signal interact_pressed

var dm: DM
@export var fantasy_level: int = 0
signal fantasy_level_changed
signal spawn_gremlin_cast
var player_spawned: bool = false
var dm_player_name: String = "DM"

func _ready() -> void:
	add_player_instance()
	await get_tree().create_timer(0.2).timeout
	player_spawned = true

func add_player_instance() -> void:
	pass

func set_player_pos(new_pos: Vector2) -> void:
	dm.global_position = new_pos

func set_player_health(hp: int, max_hp: int) -> void:
	dm.max_hp = max_hp
	dm.hitpoints = hp

func set_as_parent(p: Node2D) -> void:
	if dm.get_parent():
		dm.get_parent().remove_child(dm)
	p.add_child(dm)

func unparent_player(p: Node2D) -> void:
	p.remove_child(dm)

func update_fantasy_level(level_inc: int) -> void:
	if multiplayer.is_server():
		fantasy_level += level_inc
		request_fantasy_level_incrase.rpc(fantasy_level)
		
func unlock_fireball() -> void:
	if multiplayer.is_server():
		DmUnlocks.unlock_fireball()
		SignalBus.on_dm_unlock.emit("fireball")
		request_fantasy_level_incrase.rpc(fantasy_level)
		
func spawn_gremlin() -> void:
	if multiplayer.is_server():
		spawn_gremlin_cast.emit()

@rpc("authority", "call_local", "reliable")
func request_fantasy_level_incrase(new_fantasy_level: int):
		fantasy_level = new_fantasy_level
		fantasy_level_changed.emit(new_fantasy_level)
