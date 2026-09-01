extends Node

func _ready() -> void:
	if MapBounds.interior_from_dungeon_aabb(Rect2i()) != Rect2i():
		push_error("US-024 T004: empty dungeon AABB must yield empty interior")
		get_tree().quit(1)
		return

	var dungeon_24 := Rect2i(0, 0, 24, 24)
	var interior_24: Rect2i = MapBounds.interior_from_dungeon_aabb(dungeon_24)
	if interior_24.size != Vector2i(48, 48):
		push_error("US-024 T004: 24x24 dungeon should yield 48x48 interior, got %s" % interior_24.size)
		get_tree().quit(1)
		return
	if interior_24.size.x * interior_24.size.y < 4 * 24 * 24:
		push_error("US-024 T004: interior area must be >= 4x dungeon AABB")
		get_tree().quit(1)
		return
	if interior_24.end.x != dungeon_24.end.x:
		push_error("US-024 T004: interior must be flush to dungeon east edge")
		get_tree().quit(1)
		return
	if not _contains_rect(interior_24, dungeon_24):
		push_error("US-024 T004: dungeon AABB must sit inside interior")
		get_tree().quit(1)
		return
	var north_pad_24: int = dungeon_24.position.y - interior_24.position.y
	var south_pad_24: int = interior_24.end.y - dungeon_24.end.y
	if north_pad_24 != 12 or south_pad_24 != 12:
		push_error("US-024 T004: 24x24 dungeon should be vertically centered, pads %d/%d" % [north_pad_24, south_pad_24])
		get_tree().quit(1)
		return

	var dungeon_8x6 := Rect2i(5, 10, 8, 6)
	var interior_8x6: Rect2i = MapBounds.interior_from_dungeon_aabb(dungeon_8x6)
	if interior_8x6.size != Vector2i(16, 16):
		push_error("US-024 T004: 8x6 dungeon should yield 16x16 square interior, got %s" % interior_8x6.size)
		get_tree().quit(1)
		return
	if interior_8x6.end.x != dungeon_8x6.end.x:
		push_error("US-024 T004: 8x6 interior east flush failed")
		get_tree().quit(1)
		return
	if not _contains_rect(interior_8x6, dungeon_8x6):
		push_error("US-024 T004: 8x6 dungeon not inside interior")
		get_tree().quit(1)
		return
	if interior_8x6.size.x != interior_8x6.size.y:
		push_error("US-024 T004: interior must be square when width>=height plan, got %s" % interior_8x6.size)
		get_tree().quit(1)
		return
	var north_pad_8: int = dungeon_8x6.position.y - interior_8x6.position.y
	var south_pad_8: int = interior_8x6.end.y - dungeon_8x6.end.y
	if north_pad_8 != 5 or south_pad_8 != 5:
		push_error("US-024 T004: 8x6 should be vertically centered in 16x16, pads %d/%d" % [north_pad_8, south_pad_8])
		get_tree().quit(1)
		return

	var dungeon_wide := Rect2i(0, 0, 24, 1)
	var interior_wide: Rect2i = MapBounds.interior_from_dungeon_aabb(dungeon_wide)
	if interior_wide.size.y < 3:
		push_error("US-024 T004: height-1 dungeon needs >=1 cell pad north and south")
		get_tree().quit(1)
		return
	if dungeon_wide.position.y - interior_wide.position.y < 1:
		push_error("US-024 T004: missing north pad")
		get_tree().quit(1)
		return
	if interior_wide.end.y - dungeon_wide.end.y < 1:
		push_error("US-024 T004: missing south pad")
		get_tree().quit(1)
		return
	if interior_wide.size.x * interior_wide.size.y < 4 * 24 * 1:
		push_error("US-024 T004: padded interior still needs >= 4x area")
		get_tree().quit(1)
		return
	if not _contains_rect(interior_wide, dungeon_wide):
		push_error("US-024 T004: padded dungeon not inside interior")
		get_tree().quit(1)
		return

	var bounds := MapBounds.new()
	bounds.commit_interior(interior_24)
	if bounds.is_cliff_cell(Vector2i(12, 12)):
		push_error("US-024 T004: dungeon cell must not be a cliff")
		get_tree().quit(1)
		return
	if not bounds.is_interior_cell(Vector2i(0, 0)) or not bounds.is_interior_cell(Vector2i(23, 23)):
		push_error("US-024 T004: dungeon AABB cells must be interior")
		get_tree().quit(1)
		return
	if not bounds.is_cliff_cell(Vector2i(interior_24.position.x, interior_24.position.y - 1)):
		push_error("US-024 T004: cell north of interior must be cliff, not overlapping dungeon")
		get_tree().quit(1)
		return

	print("US-024 T004 interior size test passed")
	get_tree().quit(0)

func _contains_rect(outer: Rect2i, inner: Rect2i) -> bool:
	return (
		inner.position.x >= outer.position.x
		and inner.position.y >= outer.position.y
		and inner.end.x <= outer.end.x
		and inner.end.y <= outer.end.y
	)
