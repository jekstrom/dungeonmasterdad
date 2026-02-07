class_name PlayerRespawnWaitState extends PlayerState

@onready var idle: PlayerState = $"../idle"

# Respawn wait state properties
var respawn_delay_duration: float = 0.0
var respawn_delay_remaining: float = 0.0
var respawn_position: Vector2 = Vector2.ZERO
var delay_timer: Timer = null
var countdown_ui_timer: Timer = null

# Constants
const COUNTDOWN_UPDATE_INTERVAL: float = 0.1  # Update countdown UI 10 times per second

func Enter() -> void:
	print("PlayerRespawnWaitState: Player ", player.get_multiplayer_authority(), " entering respawn wait")
	
	# Stop all player movement and input
	player.velocity = Vector2.ZERO
	
	# Note: Player is already hidden from death state - keep them hidden during respawn wait
	# The death state handles all visibility/collision management
	
	# Set up countdown timers
	_setup_countdown_timers()
	
	# Connect to respawn delay signals
	SignalBus.player_respawn_delay_started.connect(_on_respawn_delay_started)
	SignalBus.player_respawn_completed.connect(_on_respawn_completed)
	
	# Emit signal for UI systems to show respawn countdown
	SignalBus.player_respawn_delay_started.emit(player.get_multiplayer_authority(), respawn_delay_remaining)
	
	print("PlayerRespawnWaitState: Respawn wait started - ", respawn_delay_remaining, "s remaining")

func Exit() -> void:
	print("PlayerRespawnWaitState: Player ", player.get_multiplayer_authority(), " exiting respawn wait")
	
	# Clean up timers
	_cleanup_timers()
	
	# Disconnect signals
	if SignalBus.player_respawn_delay_started.is_connected(_on_respawn_delay_started):
		SignalBus.player_respawn_delay_started.disconnect(_on_respawn_delay_started)
	if SignalBus.player_respawn_completed.is_connected(_on_respawn_completed):
		SignalBus.player_respawn_completed.disconnect(_on_respawn_completed)

func Process(_delta: float) -> PlayerState:
	# Update countdown timers
	if respawn_delay_remaining > 0:
		respawn_delay_remaining -= _delta
		
		# Clamp to zero to avoid negative values
		respawn_delay_remaining = max(0.0, respawn_delay_remaining)
		
		# Check if respawn delay is complete
		if respawn_delay_remaining <= 0:
			print("PlayerRespawnWaitState: Respawn delay completed, transitioning to idle")
			return idle
	
	# Keep player stationary during wait
	player.velocity = Vector2.ZERO
	return null

func Physics(_delta: float) -> PlayerState:
	# No physics processing during respawn wait
	player.velocity = Vector2.ZERO
	return null

func HandleInput(_event: InputEvent) -> PlayerState:
	# Limited input during respawn wait
	# Could allow camera movement or menu access, but no gameplay actions
	
	# For now, no input handling - player must wait
	return null

# =============================================================================
# RESPAWN DELAY MANAGEMENT
# =============================================================================

func set_respawn_delay(delay_duration: float, spawn_position: Vector2) -> void:
	"""Initialize respawn delay parameters"""
	respawn_delay_duration = delay_duration
	respawn_delay_remaining = delay_duration
	respawn_position = spawn_position
	
	print("PlayerRespawnWaitState: Set respawn delay to ", delay_duration, "s at position ", spawn_position)

func _setup_countdown_timers() -> void:
	"""Set up timers for respawn countdown"""
	# Create countdown UI update timer
	countdown_ui_timer = Timer.new()
	countdown_ui_timer.wait_time = COUNTDOWN_UPDATE_INTERVAL
	countdown_ui_timer.timeout.connect(_update_countdown_ui)
	add_child(countdown_ui_timer)
	countdown_ui_timer.start()

func _cleanup_timers() -> void:
	"""Clean up countdown timers"""
	if countdown_ui_timer != null and is_instance_valid(countdown_ui_timer):
		countdown_ui_timer.stop()
		countdown_ui_timer.queue_free()
		countdown_ui_timer = null

func _update_countdown_ui() -> void:
	"""Update countdown UI display"""
	if respawn_delay_remaining > 0:
		# Emit signal for UI to update countdown display
		# Could be picked up by HUD or respawn UI
		var formatted_time = "%d" % ceil(respawn_delay_remaining)
		print("Respawn in: ", formatted_time, "s")
		
		# TODO: Emit proper UI signal when respawn UI system is implemented
		# SignalBus.respawn_countdown_updated.emit(player.get_multiplayer_authority(), respawn_delay_remaining)

func get_respawn_progress() -> float:
	"""Get respawn progress as a value from 0.0 to 1.0"""
	if respawn_delay_duration <= 0:
		return 1.0
	
	return 1.0 - (respawn_delay_remaining / respawn_delay_duration)

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_respawn_delay_started(player_id: int, delay: float) -> void:
	"""Handle respawn delay started signal"""
	# Only respond to signals for this player
	if player_id != player.get_multiplayer_authority():
		return
	
	print("PlayerRespawnWaitState: Respawn delay started for ", delay, "s")
	respawn_delay_duration = delay
	respawn_delay_remaining = delay

func _on_respawn_completed(player_id: int, new_position: Vector2) -> void:
	"""Handle respawn completed signal"""
	# Only respond to signals for this player
	if player_id != player.get_multiplayer_authority():
		return
	
	print("PlayerRespawnWaitState: Respawn completed at position ", new_position)
	
	# Move player to respawn position
	player.global_position = new_position
	respawn_position = new_position
	
	# Mark respawn as complete
	respawn_delay_remaining = 0.0
	
	# State machine will transition to idle on next Process() call

# =============================================================================
# UTILITY METHODS
# =============================================================================

func get_remaining_time_formatted() -> String:
	"""Get remaining time as formatted string for UI display"""
	if respawn_delay_remaining <= 0:
		return "Ready"
	
	var minutes = int(respawn_delay_remaining) / 60.0
	var seconds = int(respawn_delay_remaining) % 60
	
	if minutes > 0:
		return "%dm %02ds" % [minutes, seconds]
	else:
		return "%ds" % seconds

func is_respawn_ready() -> bool:
	"""Check if respawn delay has completed"""
	return respawn_delay_remaining <= 0

func force_respawn() -> PlayerState:
	"""Force immediate respawn (for debugging or admin commands)"""
	print("PlayerRespawnWaitState: Forcing immediate respawn")
	respawn_delay_remaining = 0.0
	return idle

# =============================================================================
# DEBUG AND MONITORING
# =============================================================================

func get_state_info() -> Dictionary:
	"""Return current state information for debugging"""
	return {
		"state": "respawn_wait",
		"delay_duration": respawn_delay_duration,
		"remaining_time": respawn_delay_remaining,
		"progress": get_respawn_progress(),
		"respawn_position": respawn_position,
		"is_ready": is_respawn_ready()
	}
