class_name LayoutComposer extends RefCounted

var _hallway_classifier: HallwayRegionClassifier = HallwayRegionClassifier.new()

func compose(
	room_regions: Array[Dictionary],
	hallway_cells: Array[Vector2i],
	deadend_regions: Array[Dictionary]
) -> Dictionary:
	var merged_rooms: Array[Dictionary] = []
	merged_rooms.append_array(room_regions)
	merged_rooms.append_array(deadend_regions)

	var room_set: Dictionary = {}
	var room_cells: Array[Vector2i] = []
	for region in merged_rooms:
		for point in region.get("cells", []):
			var cell: Vector2i = DungeonGrid.cell_from(point)
			if room_set.has(cell):
				continue
			room_set[cell] = true
			room_cells.append(cell)

	var walkable_set: Dictionary = {}
	for cell in room_cells:
		walkable_set[cell] = true
	for cell in hallway_cells:
		if not room_set.has(cell):
			walkable_set[cell] = true

	var walkable_cells: Array[Vector2i] = []
	for cell in walkable_set.keys():
		walkable_cells.append(cell)

	return {
		"walkable_cells": walkable_cells,
		"room_regions": merged_rooms,
		"hallway_regions": _hallway_classifier.classify_hallway_regions(walkable_cells, room_cells)
	}
