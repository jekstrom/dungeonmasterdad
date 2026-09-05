extends RefCounted

const ARRIVAL_PX: float = 12.0
const GOAL_ARRIVE_PX: float = 12.0
const DIRECT_PROBE_PX: float = 32.0

var path: Array[Vector2i] = []
var goal_cell: Vector2i = DungeonGrid.SENTINEL
var goal_world: Vector2 = Vector2.INF
var repath_in: float = 0.0
var inland: bool = false


func clear() -> void:
	path.clear()
	goal_cell = DungeonGrid.SENTINEL
	goal_world = Vector2.INF
	repath_in = 0.0


func velocity_toward(body: Node2D, dest_world: Vector2, speed: float, delta: float, use_inland: bool = false) -> Vector2:
	goal_world = dest_world
	var pos: Vector2 = body.global_position
	var to_goal: Vector2 = dest_world - pos
	if to_goal.length() <= GOAL_ARRIVE_PX:
		path.clear()
		return Vector2.ZERO
	var finder: Node = body.get_tree().root.get_node_or_null("MonsterPathfinder") if body.get_tree() else null
	if finder == null:
		return to_goal.normalized() * speed
	inland = use_inland
	var start: Vector2i = finder.world_to_cell(pos)
	if not bool(finder.is_walkable_cell(start)):
		var snap: Vector2 = finder.nearest_walkable_world(pos)
		var to_snap: Vector2 = snap - pos
		if to_snap.length_squared() < 0.0001:
			return Vector2.ZERO
		return to_snap.normalized() * speed
	if _can_go_direct(body, finder, pos, dest_world):
		path.clear()
		goal_cell = DungeonGrid.SENTINEL
		return to_goal.normalized() * speed
	var want: Vector2i = finder.world_to_cell(dest_world)
	repath_in = maxf(0.0, repath_in - delta)
	var need: bool = want != goal_cell or repath_in <= 0.0
	if not path.is_empty() and not finder.is_walkable_cell(path[0]):
		need = true
	if need:
		var found: Array[Vector2i] = finder.find_path(start, want, inland)
		if finder.last_result_deferred and not path.is_empty() and want == goal_cell:
			pass
		else:
			path = found
			goal_cell = want
			repath_in = finder.REPATH_INTERVAL_SEC
	_discard_passed(pos, finder, start)
	if path.is_empty():
		return Vector2.ZERO
	var dest: Vector2 = _next_point(pos, finder)
	var to: Vector2 = dest - pos
	if to.length() <= ARRIVAL_PX:
		if path.size() > 1:
			path.remove_at(0)
			dest = _next_point(pos, finder)
			to = dest - pos
		elif to_goal.length() > GOAL_ARRIVE_PX:
			dest = dest_world
			to = dest - pos
	if to.length_squared() < 0.0001:
		return Vector2.ZERO
	return to.normalized() * speed


func _discard_passed(pos: Vector2, finder: Node, start: Vector2i) -> void:
	while not path.is_empty() and path[0] == start:
		path.remove_at(0)
	while not path.is_empty() and pos.distance_to(finder.cell_center(path[0])) <= ARRIVAL_PX:
		path.remove_at(0)
	while path.size() > 1:
		var ahead: Vector2 = finder.cell_center(path[1])
		if not bool(finder.world_segment_walkable(pos, ahead, false)):
			break
		path.remove_at(0)


func _next_point(pos: Vector2, finder: Node) -> Vector2:
	if path.is_empty():
		return pos
	if path.size() == 1 and bool(finder.world_segment_walkable(pos, goal_world, true)):
		return goal_world
	return finder.cell_center(path[0])


func _can_go_direct(body: Node2D, finder: Node, pos: Vector2, dest_world: Vector2) -> bool:
	if body is CharacterBody2D and (body as CharacterBody2D).get_slide_collision_count() > 0:
		return false
	if not bool(finder.is_world_walkable(dest_world)):
		return false
	if bool(finder.is_dungeon_world(pos)) != bool(finder.is_dungeon_world(dest_world)):
		return false
	var to: Vector2 = dest_world - pos
	var dist: float = to.length()
	if dist < 1.0:
		return true
	var probe: Vector2 = pos + to / dist * minf(DIRECT_PROBE_PX, dist)
	if not bool(finder.is_world_walkable(probe)):
		return false
	return bool(finder.world_segment_walkable(pos, dest_world, true))
