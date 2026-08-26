class_name LayoutComposer extends RefCounted

const HallwayRegionClassifier = preload("res://scripts/procedural_dungeon/hallway_region_classifier.gd")

var _hallway_classifier: HallwayRegionClassifier = HallwayRegionClassifier.new()

func compose(
	room_regions: Array[Dictionary],
	hallway_cells: Array[Vector2i],
	deadend_regions: Array[Dictionary]
) -> Dictionary:
	var merged_rooms: Array[Dictionary] = []
	for region in room_regions:
		merged_rooms.append(region)
	for region in deadend_regions:
		merged_rooms.append(region)

	var room_set: Dictionary = {}
	var room_cells: Array[Vector2i] = []
	for region in merged_rooms:
		for point in region.get("cells", []):
			var cell: Vector2i = _cell_from(point)
			if room_set.has(cell):
				continue
			room_set[cell] = true
			room_cells.append(cell)

	var walkable_set: Dictionary = {}
	for cell in room_cells:
		walkable_set[cell] = true
	for cell in hallway_cells:
		if room_set.has(cell):
			continue
		walkable_set[cell] = true

	var walkable_cells: Array[Vector2i] = []
	for cell in walkable_set.keys():
		walkable_cells.append(cell)

	var hallway_regions: Array[Dictionary] = _hallway_classifier.classify_hallway_regions(
		walkable_cells,
		room_cells
	)

	return {
		"walkable_cells": walkable_cells,
		"room_regions": merged_rooms,
		"hallway_regions": hallway_regions
	}

func _cell_from(raw_value: Variant) -> Vector2i:
	if raw_value is Vector2i:
		return raw_value
	if raw_value is Dictionary:
		return Vector2i(int(raw_value.get("x", 0)), int(raw_value.get("y", 0)))
	return Vector2i.ZERO
