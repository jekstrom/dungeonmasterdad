class_name EnemyStateAggro extends EnemyState

enum RaidPhase { APPROACH, STRIKE, RETREAT }

@export var anim_name: String = "walk"
@export var run_speed: float = 220
@export var wander_state: EnemyState
@export var melee_cooldown: float = 1.0
@export var raid_standoff_px: float = 56.0
@export var raid_retreat_px: float = 168.0
@export var raid_strike_time: float = 0.28
@export var raid_retreat_time: float = 0.5

var _melee_timer: float = 0.0
var _raid_phase: RaidPhase = RaidPhase.APPROACH
var _raid_timer: float = 0.0
var _raid_retreat_dir: Vector2 = Vector2.DOWN
var _raid_hp_before: int = 0
var _raid_hit_landed: bool = false

func enter() -> void:
	_melee_timer = 0.0
	_raid_phase = RaidPhase.APPROACH
	_raid_timer = 0.0
	_raid_hit_landed = false
	enemy.acquire_aggro_target()
	enemy.UpdateAnimation(anim_name)

func exit() -> void:
	enemy.aggro_target = null
	_set_hurtbox_monitoring(false)

func process(_delta: float) -> EnemyState:
	if not enemy.has_aggro_target():
		return wander_state
	var target: Node2D = enemy.aggro_target
	if target is Building:
		_raid_building(target as Building, _delta)
		return null
	_chase_character(target, _delta)
	return null

func physics(_delta: float) -> EnemyState:
	return null

func _chase_character(target: Node2D, delta: float) -> void:
	var to_target: Vector2 = enemy.global_position.direction_to(target.global_position)
	if to_target.length_squared() < 0.0001:
		enemy.velocity = Vector2.ZERO
	else:
		enemy.velocity = to_target * run_speed
		enemy.SetDirection(to_target)
	enemy.UpdateAnimation(anim_name)
	if target is Player:
		_strike_player(target as Player, delta)
	else:
		_update_melee(delta)

func _raid_building(building: Building, delta: float) -> void:
	var origin: Vector2 = building.factory_origin()
	var dist: float = enemy.global_position.distance_to(origin)
	match _raid_phase:
		RaidPhase.STRIKE:
			enemy.velocity = Vector2.ZERO
			_set_hurtbox_monitoring(false)
			if building.destroyed or building.hitpoints < _raid_hp_before:
				_raid_hit_landed = true
			_raid_timer = maxf(0.0, _raid_timer - delta)
			if _raid_timer > 0.0:
				return
			if _raid_hit_landed:
				_start_retreat(origin)
			else:
				_raid_phase = RaidPhase.APPROACH
		RaidPhase.RETREAT:
			enemy.velocity = _raid_retreat_dir * run_speed
			enemy.SetDirection(_raid_retreat_dir)
			enemy.UpdateAnimation(anim_name)
			_set_hurtbox_monitoring(false)
			_raid_timer = maxf(0.0, _raid_timer - delta)
			if dist >= raid_retreat_px or _raid_timer <= 0.0:
				_raid_phase = RaidPhase.APPROACH
		_:
			var stand: Vector2 = _raid_stand_point(building, origin)
			var to_stand: Vector2 = stand - enemy.global_position
			if _can_strike_building(building, dist, to_stand.length()):
				_begin_strike(building)
			elif to_stand.length() < 6.0:
				enemy.velocity = Vector2.ZERO
				enemy.UpdateAnimation("idle")
			else:
				var dir: Vector2 = to_stand.normalized()
				enemy.velocity = dir * run_speed
				enemy.SetDirection(dir)
				enemy.UpdateAnimation(anim_name)
				_set_hurtbox_monitoring(false)

func _can_strike_building(building: Building, dist: float, stand_dist: float) -> bool:
	if building.destroyed or not building.is_operating():
		return false
	if not enemy.is_melee_close_to(building):
		return false
	if dist < 10.0:
		return false
	if _blocked_by_building(building):
		return true
	if stand_dist <= 24.0:
		return true
	var hull: Rect2 = building.raid_hull_rect(8.0)
	var closest: Vector2 = _closest_point_on_rect(hull, enemy.global_position)
	return enemy.global_position.distance_to(closest) <= 20.0

func _begin_strike(building: Building) -> void:
	enemy.velocity = Vector2.ZERO
	_set_hurtbox_monitoring(false)
	_raid_phase = RaidPhase.STRIKE
	_raid_timer = raid_strike_time
	_raid_hp_before = building.hitpoints
	_raid_hit_landed = false
	_melee_timer = melee_cooldown
	var to_origin: Vector2 = building.factory_origin() - enemy.global_position
	if to_origin.length_squared() > 0.0001:
		enemy.SetDirection(to_origin)
	enemy.UpdateAnimation("idle")
	_land_raid_hit(building)

func _land_raid_hit(building: Building) -> void:
	if not enemy.multiplayer.is_server():
		return
	var hurtbox: Node = enemy.get_node_or_null("Hurtbox")
	if not (hurtbox is Hurtbox):
		return
	building.take_damage(hurtbox as Hurtbox)
	if building.destroyed or building.hitpoints < _raid_hp_before:
		_raid_hit_landed = true

func _start_retreat(origin: Vector2) -> void:
	_raid_retreat_dir = _random_retreat_dir(origin)
	_raid_phase = RaidPhase.RETREAT
	_raid_timer = raid_retreat_time
	_raid_hit_landed = false
	_set_hurtbox_monitoring(false)
	enemy.SetDirection(_raid_retreat_dir)
	enemy.UpdateAnimation(anim_name)

func _raid_stand_point(building: Building, origin: Vector2) -> Vector2:
	var hull: Rect2 = building.raid_hull_rect(12.0)
	var closest: Vector2 = _closest_point_on_rect(hull, enemy.global_position)
	var out: Vector2 = enemy.global_position - closest
	if out.length_squared() < 1.0:
		out = enemy.global_position - hull.get_center()
	if out.length_squared() < 1.0:
		out = _away_from(origin)
	return closest + out.normalized() * 10.0

func _closest_point_on_rect(rect: Rect2, p: Vector2) -> Vector2:
	var min_p: Vector2 = rect.position
	var max_p: Vector2 = rect.end
	if not rect.has_point(p):
		return Vector2(clampf(p.x, min_p.x, max_p.x), clampf(p.y, min_p.y, max_p.y))
	var dl: float = p.x - min_p.x
	var dr: float = max_p.x - p.x
	var dt: float = p.y - min_p.y
	var db: float = max_p.y - p.y
	var m: float = minf(minf(dl, dr), minf(dt, db))
	if is_equal_approx(m, dl):
		return Vector2(min_p.x, p.y)
	if is_equal_approx(m, dr):
		return Vector2(max_p.x, p.y)
	if is_equal_approx(m, dt):
		return Vector2(p.x, min_p.y)
	return Vector2(p.x, max_p.y)

func _blocked_by_building(building: Building) -> bool:
	for i in enemy.get_slide_collision_count():
		var col: KinematicCollision2D = enemy.get_slide_collision(i)
		if col and col.get_collider() == building:
			return true
	return false

func _away_from(origin: Vector2) -> Vector2:
	var away: Vector2 = enemy.global_position - origin
	if away.length_squared() < 64.0:
		return Vector2.DOWN
	return away.normalized()

func _random_retreat_dir(origin: Vector2) -> Vector2:
	var away: Vector2 = _away_from(origin)
	for _i in 8:
		var dir: Vector2 = Vector2.from_angle(randf() * TAU)
		if dir.length_squared() < 0.01:
			continue
		dir = dir.normalized()
		if dir.dot(away) >= 0.1:
			return dir
	return away

func _strike_player(player: Player, delta: float) -> void:
	_melee_timer = maxf(0.0, _melee_timer - delta)
	if not enemy.can_melee_current_target():
		_set_hurtbox_monitoring(false)
		return
	if _melee_timer > 0.0:
		return
	_melee_timer = melee_cooldown
	_set_hurtbox_monitoring(false)
	if not enemy.multiplayer.is_server():
		return
	var hurtbox: Node = enemy.get_node_or_null("Hurtbox")
	if hurtbox is Hurtbox:
		player.take_damage(hurtbox as Hurtbox)

func _update_melee(delta: float) -> void:
	_melee_timer = maxf(0.0, _melee_timer - delta)
	if not enemy.can_melee_current_target():
		_set_hurtbox_monitoring(false)
		return
	if _melee_timer > 0.0:
		return
	_set_hurtbox_monitoring(false)
	_set_hurtbox_monitoring(true)
	_melee_timer = melee_cooldown

func _set_hurtbox_monitoring(enabled: bool) -> void:
	var hurtbox := enemy.get_node_or_null("Hurtbox")
	if hurtbox is Area2D:
		(hurtbox as Area2D).monitoring = enabled
