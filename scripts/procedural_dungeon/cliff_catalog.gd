class_name CliffCatalog extends RefCounted

const CLIFF_SCENE_PATH: String = "res://level/cliff.tscn"

func get_cliff_scene_path() -> String:
	return CLIFF_SCENE_PATH

func get_approved_scene_paths() -> PackedStringArray:
	return PackedStringArray([CLIFF_SCENE_PATH])

func is_approved_scene_path(scene_path: String) -> bool:
	return scene_path == CLIFF_SCENE_PATH

func is_dungeon_tile_path(scene_path: String) -> bool:
	return TileCatalog.is_dungeon_catalog_path(scene_path)

func cliff_frame_for_cell(interior: Rect2i, cell: Vector2i) -> int:
	if interior.size.x <= 0 or interior.size.y <= 0:
		return int(CliffDoodad.CliffFrame.VOID)
	var on_n: bool = cell.y == interior.position.y - 1
	var on_s: bool = cell.y == interior.end.y
	var on_w: bool = cell.x == interior.position.x - 1
	var on_e: bool = cell.x == interior.end.x
	if on_n and on_w:
		return int(CliffDoodad.CliffFrame.NW)
	if on_n and on_e:
		return int(CliffDoodad.CliffFrame.NE)
	if on_s and on_w:
		return int(CliffDoodad.CliffFrame.SW)
	if on_s and on_e:
		return int(CliffDoodad.CliffFrame.SE)
	if on_n:
		return int(CliffDoodad.CliffFrame.N)
	if on_e:
		return int(CliffDoodad.CliffFrame.E)
	if on_s:
		return int(CliffDoodad.CliffFrame.S)
	if on_w:
		return int(CliffDoodad.CliffFrame.W)
	return int(CliffDoodad.CliffFrame.VOID)
