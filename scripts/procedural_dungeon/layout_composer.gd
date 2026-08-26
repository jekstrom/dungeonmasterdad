class_name LayoutComposer extends RefCounted

const RoomRegionClassifier = preload("res://scripts/procedural_dungeon/room_region_classifier.gd")
const HallwayRegionClassifier = preload("res://scripts/procedural_dungeon/hallway_region_classifier.gd")

var _room_classifier: RoomRegionClassifier = RoomRegionClassifier.new()
var _hallway_classifier: HallwayRegionClassifier = HallwayRegionClassifier.new()

func compose(
	base_room_cells: Array[Vector2i],
	base_hallway_cells: Array[Vector2i],
	infill_hallway_cells: Array[Vector2i]
) -> Dictionary:
	var walkable_set: Dictionary = {}
	for cell in base_room_cells:
		walkable_set[cell] = true
	for cell in base_hallway_cells:
		walkable_set[cell] = true
	for cell in infill_hallway_cells:
		walkable_set[cell] = true

	var walkable_cells: Array[Vector2i] = []
	for cell in walkable_set.keys():
		walkable_cells.append(cell)

	var room_regions: Array[Dictionary] = _room_classifier.classify_room_regions(base_room_cells)
	var hallway_regions: Array[Dictionary] = _hallway_classifier.classify_hallway_regions(walkable_cells, base_room_cells)

	return {
		"walkable_cells": walkable_cells,
		"room_regions": room_regions,
		"hallway_regions": hallway_regions
	}
