class_name SnakeTrailContainer
extends Node2D
#
## Synchronized properties (automatically replicated by MultiplayerSynchronizer)
##@export var trail_positions: Array[Vector2] = []
##@export var trail_count: int = 0
##@export var player_id: int = -1
##@export var max_segments: int = 50
##@export var shadow: PackedScene
#@export var enabled: bool = false
#
## Local properties (not synchronized)
#var shadow_pool: Array[Shadow] = []
#var collision_pool: Array[StaticBody2D] = []
#var active_shadows: Array[Shadow] = []
#var active_collisions: Array[StaticBody2D] = []
#
## Trail configuration
#var collision_radius: float = 6.0
#var trail_interval: float = 16.0
#
## Node references
#@onready var multiplayer_sync: MultiplayerSynchronizer = $MultiplayerSynchronizer
#@onready var segments_container: Node2D = $TrailSegments
#
## Signals
#signal trail_segments_changed(segment_count: int)
#signal cleanup_requested(player_id: int)
#
#func _ready() -> void:
	##setup_sprite_pool()
	#enabled = false
	#SignalBus.on_item_pickup.connect(add_trail_segment)
##
##func setup_sprite_pool() -> void:
	##for i in range(max_segments + 10):
		##var shadow_node = create_trail_shadow(-max_segments + i)
		##
		##shadow_node.visible = false
		##shadow_node.enabled = false
		##segments_container.add_child(shadow_node)
		##
		##shadow_pool.append(shadow_node)
##
##func setup_for_player(pid: int, max_segs: int = 50) -> void:
	##player_id = pid
	##max_segments = max_segs
	##
	### Set up initial state
	##trail_positions.clear()
	##trail_count = 0
	##
	##enabled = true
	##print("SnakeTrailContainer: Setup for player ", player_id, " with max segments ", max_segments)
##
##func update_trail_positions(head_position: Vector2) -> void:
	##if not multiplayer.is_server(): return
	##if not enabled: return
	##
	##trail_positions.push_back(head_position)
	##
	##while trail_positions.size() > max_segments:
		##trail_positions.pop_front()
	##
	##trail_count = trail_positions.size()
	##
	##update_sprite_positions()
#
#func add_trail_segment(pid: int) -> void:
	#if not multiplayer.is_server(): return
	#if not enabled: return
#
	#add_trail_segment_on_client.rpc_id(pid)
	#print ("Adding shadow to player: ", pid)
		#
	## This will be called when player picks up items to extend trail
	##max_segments += 1
	##trail_segments_changed.emit(max_segments)
#
	##add_shadow_from_pool()
#
#@rpc("authority", "call_remote", "reliable")
#func add_trail_segment_on_client() -> void:
	#pass
#
#func trim_trail_segments(new_max: int) -> void:
	#if not multiplayer.is_server(): return
	#if not enabled: return
	#
	#max_segments = new_max
	#
	## Remove excess positions
	#while trail_positions.size() > max_segments:
		#trail_positions.pop_front()
	#
	#trail_count = trail_positions.size()
	#update_sprite_positions()
##
##func update_sprite_positions() -> void:
	##if not enabled: return
	### Ensure we have enough active sprites
	##while active_shadows.size() < trail_positions.size():
		##add_shadow_from_pool()
	##
	### Return excess sprites to pool
	##while active_shadows.size() > trail_positions.size():
		##return_shadow_to_pool()
	##
	### Update positions for active sprites
	##var size = min(active_shadows.size(), trail_positions.size())
	##for i in range(size):
		##var active_shadow = active_shadows[i]
		##
		##active_shadow.global_position = trail_positions[i]
##
##func add_shadow_from_pool() -> void:
	##if not enabled: return
	##if shadow_pool.size() > 0 and collision_pool.size() > 0:
		##var added_shadow: Shadow = shadow_pool.pop_back()
		##var collision = collision_pool.pop_back()
		##
		##added_shadow.visible = true
		##collision.set_meta("trail_owner_id", player_id)
		##
		##active_shadows.append(added_shadow)
		##active_collisions.append(collision)
##
##func return_shadow_to_pool() -> void:
	##if not enabled: return
	##if active_shadows.size() > 0 and active_collisions.size() > 0:
		##var active_shadow: Shadow = active_shadows.pop_back()
		##var collision = active_collisions.pop_back()
		##
		##active_shadow.visible = false
		##
		##shadow_pool.append(active_shadow)
		##collision_pool.append(collision)
##
##func create_trail_shadow(segment_index: int) -> Shadow:
	##var trail_shadow: Shadow = shadow.instantiate()
	##trail_shadow.name = "trail_" + str(player_id) + "_" + str(segment_index)
	##print("SnakeTrailContainer: ", trail_shadow.name)
	##return trail_shadow
#
#func get_player_by_id(pid: int) -> Node:
	## Find player node by ID (reuse logic from snake state)
	#var players = get_tree().get_nodes_in_group("players")
	#for player_node in players:
		#if player_node.name.is_valid_int() and int(player_node.name) == pid:
			#return player_node
	#
	#for player_node in players:
		#if player_node.has_method("get_player_id") and player_node.get_player_id() == pid:
			#return player_node
		#elif "player_id" in player_node and player_node.player_id == pid:
			#return player_node
	#
	#if multiplayer.has_multiplayer_peer():
		#for player_node in players:
			#if player_node.is_multiplayer_authority() and player_node.get_multiplayer_authority() == pid:
				#return player_node
	#
	#return null
##
##func get_trail_data() -> Dictionary:
	##return {
		##"player_id": player_id,
		##"positions": trail_positions,
		##"count": trail_count,
		##"max_segments": max_segments
	##}
#
#func cleanup() -> void:
	## Return all sprites to pool
	#while active_shadows.size() > 0:
		#return_shadow_to_pool()
	#
	## Clear position data
	#trail_positions.clear()
	#trail_count = 0
	#
	## Emit cleanup signal
	#cleanup_requested.emit(player_id)
	#
	#print("SnakeTrailContainer: Cleaned up for player ", player_id)
#
##var last_sync_count: int = 0
#
func _process(_delta: float) -> void:
	pass
