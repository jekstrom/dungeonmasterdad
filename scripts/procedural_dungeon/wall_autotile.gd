class_name WallAutotile extends RefCounted

# cubicle_stone_wall.png: centered H/V/T/+ plus inner corners 24-27. Skip 4.

static func wall_type(cell: Vector2i, walkable_set: Dictionary) -> int:
	# Type 2 is the vertical collider so east/west occupancy edges actually block.
	if walkable_set.has(cell + Vector2i.RIGHT) or walkable_set.has(cell + Vector2i.LEFT):
		return 2
	return 1


static func wall_frame(cell: Vector2i, walkable_set: Dictionary, wall_set: Dictionary) -> int:
	var n: bool = wall_set.has(cell + Vector2i.UP)
	var e: bool = wall_set.has(cell + Vector2i.RIGHT)
	var s: bool = wall_set.has(cell + Vector2i.DOWN)
	var w: bool = wall_set.has(cell + Vector2i.LEFT)
	var h_count: int = int(e) + int(w)
	var v_count: int = int(n) + int(s)
	var count: int = h_count + v_count
	if count == 4:
		return 21
	if count == 3:
		if not n:
			return 19
		if not e:
			return 20
		if not s:
			return 17
		return 18
	if h_count == 2 and v_count == 0:
		return 0
	if v_count == 2 and h_count == 0:
		return 1
	if h_count == 1 and v_count == 1:
		return _corner_frame(cell, n, e, s, w, walkable_set)
	if count == 1:
		if e:
			return 7
		if w:
			return 8
		if s:
			return 9
		return 10
	if wall_type(cell, walkable_set) == 2:
		return 1
	return 0


static func _corner_frame(
	cell: Vector2i,
	n: bool,
	e: bool,
	s: bool,
	w: bool,
	walkable_set: Dictionary
) -> int:
	# Outer L when the inside diagonal is walkable; otherwise inner (concave).
	var se: bool = walkable_set.has(cell + Vector2i.RIGHT + Vector2i.DOWN)
	var sw: bool = walkable_set.has(cell + Vector2i.LEFT + Vector2i.DOWN)
	var ne: bool = walkable_set.has(cell + Vector2i.RIGHT + Vector2i.UP)
	var nw: bool = walkable_set.has(cell + Vector2i.LEFT + Vector2i.UP)
	if w and s:
		return 2 if sw else 25
	if w and n:
		return 3 if nw else 27
	if e and n:
		return 5 if ne else 26
	if e and s:
		return 6 if se else 24
	return 0
