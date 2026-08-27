class_name HallwayCarver extends RefCounted

const DungeonGrid = preload("res://scripts/procedural_dungeon/dungeon_grid.gd")

func carve_graph_hallways(rooms_by_id: Dictionary, graph_edges: Array, bounds: Rect2i) -> Dictionary:
	var unique_cells: Dictionary = {}
	for edge in graph_edges:
		if not (edge is Array) or edge.size() < 2:
			continue
		var from_center: Vector2i = _center_of(rooms_by_id, str(edge[0]))
		var to_center: Vector2i = _center_of(rooms_by_id, str(edge[1]))
		for cell in DungeonGrid.carve_l(from_center, to_center, bounds):
			unique_cells[cell] = true

	var hallway_cells: Array[Vector2i] = []
	for cell in unique_cells.keys():
		hallway_cells.append(cell)
	return {
		"ok": true,
		"hallway_cells": hallway_cells
	}


func _center_of(rooms_by_id: Dictionary, room_id: String) -> Vector2i:
	if not rooms_by_id.has(room_id):
		return Vector2i.ZERO
	var entry: Variant = rooms_by_id[room_id]
	if entry is Vector2i:
		return entry
	if entry is Dictionary:
		return DungeonGrid.cell_from(entry.get("center", entry))
	return Vector2i.ZERO
