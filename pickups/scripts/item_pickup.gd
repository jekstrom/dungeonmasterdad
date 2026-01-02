@tool
class_name ItemPickup extends CharacterBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var area_2d: Area2D = $Area2D

@export var item_data: ItemData: set = _set_item_data

func _ready() -> void:
	update_texture()
	if Engine.is_editor_hint():
		return
	area_2d.body_entered.connect(on_body_entered)
	if item_data:
		audio_stream_player_2d.stream = item_data.pickup_sound

func _physics_process(delta: float) -> void:
	var collision_info = move_and_collide(velocity * delta)
	if collision_info:
		velocity = velocity.bounce(collision_info.get_normal())
	velocity -= velocity * delta * 4

func on_body_entered(_body) -> void:
	if _body is DM and item_data != null and (item_data.pickup_char.is_empty() or item_data.pickup_char == "dm_only"):
		handle_pickup(1, item_data)
	if _body is Player and item_data != null and (item_data.pickup_char.is_empty() or item_data.pickup_char == "player_only"):
		try_pick_up(item_data)
	area_2d.body_entered.disconnect(on_body_entered)

func try_pick_up(picked_up_item_data: ItemData):
	# Send a request to the server with the item's unique name or ID
	pick_up_request.rpc_id(1, picked_up_item_data.get_path())

@rpc("any_peer", "call_remote", "reliable")
func pick_up_request(item_path: String) -> void:
	if not multiplayer.is_server(): return
	
	var sender_id = multiplayer.get_remote_sender_id()
	var player_node = get_node("../" + str(sender_id))
	var picked_up_item_data: ItemData = ItemDatabase.get_item(item_path)
	
	var d = player_node.global_position.distance_to(self.global_position)
	if d < 30.0:
		handle_pickup(sender_id, picked_up_item_data)

func handle_pickup(sender_id: int, picked_up_item_data: ItemData) -> void:
	PlayerManager.add_item_to_inventory(sender_id, picked_up_item_data)
	AudioManager.play_private_sound(sender_id, item_data.pickup_sound.resource_path, Vector2(0.6, 1.0))
	update_client.rpc()

@rpc("any_peer", "call_local", "reliable")
func update_client():
	visible = false
	queue_free()

func update_texture() -> void:
	if item_data != null and sprite_2d != null:
		sprite_2d.texture = item_data.texture

func _set_item_data(_value: ItemData) -> void:
	item_data = _value
	update_texture()
