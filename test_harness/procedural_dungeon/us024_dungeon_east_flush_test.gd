extends Node

func _ready() -> void:
	var dungeon := Rect2i(5, 10, 8, 6)
	var delta: Vector2i = MapBounds.cell_translation_for_east_flush(dungeon)
	var shifted := Rect2i(dungeon.position + delta, dungeon.size)
	var interior: Rect2i = MapBounds.interior_from_dungeon_aabb(shifted)
	if interior.position != Vector2i.ZERO:
		push_error("US-024 T005: east-flush translation should place interior at origin, got %s" % interior.position)
		get_tree().quit(1)
		return
	if shifted.end.x != interior.end.x:
		push_error("US-024 T005: dungeon AABB must be flush to interior east edge")
		get_tree().quit(1)
		return
	if not _contains_rect(interior, shifted):
		push_error("US-024 T005: translated dungeon must sit inside interior")
		get_tree().quit(1)
		return

	var bounds := MapBounds.new()
	bounds.commit_interior(interior)
	for y in range(shifted.position.y, shifted.end.y):
		for x in range(shifted.position.x, shifted.end.x):
			if bounds.is_cliff_cell(Vector2i(x, y)):
				push_error("US-024 T005: dungeon cell %s overlaps a cliff" % Vector2i(x, y))
				get_tree().quit(1)
				return
			if not bounds.is_interior_cell(Vector2i(x, y)):
				push_error("US-024 T005: dungeon cell %s is not interior" % Vector2i(x, y))
				get_tree().quit(1)
				return

	var layout := DungeonLayoutData.new()
	layout.layout_id = "t005"
	layout.entrance_cell = Vector2i(12, 12)
	layout.exit_cell = Vector2i(6, 11)
	layout.walkable_cells = [Vector2i(12, 12), Vector2i(6, 11), Vector2i(8, 11)]
	layout.tile_placements = [{"position": {"x": 12, "y": 12}, "tileRole": "entrance"}]
	layout.monster_spawns = [{"position": {"x": 8, "y": 11}}]
	layout.room_regions = [{"role": "start", "cells": [{"x": 12, "y": 12}]}]
	layout.translate_cells(Vector2i(3, -4))
	if layout.entrance_cell != Vector2i(15, 8) or layout.exit_cell != Vector2i(9, 7):
		push_error("US-024 T005: layout cell translation failed")
		get_tree().quit(1)
		return
	if layout.walkable_cells[0] != Vector2i(15, 8):
		push_error("US-024 T005: walkable cells not translated")
		get_tree().quit(1)
		return
	if int(layout.tile_placements[0]["position"]["x"]) != 15:
		push_error("US-024 T005: tile placements not translated")
		get_tree().quit(1)
		return
	if int(layout.monster_spawns[0]["position"]["y"]) != 7:
		push_error("US-024 T005: monster spawns not translated")
		get_tree().quit(1)
		return

	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager == null or not manager.has_method("generate_dungeon_contract"):
		push_error("US-024 T005: DungeonGenerationManager missing")
		get_tree().quit(1)
		return
	var response: Dictionary = manager.generate_dungeon_contract({
		"requestId": "t005-contract-untranslated",
		"startPosition": {"x": 2, "y": 2},
		"exitPosition": {"x": 16, "y": 16},
		"generationBounds": {"origin": {"x": 0, "y": 0}, "size": {"x": 24, "y": 24}},
		"roomSize": 5,
		"roomCount": 3
	}, 1)
	if not response.get("ok", false):
		push_error("US-024 T005: contract generate failed %s" % response)
		get_tree().quit(1)
		return
	var data: Dictionary = response.get("data", {})
	var entrance: Dictionary = data.get("entrance", {})
	if int(entrance.get("x", -1)) != 2 or int(entrance.get("y", -1)) != 2:
		push_error("US-024 T005: contract tests must keep generator-space entrance cells")
		get_tree().quit(1)
		return

	print("US-024 T005 dungeon east flush test passed")
	get_tree().quit(0)

func _contains_rect(outer: Rect2i, inner: Rect2i) -> bool:
	return (
		inner.position.x >= outer.position.x
		and inner.position.y >= outer.position.y
		and inner.end.x <= outer.end.x
		and inner.end.y <= outer.end.y
	)
