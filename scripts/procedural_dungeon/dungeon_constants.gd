class_name DungeonConstants extends RefCounted

const DEFAULT_PROFILE_ID: String = "standard"
const STANDARD_MIN_BOUNDS: Vector2i = Vector2i(16, 16)
const MAX_GENERATION_ATTEMPTS: int = 20
const FLOOR_Z_INDEX: int = -1
const WALL_Z_INDEX: int = 0

const DEFAULT_ROOM_SIZE: int = 5
const MIN_ROOM_SIZE: int = 3
const MAX_ROOM_SIZE: int = 11
const MIN_ROOM_COUNT: int = 3
const MAX_ROOM_COUNT: int = 8
const MIN_ROOM_CELLS: int = 9

static func normalize_room_size(room_size: int) -> int:
	var size: int = clampi(room_size, MIN_ROOM_SIZE, MAX_ROOM_SIZE)
	if size % 2 == 0:
		size -= 1
	return size

static func room_radius(room_size: int) -> int:
	return int(normalize_room_size(room_size) / 2)

static func room_center_separation(room_size: int) -> int:
	return normalize_room_size(room_size) + 1

static func auto_mid_room_count(bounds: Rect2i) -> int:
	var area: int = bounds.size.x * bounds.size.y
	return clampi(int(area / 180), 1, 3)
