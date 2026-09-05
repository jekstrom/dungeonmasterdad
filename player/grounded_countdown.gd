extends Node2D

const BAR_WIDTH: float = 48.0
const BAR_HEIGHT: float = 8.0

@onready var skull: Sprite2D = $Skull
@onready var fill: ColorRect = $BarFill
@onready var background: ColorRect = $BarBg

var _pulse_t: float = 0.0
var _local_elapsed: float = 0.0


func _ready() -> void:
	z_as_relative = false
	z_index = 100
	visible = false
	if background:
		background.position = Vector2(-BAR_WIDTH * 0.5, 18.0)
		background.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	if fill:
		fill.position = Vector2(-BAR_WIDTH * 0.5, 18.0)
		fill.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	if skull:
		skull.scale = Vector2(1.6, 1.6)


func _process(delta: float) -> void:
	var player: Player = get_parent() as Player
	if player == null or player.hitpoints <= 0:
		_reset()
		return
	if not _is_warning_active(player):
		_reset()
		return
	var remaining: float = _remaining(player, delta)
	visible = true
	var limit: float = DmManager.GROUNDED_FANTASY_SEC
	var ratio: float = clampf(remaining / limit, 0.0, 1.0)
	if fill:
		fill.size = Vector2(BAR_WIDTH * ratio, BAR_HEIGHT)
		fill.color = Color(0.95, 0.12 + ratio * 0.35, 0.12, 1.0)
	var urgency: float = 1.0 - ratio
	_pulse_t += delta * (3.0 + urgency * 7.0)
	var pulse: float = 0.5 + 0.5 * sin(_pulse_t * TAU)
	if skull:
		var scale_amt: float = 1.6 + 0.28 * pulse * (0.45 + urgency)
		skull.scale = Vector2(scale_amt, scale_amt)
		skull.modulate = Color(1.0, 0.7 + 0.3 * pulse, 0.7 + 0.3 * pulse, 1.0)


func _is_warning_active(player: Player) -> bool:
	if not DmUnlocks.is_owned("grounded"):
		return false
	var tree := get_tree()
	if tree == null:
		return false
	var fantasy: Node = tree.get_first_node_in_group("FantasyZone")
	if fantasy == null or not fantasy.has_method("is_claimed_world"):
		return false
	return bool(fantasy.call("is_claimed_world", player.global_position))


func _remaining(player: Player, delta: float) -> float:
	var limit: float = DmManager.GROUNDED_FANTASY_SEC
	if player.grounded_remaining > 0.001:
		_local_elapsed = limit - player.grounded_remaining
		return player.grounded_remaining
	_local_elapsed = minf(limit, _local_elapsed + delta)
	return maxf(0.0, limit - _local_elapsed)


func _reset() -> void:
	visible = false
	_pulse_t = 0.0
	_local_elapsed = 0.0
