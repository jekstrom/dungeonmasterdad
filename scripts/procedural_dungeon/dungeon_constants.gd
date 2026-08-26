class_name DungeonConstants extends RefCounted

const DEFAULT_PROFILE_ID: String = "standard"
const STANDARD_MIN_BOUNDS: Vector2i = Vector2i(16, 16)
const MAX_GENERATION_ATTEMPTS: int = 20
const MAX_REQUESTS_PER_TICK: int = 1

const TARGET_GENERATION_SECONDS: float = 2.0
const MAX_FRAME_FREEZE_SECONDS: float = 1.0

const MIN_ROOM_COUNT: int = 1
const MIN_HALLWAY_COUNT: int = 1

const EXISTING_FLOOR_SCENE_PATH: String = "res://level/floor.tscn"
const EXISTING_WALL_SCENE_PATH: String = "res://level/wall.tscn"

#const EXISTING_MONSTER_SCENE_PATHS: PackedStringArray = PackedStringArray([
	#"res://monsters/goblin.tscn",
	#"res://monsters/skeleton/skeleton.tscn",
	#"res://monsters/knight/knight.tscn"
#])
