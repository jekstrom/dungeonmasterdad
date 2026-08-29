class_name Building extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

const BLIZZARD_FACTORY_INTERVAL_FACTOR := 2.0

@export var interval: float = 1.0
@export var hitpoints: int = 10
@export var blizzard_factory_interval_factor: float = BLIZZARD_FACTORY_INTERVAL_FACTOR
var timer: float = 0.0
var is_ghost: bool = true
var _baseline_interval: float = -1.0
var _applied_blizzard_factor: float = 1.0

func _enter_tree() -> void:
	_ensure_baseline_interval()
	if not SignalBus.spell_cast.is_connected(_on_blizzard_spell_cast):
		SignalBus.spell_cast.connect(_on_blizzard_spell_cast)
	if not SignalBus.fantasy_pocket_expired.is_connected(_on_blizzard_pocket_expired):
		SignalBus.fantasy_pocket_expired.connect(_on_blizzard_pocket_expired)
	if not SignalBus.map_bounds_cleared.is_connected(_on_blizzard_map_cleared):
		SignalBus.map_bounds_cleared.connect(_on_blizzard_map_cleared)

func _exit_tree() -> void:
	if SignalBus.spell_cast.is_connected(_on_blizzard_spell_cast):
		SignalBus.spell_cast.disconnect(_on_blizzard_spell_cast)
	if SignalBus.fantasy_pocket_expired.is_connected(_on_blizzard_pocket_expired):
		SignalBus.fantasy_pocket_expired.disconnect(_on_blizzard_pocket_expired)
	if SignalBus.map_bounds_cleared.is_connected(_on_blizzard_map_cleared):
		SignalBus.map_bounds_cleared.disconnect(_on_blizzard_map_cleared)

func set_ghost() -> void:
	is_ghost = true
	collision_shape_2d.set_deferred("disabled", true)

func enable() -> void:
	is_ghost = false
	collision_shape_2d.set_deferred("disabled", false)
	set_deferred("collision_layer", 1)
	set_deferred("collision_mask", 1)
	sync_blizzard_interval()

func factory_origin() -> Vector2:
	return global_position

func production_remaining() -> float:
	return maxf(0.0, interval - timer)

func sync_blizzard_interval(ignore_pocket_id: int = -1) -> void:
	if not multiplayer.is_server():
		return
	if is_ghost:
		return
	var in_pocket: bool = DmManager.is_in_blizzard_slow_rect(factory_origin(), ignore_pocket_id)
	var factor: float = blizzard_factory_interval_factor if in_pocket else 1.0
	if factor <= 0.0:
		factor = BLIZZARD_FACTORY_INTERVAL_FACTOR if in_pocket else 1.0
	_apply_blizzard_interval_factor(factor)

func _ensure_baseline_interval() -> void:
	if _baseline_interval < 0.0:
		_baseline_interval = interval

func _apply_blizzard_interval_factor(new_factor: float) -> void:
	_ensure_baseline_interval()
	if new_factor <= 0.0:
		new_factor = 1.0
	if is_equal_approx(new_factor, _applied_blizzard_factor):
		return
	var remaining: float = production_remaining()
	remaining *= new_factor / _applied_blizzard_factor
	interval = _baseline_interval * new_factor
	timer = interval - remaining
	_applied_blizzard_factor = new_factor

func _on_blizzard_spell_cast(spell_id: String, _spell_data: Dictionary) -> void:
	if spell_id != "bemidji_blizzard":
		return
	sync_blizzard_interval()

func _on_blizzard_pocket_expired(pocket_id: int) -> void:
	sync_blizzard_interval(pocket_id)

func _on_blizzard_map_cleared() -> void:
	_apply_blizzard_interval_factor(1.0)

func _process(_delta: float) -> void:
	if is_ghost: return
	pass
