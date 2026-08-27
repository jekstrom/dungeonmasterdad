class_name HallwayRegionClassifier extends RefCounted

const DungeonGrid = preload("res://scripts/procedural_dungeon/dungeon_grid.gd")

func classify_hallway_regions(all_walkable_cells: Array[Vector2i], room_cells: Array[Vector2i]) -> Array[Dictionary]:
	var walkable_set: Dictionary = DungeonGrid.set_from(all_walkable_cells)
	var room_set: Dictionary = DungeonGrid.set_from(room_cells)
	var hallway_set: Dictionary = {}
	for cell in walkable_set.keys():
		if not room_set.has(cell):
			hallway_set[cell] = true

	var regions: Array[Dictionary] = []
	var visited: Dictionary = {}
	var region_index: int = 0
	for start_cell in hallway_set.keys():
		if visited.has(start_cell):
			continue
		var component: Array[Vector2i] = DungeonGrid.flood_fill(start_cell, hallway_set, visited)
		if component.is_empty():
			continue
		regions.append({
			"hallwayId": "hallway_%d" % region_index,
			"cells": DungeonGrid.points_to_dicts(component)
		})
		region_index += 1
	return regions
