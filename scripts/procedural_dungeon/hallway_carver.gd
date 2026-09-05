class_name HallwayCarver extends RefCounted

const MazeCorridorCarverScript = preload("res://scripts/procedural_dungeon/maze_corridor_carver.gd")

var _maze = MazeCorridorCarverScript.new()

func carve_graph_hallways(
	rooms_by_id: Dictionary,
	graph_edges: Array,
	bounds: Rect2i,
	generation_seed: int = 1,
	_braid_rate: float = DungeonConstants.DEFAULT_BRAID_RATE
) -> Dictionary:
	var unique_cells: Dictionary = {}
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = generation_seed
	var room_sets: Dictionary = {}
	var all_rooms: Dictionary = {}
	for room_id in rooms_by_id.keys():
		var cell_set: Dictionary = _cell_set_of(rooms_by_id, str(room_id))
		room_sets[str(room_id)] = cell_set
		for cell in cell_set.keys():
			all_rooms[cell] = true

	for edge in graph_edges:
		if not (edge is Array) or edge.size() < 2:
			continue
		var from_id: String = str(edge[0])
		var to_id: String = str(edge[1])
		var from_set: Dictionary = room_sets.get(from_id, {})
		var to_set: Dictionary = room_sets.get(to_id, {})
		var from_center: Vector2i = _center_of(rooms_by_id, from_id)
		var to_center: Vector2i = _center_of(rooms_by_id, to_id)
		var from_out: Vector2i = _outside_door(from_set, to_center, bounds, all_rooms)
		var to_out: Vector2i = _outside_door(to_set, from_center, bounds, all_rooms)
		if from_out == DungeonGrid.SENTINEL or to_out == DungeonGrid.SENTINEL:
			continue
		var blocked: Dictionary = all_rooms.duplicate()
		for cell in _room_adjacent(all_rooms, bounds).keys():
			if cell == from_out or cell == to_out:
				continue
			blocked[cell] = true
		var path: Array[Vector2i] = _maze.carve_between(from_out, to_out, bounds, blocked, rng)
		if path.is_empty() or not _path_reaches(path, to_out):
			continue
		for cell in path:
			if all_rooms.has(cell):
				continue
			unique_cells[cell] = true

	var hallway_cells: Array[Vector2i] = []
	for cell in unique_cells.keys():
		hallway_cells.append(cell)
	return {
		"ok": true,
		"hallway_cells": hallway_cells
	}


func _outside_door(
	room_set: Dictionary,
	toward: Vector2i,
	bounds: Rect2i,
	all_rooms: Dictionary
) -> Vector2i:
	var best: Vector2i = DungeonGrid.SENTINEL
	var best_d: int = 1_000_000
	for cell in room_set.keys():
		for neighbor in DungeonGrid.neighbors(cell):
			if not bounds.has_point(neighbor):
				continue
			if all_rooms.has(neighbor):
				continue
			var d: int = absi(neighbor.x - toward.x) + absi(neighbor.y - toward.y)
			if d < best_d:
				best_d = d
				best = neighbor
	return best


func _room_adjacent(all_rooms: Dictionary, bounds: Rect2i) -> Dictionary:
	var result: Dictionary = {}
	for cell in all_rooms.keys():
		for neighbor in DungeonGrid.neighbors(cell):
			if not bounds.has_point(neighbor):
				continue
			if all_rooms.has(neighbor):
				continue
			result[neighbor] = true
	return result


func _path_reaches(path: Array[Vector2i], goal: Vector2i) -> bool:
	for cell in path:
		if cell == goal:
			return true
	return false


func _cell_set_of(rooms_by_id: Dictionary, room_id: String) -> Dictionary:
	var result: Dictionary = {}
	if not rooms_by_id.has(room_id):
		return result
	var entry: Variant = rooms_by_id[room_id]
	if entry is Dictionary:
		var raw: Variant = entry.get("cells", [])
		if raw is Array:
			for item in raw:
				result[DungeonGrid.cell_from(item)] = true
		if result.is_empty():
			result[DungeonGrid.cell_from(entry.get("center", entry))] = true
	elif entry is Vector2i:
		result[entry] = true
	return result


func _center_of(rooms_by_id: Dictionary, room_id: String) -> Vector2i:
	if not rooms_by_id.has(room_id):
		return Vector2i.ZERO
	var entry: Variant = rooms_by_id[room_id]
	if entry is Vector2i:
		return entry
	if entry is Dictionary:
		return DungeonGrid.cell_from(entry.get("center", entry))
	return Vector2i.ZERO
