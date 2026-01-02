extends Node

var max_polyphony: int = 4

# --- PRIVATE/UI AUDIO ---
func play_private_sound(peer_id: int, sound_path: String, pitch_range: Vector2 = Vector2(1.0, 1.0)):
	if not multiplayer.is_server(): return
	_client_play_flat_sound.rpc_id(peer_id, sound_path, pitch_range)

# --- SPATIAL 2D AUDIO ---
# Use this for explosions, footsteps, or environmental sounds in the game world
func play_spatial_2d(sound_path: String, position: Vector2, pitch_range: Vector2 = Vector2(1.0, 1.0)):
	if not multiplayer.is_server(): return
	_client_play_2d_sound.rpc(sound_path, position, pitch_range)

# --- INTERNAL CLIENT LOGIC ---
@rpc("authority", "call_local", "reliable")
func _client_play_flat_sound(sound_path: String, pitch_range: Vector2):
	var player = AudioStreamPlayer.new()
	player.max_polyphony = max_polyphony
	_setup_and_play(player, sound_path, pitch_range)

@rpc("authority", "call_local", "reliable")
func _client_play_2d_sound(sound_path: String, pos: Vector2, pitch_range: Vector2):
	var player = AudioStreamPlayer2D.new()
	player.max_polyphony = max_polyphony
	player.global_position = pos
	
	player.max_distance = 2000.0 # Pixels
	player.attenuation = 1.0      # 1.0 is standard log falloff
	
	_setup_and_play(player, sound_path, pitch_range)

func _setup_and_play(player: Node, sound_path: String, pitch_range: Vector2):
	add_child(player)
	player.stream = load(sound_path)
	player.bus = &"SFX"
	player.pitch_scale = randf_range(pitch_range.x, pitch_range.y)
	player.play()
	player.finished.connect(player.queue_free)
