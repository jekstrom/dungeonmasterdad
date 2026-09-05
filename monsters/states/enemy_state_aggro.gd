class_name EnemyStateAggro extends EnemyState

enum RaidPhase { APPROACH, STRIKE, RETREAT }

@export var anim_name: String = "walk"
@export var run_speed: float = 220
@export var wander_state: EnemyState
@export var melee_cooldown: float = 1.0
@export var raid_standoff_px: float = 12.0
@export var raid_melee_px: float = 40.0
@export var raid_strike_px: float = 28.0
@export var raid_retreat_px: float = 168.0
@export var raid_strike_time: float = 0.28
@export var raid_retreat_time: float = 0.5

var _melee_timer: float = 0.0
var _raid_phase: RaidPhase = RaidPhase.APPROACH
var _raid_timer: float = 0.0
var _raid_retreat_dir: Vector2 = Vector2.DOWN
var _raid_hp_before: int = 0
var _raid_hit_landed: bool = false
var _raid_in_melee: bool = false
var _raid_target_id: int = 0

func enter() -> void:
	_melee_timer = 0.0
	_raid_phase = RaidPhase.APPROACH
	_raid_timer = 0.0
	_raid_hit_landed = false
	_raid_in_melee = false
	_raid_target_id = 0
	enemy.clear_path_follow()
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
	if enemy.can_melee_current_target():
		enemy.velocity = Vector2.ZERO
		enemy.UpdateAnimation("idle")
	else:
		enemy.follow_path_to(target.global_position, run_speed, delta)
		enemy.UpdateAnimation(anim_name)
	_strike_character(target, delta)

func _raid_building(building: Building, delta: float) -> void:
	var origin: Vector2 = building.factory_origin()
	var dist: float = enemy.global_position.distance_to(origin)
	var building_id: int = building.get_instance_id()
	if building_id != _raid_target_id:
		_raid_target_id = building_id
		_raid_in_melee = false
		_raid_phase = RaidPhase.APPROACH
		enemy.clear_path_follow()
	if building.hull_distance(enemy.global_position) <= raid_melee_px:
		_raid_in_melee = true
	match _raid_phase:
		RaidPhase.STRIKE:
			enemy.clear_path_follow()
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
			enemy.clear_path_follow()
			enemy.velocity = _raid_retreat_dir * run_speed
			enemy.SetDirection(_raid_retreat_dir)
			enemy.UpdateAnimation(anim_name)
			_set_hurtbox_monitoring(false)
			_raid_timer = maxf(0.0, _raid_timer - delta)
			if dist >= raid_retreat_px or _raid_timer <= 0.0:
				_raid_phase = RaidPhase.APPROACH
		_:
			if _raid_in_melee:
				_raid_melee_close(building, origin, dist)
			else:
				enemy.follow_path_to(_raid_path_goal(building, origin), run_speed, delta)
				enemy.UpdateAnimation(anim_name)
				_set_hurtbox_monitoring(false)
				if building.hull_distance(enemy.global_position) <= raid_melee_px:
					_raid_in_melee = true
					enemy.clear_path_follow()
					if _can_strike_building(building, dist):
						_begin_strike(building)


func _raid_melee_close(building: Building, origin: Vector2, dist: float) -> void:
	enemy.clear_path_follow()
	if _can_strike_building(building, dist):
		_begin_strike(building)
		return
	if dist < 10.0:
		var away: Vector2 = _away_from(origin)
		enemy.velocity = away * run_speed
		enemy.SetDirection(away)
		enemy.UpdateAnimation(anim_name)
		_set_hurtbox_monitoring(false)
		return
	var closest: Vector2 = building.closest_hull_point(enemy.global_position)
	var to_hull: Vector2 = closest - enemy.global_position
	if to_hull.length_squared() < 0.0001:
		to_hull = origin - enemy.global_position
	if to_hull.length_squared() < 0.0001:
		enemy.velocity = Vector2.ZERO
		enemy.UpdateAnimation("idle")
		return
	enemy.velocity = to_hull.normalized() * run_speed
	enemy.SetDirection(to_hull)
	enemy.UpdateAnimation(anim_name)
	_set_hurtbox_monitoring(false)


func _raid_path_goal(building: Building, origin: Vector2) -> Vector2:
	var closest: Vector2 = building.closest_hull_point(enemy.global_position)
	var out: Vector2 = enemy.global_position - closest
	if out.length_squared() < 1.0:
		out = _away_from(origin)
	var stand: Vector2 = closest + out.normalized() * raid_standoff_px
	var tree := enemy.get_tree()
	if tree:
		var finder: Node = tree.root.get_node_or_null("MonsterPathfinder")
		if finder and finder.has_method("nearest_walkable_world"):
			return finder.nearest_walkable_world(stand)
	return stand

func _can_strike_building(building: Building, dist: float) -> bool:
	if building.destroyed or not building.is_operating():
		return false
	if dist < 10.0:
		return false
	if _blocked_by_building(building):
		return true
	return building.hull_distance(enemy.global_position) <= raid_strike_px

func _begin_strike(building: Building) -> void:
	enemy.clear_path_follow()
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
	enemy.clear_path_follow()
	_raid_retreat_dir = _random_retreat_dir(origin)
	_raid_phase = RaidPhase.RETREAT
	_raid_timer = raid_retreat_time
	_raid_hit_landed = false
	_set_hurtbox_monitoring(false)
	enemy.SetDirection(_raid_retreat_dir)
	enemy.UpdateAnimation(anim_name)

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

func _strike_character(target: Node2D, delta: float) -> void:
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
	if not (hurtbox is Hurtbox):
		return
	if target is Player:
		(target as Player).take_damage(hurtbox as Hurtbox)
		return
	var hitbox: Node = target.get_node_or_null("Hitbox")
	if hitbox is Hitbox:
		(hitbox as Hitbox).take_damage(hurtbox as Hurtbox)

func _set_hurtbox_monitoring(enabled: bool) -> void:
	var hurtbox := enemy.get_node_or_null("Hurtbox")
	if hurtbox is Area2D:
		(hurtbox as Area2D).monitoring = enabled
