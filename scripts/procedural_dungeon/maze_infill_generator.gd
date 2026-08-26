class_name MazeInfillGenerator extends RefCounted

func generate_infill(bounds: Rect2i, existing_walkable_cells: Array[Vector2i], seed: int) -> Dictionary:
	var existing_set: Dictionary = {}
	for cell in existing_walkable_cells:
		existing_set[cell] = true

	if existing_walkable_cells.is_empty():
		return {
			"ok": true,
			"hallway_cells": []
		}

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed

	var branch_starts: int = mini(6, maxi(2, existing_walkable_cells.size() / 10))
	var infill_set: Dictionary = {}

	for _i in range(branch_starts):
		var start_index: int = rng.randi_range(0, existing_walkable_cells.size() - 1)
		var current: Vector2i = existing_walkable_cells[start_index]
		var branch_length: int = rng.randi_range(6, 16)

		for _step in range(branch_length):
			var direction: Vector2i = _random_cardinal_direction(rng)
			var candidate: Vector2i = current + direction
			if not bounds.has_point(candidate):
				continue

			if existing_set.has(candidate):
				current = candidate
				continue

			infill_set[candidate] = true
			current = candidate

	var hallway_cells: Array[Vector2i] = []
	for cell in infill_set.keys():
		hallway_cells.append(cell)

	return {
		"ok": true,
		"hallway_cells": hallway_cells
	}

func _random_cardinal_direction(rng: RandomNumberGenerator) -> Vector2i:
	var directions: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]
	return directions[rng.randi_range(0, directions.size() - 1)]
