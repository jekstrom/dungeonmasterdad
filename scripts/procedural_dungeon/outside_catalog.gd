class_name OutsideCatalog extends RefCounted

const OUTSIDE_SCENE_PATH: String = "res://level/outside_tile.tscn"
const VARIETY_COUNT: int = 3

const GRASS_STRIP_PATHS: PackedStringArray = [
	"res://sprites/outside_grass_neutral.png",
	"res://sprites/outside_grass_reality.png",
	"res://sprites/outside_grass_fantasy.png",
]
const DIRT_STRIP_PATHS: PackedStringArray = [
	"res://sprites/outside_dirt_neutral.png",
	"res://sprites/outside_dirt_reality.png",
	"res://sprites/outside_dirt_fantasy.png",
]

func get_outside_scene_path() -> String:
	return OUTSIDE_SCENE_PATH

func get_approved_scene_paths() -> PackedStringArray:
	return PackedStringArray([OUTSIDE_SCENE_PATH])

func is_approved_scene_path(scene_path: String) -> bool:
	return scene_path == OUTSIDE_SCENE_PATH

func is_dungeon_tile_path(scene_path: String) -> bool:
	return TileCatalog.is_dungeon_catalog_path(scene_path)

func strip_path(ground_kind: int, presentation: int) -> String:
	var pres: int = clampi(presentation, 0, 2)
	if ground_kind == int(OutsideTile.GroundKind.DIRT):
		return DIRT_STRIP_PATHS[pres]
	return GRASS_STRIP_PATHS[pres]

func apply_random_neutral(tile: Node, rng: RandomNumberGenerator) -> void:
	if tile == null or rng == null:
		return
	if "ground_kind" in tile:
		tile.ground_kind = (
			OutsideTile.GroundKind.GRASS if rng.randi_range(0, 1) == 0 else OutsideTile.GroundKind.DIRT
		)
	if "variety" in tile:
		tile.variety = rng.randi_range(0, VARIETY_COUNT - 1)
	if "element_presentation" in tile:
		tile.element_presentation = OutsideTile.ElementPresentation.NEUTRAL
