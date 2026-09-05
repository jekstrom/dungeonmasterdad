extends Node

const OccupancyScript = preload("res://scripts/pathfinding/occupancy_grid.gd")
const PathFollowerScript = preload("res://scripts/pathfinding/monster_path_follower.gd")

func _ready() -> void:
	if not _run_suite():
		return
	print("US-056 monster A* pathfinding test passed")
	get_tree().quit(0)


func _run_suite() -> bool:
	var finder: Node = get_node_or_null("/root/MonsterPathfinder")
	if finder == null:
		return _fail("US-056: MonsterPathfinder autoload missing")
	if not is_equal_approx(float(finder.occupancy.CELL_PX), 32.0):
		return _fail("US-056: path grid must be 32px cells")
	if finder.world_to_cell(Vector2(96, 32)) != Vector2i(3, 1):
		return _fail("US-056: 32px world_to_cell(96,32) want (3,1)")

	var region := Rect2i(Vector2i.ZERO, Vector2i(9, 10))
	var walkable: Array[Vector2i] = []
	for y in range(10):
		for x in range(9):
			if x == 4 and y < 9:
				continue
			walkable.append(Vector2i(x, y))
	var cliffs: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, -1), Vector2i(2, -1)]
	finder.configure_test_map(region, walkable, cliffs)

	var around: Array[Vector2i] = finder.find_path(Vector2i(1, 5), Vector2i(7, 5), false)
	if around.is_empty():
		return _fail("US-056 AC1: path around wall is empty")
	if not _uses_gap(around):
		return _fail("US-056 AC2: path must use the corridor gap at y=9")
	for cell in around:
		if cell.x == 4 and cell.y < 9:
			return _fail("US-056 AC1: path walked through the wall")
		if not finder.is_walkable_cell(cell):
			return _fail("US-056 FR-003: path contains blocked cell %s" % cell)

	var sealed: Array[Vector2i] = []
	for y in range(10):
		for x in range(9):
			if x == 4:
				continue
			sealed.append(Vector2i(x, y))
	finder.configure_test_map(region, sealed, cliffs)
	var none: Array[Vector2i] = finder.find_path(Vector2i(1, 5), Vector2i(7, 5), false)
	if not none.is_empty():
		return _fail("US-056 AC8: sealed wall must yield no path, got %d cells" % none.size())

	var open_line: Array[Vector2i] = []
	for x in range(5):
		open_line.append(Vector2i(x, 0))
	var no_cliffs: Array[Vector2i] = []
	finder.configure_test_map(Rect2i(Vector2i.ZERO, Vector2i(5, 1)), open_line, no_cliffs)
	finder.searches_this_frame = 0
	var los: Array[Vector2i] = finder.find_path(Vector2i(0, 0), Vector2i(4, 0), false)
	if los.size() != 5:
		return _fail("US-056 AC7: LOS path want 5 cells got %d" % los.size())
	if bool(finder.last_used_astar) or not bool(finder.last_used_los):
		return _fail("US-056 AC7: LOS must skip A*")
	finder.searches_this_frame = 0
	var inland_los: Array[Vector2i] = finder.find_path(Vector2i(0, 0), Vector2i(4, 0), true)
	if inland_los.size() != 5 or bool(finder.last_used_astar):
		return _fail("US-056: open-ground inland seek must still LOS-skip to the goal")
	if int(finder.searches_this_frame) != 0:
		return _fail("US-056 AC7: LOS must not consume search budget")

	finder.configure_test_map(region, walkable, cliffs)
	finder.searches_this_frame = 0
	var deferred_hits: int = 0
	for i in range(12):
		var start := Vector2i(0, i % 9)
		var goal := Vector2i(8, (i + 3) % 9)
		finder._cache.clear()
		var p: Array[Vector2i] = finder.find_path(start, goal, false)
		if bool(finder.last_result_deferred):
			deferred_hits += 1
			if not p.is_empty():
				return _fail("US-056 AC10: deferred search must not return a new path")
	if int(finder.searches_this_frame) > int(finder.MAX_SEARCHES_PER_FRAME):
		return _fail("US-056 AC10: searches_this_frame %d over cap" % int(finder.searches_this_frame))
	if deferred_hits < 1:
		return _fail("US-056 AC10: expected later requests to defer")

	finder.configure_test_map(region, walkable, cliffs)
	var before: Array[Vector2i] = finder.find_path(Vector2i(1, 5), Vector2i(7, 5), false)
	if before.is_empty():
		return _fail("US-056 AC9: baseline path empty")
	if not _uses_gap(before):
		return _fail("US-056 AC9: baseline path missing gap size=%d first=%s last=%s" % [before.size(), str(before[0]), str(before[before.size() - 1])])
	var no_gap: Array[Vector2i] = []
	for y in range(10):
		for x in range(9):
			if x == 4:
				continue
			no_gap.append(Vector2i(x, y))
	finder.configure_test_map(region, no_gap, cliffs)
	var after: Array[Vector2i] = finder.find_path(Vector2i(1, 5), Vector2i(7, 5), false)
	if not after.is_empty():
		return _fail("US-056 AC9: occupancy dirty must drop the sealed corridor path")

	finder.configure_test_map(region, walkable, cliffs)
	var inland: Array[Vector2i] = finder.find_path(Vector2i(1, 0), Vector2i(3, 0), true)
	if inland.is_empty():
		return _fail("US-056 AC4: inland A* returned empty on open cells")
	for cell in inland:
		if not finder.is_walkable_cell(cell):
			return _fail("US-056 AC4: inland path left walkable cells")

	if not _assert_collider_stamp_uses_cell_centers(finder):
		return false
	if not _assert_los_goes_straight(finder):
		return false
	if not _assert_dungeon_exit_path(finder):
		return false
	if not _assert_string_pull(finder):
		return false
	if not _assert_exit_portal_follow(finder):
		return false
	if not _assert_tree_trunk_blocks(finder):
		return false

	return true


func _assert_tree_trunk_blocks(finder: Node) -> bool:
	var occ = OccupancyScript.new()
	occ.region = Rect2i(Vector2i.ZERO, Vector2i(24, 24))
	for y in range(24):
		for x in range(24):
			occ.walkable[Vector2i(x, y)] = true
	var tree: Node2D = load("res://doodads/tree.tscn").instantiate() as Node2D
	if tree == null:
		return _fail("US-056: tree.tscn must instantiate")
	add_child(tree)
	tree.global_position = Vector2(320.0, 320.0)
	occ._block_live_tree_trunks(get_tree())
	var trunk: Vector2i = OccupancyScript.from_world(tree.global_position)
	var blocked := 0
	for y in range(trunk.y - 2, trunk.y + 3):
		for x in range(trunk.x - 2, trunk.x + 3):
			if not occ.is_walkable(Vector2i(x, y)):
				blocked += 1
	var far: Vector2i = OccupancyScript.from_world(tree.global_position + Vector2(160.0, 0.0))
	tree.queue_free()
	if blocked < 1:
		return _fail("US-056: tree trunk must block occupancy near the origin")
	if not occ.is_walkable(far):
		return _fail("US-056: tree occupancy must stay near the trunk, not the canopy")
	return true


func _assert_collider_stamp_uses_cell_centers(finder: Node) -> bool:
	var occ = OccupancyScript.new()
	occ.region = Rect2i(Vector2i.ZERO, Vector2i(8, 8))
	for y in range(8):
		for x in range(8):
			occ.walkable[Vector2i(x, y)] = true
	var foot := Rect2(Vector2(32.0, 80.0), Vector2(128.0, 44.0))
	occ._block_world_rect(foot)
	var blocked := 0
	var north_of_foot := 0
	for y in range(8):
		for x in range(8):
			if occ.is_walkable(Vector2i(x, y)):
				continue
			blocked += 1
			var c: Vector2 = OccupancyScript.to_world_center(Vector2i(x, y))
			if c.y < foot.position.y:
				north_of_foot += 1
	if blocked < 1:
		return _fail("US-056: south-foot collider must block cells whose centers sit in it")
	if north_of_foot > 0:
		return _fail("US-056: south-foot collider must not block cells north of the foot (%d)" % north_of_foot)
	return true


func _assert_los_goes_straight(finder: Node) -> bool:
	var open: Array[Vector2i] = []
	for y in range(5):
		for x in range(5):
			open.append(Vector2i(x, y))
	var no_cliffs: Array[Vector2i] = []
	finder.configure_test_map(Rect2i(Vector2i.ZERO, Vector2i(5, 5)), open, no_cliffs)
	var body := Node2D.new()
	add_child(body)
	var start: Vector2 = finder.cell_center(Vector2i(0, 0))
	var goal: Vector2 = finder.cell_center(Vector2i(3, 2))
	body.global_position = start
	var follower = PathFollowerScript.new()
	var vel: Vector2 = follower.velocity_toward(body, goal, 140.0, 0.016, false)
	body.queue_free()
	var want: Vector2 = (goal - start).normalized()
	if vel.length() < 1.0:
		return _fail("US-056: LOS to the goal must not stand still")
	if vel.normalized().dot(want) < 0.99:
		return _fail("US-056: LOS to the goal must steer straight at it, vel=%s want=%s" % [vel, want])

	var blocked: Array[Vector2i] = []
	for y in range(5):
		for x in range(5):
			if x == 2 and y < 4:
				continue
			blocked.append(Vector2i(x, y))
	finder.configure_test_map(Rect2i(Vector2i.ZERO, Vector2i(5, 5)), blocked, no_cliffs)
	var charger := Node2D.new()
	add_child(charger)
	charger.global_position = finder.cell_center(Vector2i(1, 2))
	var around = PathFollowerScript.new()
	var charge: Vector2 = around.velocity_toward(charger, finder.cell_center(Vector2i(3, 2)), 140.0, 0.016, false)
	charger.queue_free()
	if charge.normalized().dot(Vector2.RIGHT) > 0.9:
		return _fail("US-056: must not charge a wall just because the goal is on the other side")
	return true


func _assert_dungeon_exit_path(finder: Node) -> bool:
	var layout := DungeonLayoutData.new()
	var room: Array[Vector2i] = []
	for y in range(2, 5):
		for x in range(6, 9):
			room.append(Vector2i(x, y))
	layout.walkable_cells = room
	layout.entrance_cell = Vector2i(8, 3)
	layout.exit_cell = Vector2i(6, 3)
	var room_points: Array[Dictionary] = []
	for cell in room:
		room_points.append({"x": cell.x, "y": cell.y})
	layout.room_regions = [{"role": "exit", "cells": room_points}]
	var builder := TilePlacementBuilder.new()
	layout.tile_placements = builder.build(layout, DungeonGrid.set_from(layout.walkable_cells))

	var room_set: Dictionary = DungeonGrid.set_from(layout.walkable_cells)
	var walls: Dictionary = {}
	var floors: Dictionary = {}
	var door: Vector2i = DungeonGrid.SENTINEL
	for placement in layout.tile_placements:
		var cell: Vector2i = DungeonGrid.cell_from(placement.get("position", {}))
		var role: String = str(placement.get("tileRole", ""))
		if role == "wall":
			walls[cell] = true
		elif role == "floor" or role == "entrance" or role == "exit":
			floors[cell] = true
			if not room_set.has(cell):
				door = cell
	if door == DungeonGrid.SENTINEL:
		return _fail("US-056: expected an exit door floor outside walkable_cells")
	if walls.has(door):
		return _fail("US-056: exit door must not be a wall tile")

	var dungeon_walk: Dictionary = {}
	for cell in layout.walkable_cells:
		dungeon_walk[cell] = true
	for cell in floors:
		dungeon_walk[cell] = true

	var min_c: Vector2i = room[0]
	var max_c: Vector2i = room[0]
	for cell in room:
		min_c.x = mini(min_c.x, cell.x)
		min_c.y = mini(min_c.y, cell.y)
		max_c.x = maxi(max_c.x, cell.x)
		max_c.y = maxi(max_c.y, cell.y)
	var aabb := Rect2i(min_c - Vector2i.ONE, (max_c - min_c) + Vector2i(3, 3))
	var interior := Rect2i(Vector2i.ZERO, Vector2i(12, 8))
	var overworld := Vector2i(2, 3)
	if not interior.has_point(door) or not interior.has_point(overworld):
		return _fail("US-056: interior must contain the exit door and overworld")
	if not OccupancyScript._world_tile_walkable(door, interior, dungeon_walk, walls, door):
		return _fail("US-056: exit door must be occupancy-walkable")
	if not OccupancyScript._world_tile_walkable(overworld, interior, dungeon_walk, walls, door):
		return _fail("US-056: overworld west of the dungeon must be occupancy-walkable")
	if not OccupancyScript._world_tile_walkable(Vector2i(5, 2), interior, dungeon_walk, walls, door):
		return _fail("US-056: wall tiles stamp walkable underlay; the foot collider is the blocker")
	if not OccupancyScript._world_tile_walkable(Vector2i(1, 3), interior, dungeon_walk, walls, door):
		return _fail("US-056: generation blocked_cells leftover must not seal overworld")
	if not OccupancyScript._world_tile_walkable(Vector2i(4, 3), interior, dungeon_walk, walls, door):
		return _fail("US-056: overworld cell at the exit door must stay open")
	var walls_hole: Dictionary = walls.duplicate()
	walls_hole.erase(Vector2i(8, 5))
	if OccupancyScript._world_tile_walkable(Vector2i(8, 5), interior, dungeon_walk, walls_hole, door):
		return _fail("US-056: south shell hole must stay sealed so gremlins use the exit")

	var occupancy = OccupancyScript.new()
	occupancy.dungeon_floors = dungeon_walk
	occupancy.exit_door = door
	occupancy.exit_landing = Vector2i(4, 3)
	occupancy._paint_world_tiles(interior, aabb, dungeon_walk, walls, door)
	var door_path: Vector2i = OccupancyScript.layout_path_origin(door)
	if not occupancy.is_walkable(door_path):
		return _fail("US-056: 64px occupancy must stamp the exit door")
	var room_mid: Vector2i = OccupancyScript.layout_path_origin(Vector2i(7, 3))
	if not occupancy.is_walkable(room_mid):
		return _fail("US-056: room interior must stay walkable")
	if not _assert_wall_foot_occupancy(occupancy, walls):
		return false

	var painted: Array[Vector2i] = []
	for cell in occupancy.walkable:
		painted.append(cell)
	var no_cliffs: Array[Vector2i] = []
	finder.configure_test_map(occupancy.region, painted, no_cliffs)
	finder.occupancy.dungeon_floors = dungeon_walk
	finder.occupancy.exit_door = door
	finder.occupancy.exit_landing = Vector2i(4, 3)
	var start: Vector2i = OccupancyScript.layout_path_origin(Vector2i(8, 3))
	var goal: Vector2i = OccupancyScript.layout_path_origin(overworld)
	var path: Array[Vector2i] = finder.find_path(start, goal, false)
	if path.is_empty():
		return _fail("US-056: dungeon-to-overworld path is empty (gremlins trapped inside)")
	var used_door := false
	for cell in path:
		var world_cell: Vector2i = OccupancyScript.world_cell_of_path(cell)
		if world_cell == door:
			used_door = true
	if not used_door:
		return _fail("US-056: dungeon-to-overworld path must use the exit door")
	var south_goal: Vector2i = OccupancyScript.layout_path_origin(Vector2i(8, 6))
	var south_path: Array[Vector2i] = finder.find_path(start, south_goal, false)
	if south_path.is_empty():
		return _fail("US-056: inside-to-south-overworld path is empty")
	var used_south_door := false
	for cell in south_path:
		if OccupancyScript.world_cell_of_path(cell) == door:
			used_south_door = true
	if not used_south_door:
		return _fail("US-056: leaving toward the south must still use the exit door")
	var room_world: Vector2 = finder.cell_center(start)
	var grass_world: Vector2 = finder.cell_center(south_goal)
	if bool(finder.world_segment_walkable(room_world, grass_world, false)):
		return _fail("US-056: must not have line of sight through a south wall")
	var charger := Node2D.new()
	add_child(charger)
	charger.global_position = room_world
	var through = PathFollowerScript.new()
	var charge: Vector2 = through.velocity_toward(charger, grass_world, 140.0, 0.016, false)
	charger.queue_free()
	var southward: Vector2 = (grass_world - room_world).normalized()
	if charge.length() > 1.0 and charge.normalized().dot(southward) > 0.9:
		return _fail("US-056: must not charge through a south wall, vel=%s" % charge)
	return true


func _assert_wall_foot_occupancy(occupancy, walls: Dictionary) -> bool:
	var south_wall := Vector2i(8, 5)
	if not walls.has(south_wall):
		return _fail("US-056: expected a south wall at (8,5)")
	var cube: Rect2 = OccupancyScript.layout_sprite_rect(south_wall)
	var cap: Vector2 = cube.position + Vector2(cube.size.x * 0.5, 16.0)
	var foot: Vector2 = cube.position + Vector2(cube.size.x * 0.5, cube.size.y - 16.0)
	var grass: Vector2 = cube.position + Vector2(cube.size.x * 0.5, cube.size.y + 16.0)
	if not occupancy.is_walkable(OccupancyScript.from_world(cap)):
		return _fail("US-056: 3/4 wall cap must stay walkable so art can sit above occupancy")
	if occupancy.is_walkable(OccupancyScript.from_world(foot)):
		return _fail("US-056: south wall foot must be blocked")
	if not occupancy.is_walkable(OccupancyScript.from_world(grass)):
		return _fail("US-056: grass south of a wall sprite must stay walkable")
	var north_of_south: Vector2 = cube.position + Vector2(cube.size.x * 0.5, -16.0)
	if not occupancy.is_walkable(OccupancyScript.from_world(north_of_south)):
		return _fail("US-056: floor immediately north of a south wall cube must stay walkable")
	return true


func _assert_string_pull(finder: Node) -> bool:
	var open_line: Array[Vector2i] = []
	for x in range(8):
		open_line.append(Vector2i(x, 0))
	var no_cliffs: Array[Vector2i] = []
	finder.configure_test_map(Rect2i(Vector2i.ZERO, Vector2i(8, 1)), open_line, no_cliffs)
	var hall := Node2D.new()
	add_child(hall)
	hall.global_position = finder.cell_center(Vector2i(2, 0))
	var hall_follow = PathFollowerScript.new()
	var hall_vel: Vector2 = hall_follow.velocity_toward(hall, finder.cell_center(Vector2i(7, 0)), 140.0, 0.016, false)
	hall.queue_free()
	if hall_vel.length() < 1.0 or hall_vel.x <= 0.0:
		return _fail("US-056: standing on a hallway cell center must keep moving toward the goal, vel=%s" % hall_vel)

	var region := Rect2i(Vector2i.ZERO, Vector2i(9, 12))
	var walkable: Array[Vector2i] = []
	for y in range(12):
		for x in range(9):
			if x == 4 and y < 9:
				continue
			walkable.append(Vector2i(x, y))
	var cliffs: Array[Vector2i] = []
	finder.configure_test_map(region, walkable, cliffs)

	var a: Vector2 = finder.cell_center(Vector2i(3, 8))
	var c: Vector2 = finder.cell_center(Vector2i(4, 9))
	if bool(finder.world_segment_walkable(a, c, false)):
		return _fail("US-056: diagonal shortcut around a wall corner must be blocked")
	if not bool(finder.world_segment_walkable(a, finder.cell_center(Vector2i(3, 9)), false)):
		return _fail("US-056: cardinal step off a wall face must stay walkable")

	var body := Node2D.new()
	add_child(body)
	body.global_position = finder.cell_center(Vector2i(3, 5))
	var follower = PathFollowerScript.new()
	var start_y: float = body.global_position.y
	var reversed := 0
	var stopped := 0
	for _i in range(40):
		var vel: Vector2 = follower.velocity_toward(body, finder.cell_center(Vector2i(7, 5)), 140.0, 0.016, false)
		if vel.length() < 1.0:
			stopped += 1
		if vel.y < -8.0:
			reversed += 1
		body.global_position += vel * 0.016
	var end: Vector2 = body.global_position
	body.queue_free()
	if stopped > 2:
		return _fail("US-056: follow stopped on intermediate cells %d ticks" % stopped)
	if reversed > 2:
		return _fail("US-056: follow reversed at the wall %d ticks" % reversed)
	if end.y < start_y + 24.0:
		return _fail("US-056: follow must progress around the wall, y %s -> %s" % [start_y, end.y])
	return true


func _assert_exit_portal_follow(finder: Node) -> bool:
	var region := Rect2i(Vector2i.ZERO, Vector2i(16, 16))
	var walkable: Array[Vector2i] = []
	for y in range(4, 10):
		for x in range(8, 14):
			walkable.append(Vector2i(x, y))
	for y in range(6, 8):
		for x in range(4, 8):
			walkable.append(Vector2i(x, y))
	for y in range(16):
		for x in range(6):
			walkable.append(Vector2i(x, y))
	var no_cliffs: Array[Vector2i] = []
	finder.configure_test_map(region, walkable, no_cliffs)
	var scale: int = OccupancyScript.subdiv()
	var door_path := Vector2i(8, 6)
	var land_path := Vector2i(5, 6)
	var floors: Dictionary = {}
	for cell in walkable:
		if cell.x >= 8:
			floors[Vector2i(int(floor(float(cell.x) / float(scale))), int(floor(float(cell.y) / float(scale))))] = true
	floors[Vector2i(int(floor(float(door_path.x) / float(scale))), int(floor(float(door_path.y) / float(scale))))] = true
	finder.occupancy.dungeon_floors = floors
	finder.occupancy.exit_door = Vector2i(int(floor(float(door_path.x) / float(scale))), int(floor(float(door_path.y) / float(scale))))
	finder.occupancy.exit_landing = Vector2i(int(floor(float(land_path.x) / float(scale))), int(floor(float(land_path.y) / float(scale))))
	if not bool(finder.is_portal_pair(door_path, land_path)):
		return _fail("US-056: door %s and landing %s must be a portal pair" % [door_path, land_path])

	var routed: Array[Vector2i] = finder.find_path(Vector2i(10, 6), Vector2i(2, 6), false)
	if routed.is_empty():
		return _fail("US-056: inside-to-overworld path is empty")
	var saw_portal := false
	for i in range(routed.size() - 1):
		if bool(finder.is_portal_pair(routed[i], routed[i + 1])):
			saw_portal = true
			break
	if not saw_portal:
		return _fail("US-056: inside-to-overworld A* must pass the exit portal")

	var body := Node2D.new()
	add_child(body)
	body.global_position = finder.cell_center(Vector2i(10, 6))
	var follower = PathFollowerScript.new()
	var start_x: float = body.global_position.x
	for _i in range(20):
		var vel: Vector2 = follower.velocity_toward(body, finder.cell_center(Vector2i(2, 6)), 140.0, 0.016, false)
		if vel.length() < 1.0:
			body.queue_free()
			return _fail("US-056: follow must not stop in a cell while leaving the dungeon")
		body.global_position += vel * 0.016
	var end_x: float = body.global_position.x
	body.queue_free()
	if end_x >= start_x:
		return _fail("US-056: leaving the dungeon must move west toward the landing, x %s -> %s" % [start_x, end_x])
	return true


func _uses_gap(path: Array[Vector2i]) -> bool:
	for cell in path:
		if cell.y >= 8:
			return true
	return false


func _fail(message: String) -> bool:
	push_error(message)
	get_tree().quit(1)
	return false
