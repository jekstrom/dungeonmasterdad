class_name ZoneAmbientVfx extends Node

## Local-only ambient VFX: Reality dust and Fantasy sparkles from replicated claim.
## Rebuilds on claim/map change. Does not scan the whole map every physics frame.
## US-026 T001-T004. Convert puffs stay US-002 / US-004.

const CLAIM_NONE := 0
const CLAIM_REALITY := 1
const CLAIM_FANTASY := -1

const DUST_PATH := "res://sprites/reality_dust.png"
const SPARKLE_PATH := "res://sprites/fantasy_sparkle.png"
const CONVERT_PUFF_REALITY := "res://sprites/reality_drift_puff.png"
const CONVERT_PUFF_FANTASY := "res://sprites/fantasy_drift_puff.png"
const SPARKS_PATH := "res://sprites/sparks.png"
const FRAME_PX := 32
const FRAME_COUNT := 6
const POP_FPS := 10.0
const ANIM := &"pop"
const DEFAULT_INTERVAL_MIN := 1.8
const DEFAULT_INTERVAL_MAX := 3.6

var interval_min: float = DEFAULT_INTERVAL_MIN
var interval_max: float = DEFAULT_INTERVAL_MAX
var rebuild_count: int = 0

var _dust_cells: Array[Vector2i] = []
var _sparkle_cells: Array[Vector2i] = []
var _dust_lookup: Dictionary = {}
var _sparkle_lookup: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _dust_frames: SpriteFrames = null
var _sparkle_frames: SpriteFrames = null
var _dust_tried: bool = false
var _sparkle_tried: bool = false
var _until_pop: float = 0.0

func _ready() -> void:
	_rng.randomize()
	set_process(false)
	set_physics_process(false)
	if not SignalBus.reality_claim_changed.is_connected(_on_claim_changed):
		SignalBus.reality_claim_changed.connect(_on_claim_changed)
	if not SignalBus.fantasy_claim_changed.is_connected(_on_claim_changed):
		SignalBus.fantasy_claim_changed.connect(_on_claim_changed)
	if not SignalBus.map_bounds_committed.is_connected(_on_map_changed):
		SignalBus.map_bounds_committed.connect(_on_map_changed)
	if not SignalBus.map_bounds_cleared.is_connected(_on_map_changed):
		SignalBus.map_bounds_cleared.connect(_on_map_changed)
	call_deferred("rebuild_candidates")

func _process(delta: float) -> void:
	if _dust_cells.is_empty() and _sparkle_cells.is_empty():
		set_process(false)
		return
	_until_pop -= delta
	if _until_pop > 0.0:
		return
	_until_pop = _rng.randf_range(interval_min, maxf(interval_min, interval_max))
	_play_random_pop()

func _on_claim_changed(_unused = null) -> void:
	rebuild_candidates()

func _on_map_changed(_unused = null) -> void:
	rebuild_candidates()

func rebuild_candidates() -> void:
	rebuild_count += 1
	_dust_cells.clear()
	_sparkle_cells.clear()
	_dust_lookup.clear()
	_sparkle_lookup.clear()
	var tree := get_tree()
	if tree != null:
		for cell in _coverage_cells():
			var claim: int = ZoneDriftClaim.for_cell(tree, cell)
			if claim == CLAIM_REALITY:
				if _dust_lookup.has(cell):
					continue
				_dust_lookup[cell] = true
				_dust_cells.append(cell)
			elif claim == CLAIM_FANTASY:
				if _sparkle_lookup.has(cell):
					continue
				_sparkle_lookup[cell] = true
				_sparkle_cells.append(cell)
	_cull_stale_pops()
	var has_any: bool = not _dust_cells.is_empty() or not _sparkle_cells.is_empty()
	set_physics_process(false)
	set_process(has_any)
	if has_any and _until_pop <= 0.0:
		_until_pop = _rng.randf_range(interval_min, maxf(interval_min, interval_max))

func is_dust_candidate(cell: Vector2i) -> bool:
	return _dust_lookup.has(cell)

func is_sparkle_candidate(cell: Vector2i) -> bool:
	return _sparkle_lookup.has(cell)

func candidate_kind(cell: Vector2i) -> int:
	if _dust_lookup.has(cell):
		return CLAIM_REALITY
	if _sparkle_lookup.has(cell):
		return CLAIM_FANTASY
	return CLAIM_NONE

func dust_strip_path() -> String:
	return DUST_PATH

func sparkle_strip_path() -> String:
	return SPARKLE_PATH

func play_pop(cell: Vector2i) -> AnimatedSprite2D:
	var kind: int = candidate_kind(cell)
	if kind == CLAIM_NONE:
		return null
	return _spawn_pop(cell, kind)

func play_dust(cell: Vector2i) -> AnimatedSprite2D:
	if not is_dust_candidate(cell):
		return null
	return _spawn_pop(cell, CLAIM_REALITY)

func play_sparkle(cell: Vector2i) -> AnimatedSprite2D:
	if not is_sparkle_candidate(cell):
		return null
	return _spawn_pop(cell, CLAIM_FANTASY)

func has_replicated_emitting() -> bool:
	return _node_has_replicator(self)

func _coverage_cells() -> Array[Vector2i]:
	var seen: Dictionary = {}
	var cells: Array[Vector2i] = []
	_append_zone_coverage("RealityZone", seen, cells)
	_append_zone_coverage("FantasyZone", seen, cells)
	return cells

func _append_zone_coverage(group_name: String, seen: Dictionary, cells: Array[Vector2i]) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var zone: Node = tree.get_first_node_in_group(group_name)
	if zone == null:
		return
	if "home_rect" in zone:
		_append_rect_cells(seen, cells, zone.home_rect)
	if "claim" in zone:
		for pocket in zone.claim.pockets:
			if typeof(pocket) != TYPE_DICTIONARY:
				continue
			_append_rect_cells(seen, cells, pocket.get("rect", Rect2i()))

func _append_rect_cells(seen: Dictionary, cells: Array[Vector2i], rect: Rect2i) -> void:
	if rect.size.x <= 0 or rect.size.y <= 0:
		return
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var cell := Vector2i(x, y)
			if seen.has(cell):
				continue
			seen[cell] = true
			cells.append(cell)

func _play_random_pop() -> void:
	var dust_near: Array[Vector2i] = _nearby(_dust_cells)
	var sparkle_near: Array[Vector2i] = _nearby(_sparkle_cells)
	var total: int = dust_near.size() + sparkle_near.size()
	if total <= 0:
		return
	var pick: int = _rng.randi_range(0, total - 1)
	if pick < dust_near.size():
		_spawn_pop(dust_near[pick], CLAIM_REALITY)
	else:
		_spawn_pop(sparkle_near[pick - dust_near.size()], CLAIM_FANTASY)

func _nearby(cells: Array[Vector2i]) -> Array[Vector2i]:
	var vis: Rect2i = _visible_cell_rect()
	if vis.size.x <= 0 or vis.size.y <= 0:
		return cells
	var out: Array[Vector2i] = []
	for cell in cells:
		if vis.has_point(cell):
			out.append(cell)
	return out

func _visible_cell_rect() -> Rect2i:
	var cam: Camera2D = _camera()
	if cam == null:
		return Rect2i()
	var vp := get_viewport()
	if vp == null:
		return Rect2i()
	var size: Vector2 = vp.get_visible_rect().size
	var zoom: Vector2 = cam.zoom
	if zoom.x == 0.0 or zoom.y == 0.0:
		return Rect2i()
	var world_size := Vector2(size.x / zoom.x, size.y / zoom.y)
	var center: Vector2 = cam.get_screen_center_position()
	var top_left: Vector2 = center - world_size * 0.5
	var c0: Vector2i = DungeonGrid.from_world(top_left)
	var c1: Vector2i = DungeonGrid.from_world(top_left + world_size)
	var pos := Vector2i(mini(c0.x, c1.x), mini(c0.y, c1.y))
	var ext := Vector2i(absi(c1.x - c0.x) + 1, absi(c1.y - c0.y) + 1)
	return Rect2i(pos, ext).grow(1)

func _camera() -> Camera2D:
	var vp := get_viewport()
	if vp == null:
		return null
	return vp.get_camera_2d()

func _spawn_pop(cell: Vector2i, kind: int) -> AnimatedSprite2D:
	if kind == CLAIM_REALITY and not _dust_lookup.has(cell):
		return null
	if kind == CLAIM_FANTASY and not _sparkle_lookup.has(cell):
		return null
	if kind != CLAIM_REALITY and kind != CLAIM_FANTASY:
		return null
	var frames: SpriteFrames = _ensure_frames(kind)
	if frames == null:
		return null
	var parent: Node = get_parent()
	if parent == null:
		parent = self
	var sprite := AnimatedSprite2D.new()
	if kind == CLAIM_REALITY:
		sprite.name = "RealityAmbientDust"
	else:
		sprite.name = "FantasyAmbientSparkle"
	sprite.sprite_frames = frames
	sprite.centered = true
	sprite.z_as_relative = false
	sprite.z_index = 10
	sprite.position = DungeonGrid.to_world_center(cell) + Vector2(
		_rng.randf_range(-20.0, 20.0),
		_rng.randf_range(-20.0, 20.0)
	)
	sprite.set_meta("ambient_cell", cell)
	sprite.set_meta("ambient_kind", kind)
	parent.add_child(sprite)
	sprite.play(ANIM)
	sprite.animation_finished.connect(_on_pop_finished.bind(sprite), CONNECT_ONE_SHOT)
	return sprite

func _on_pop_finished(sprite: AnimatedSprite2D) -> void:
	if is_instance_valid(sprite):
		sprite.queue_free()

func _cull_stale_pops() -> void:
	var parent: Node = get_parent()
	if parent == null:
		parent = self
	for child in parent.get_children():
		if not (child is AnimatedSprite2D) or not is_instance_valid(child):
			continue
		if not child.has_meta("ambient_cell") or not child.has_meta("ambient_kind"):
			continue
		var cell: Vector2i = child.get_meta("ambient_cell")
		var kind: int = int(child.get_meta("ambient_kind"))
		var keep := false
		if kind == CLAIM_REALITY:
			keep = _dust_lookup.has(cell)
		elif kind == CLAIM_FANTASY:
			keep = _sparkle_lookup.has(cell)
		if not keep:
			child.queue_free()

func _ensure_frames(kind: int) -> SpriteFrames:
	if kind == CLAIM_REALITY:
		if _dust_frames != null:
			return _dust_frames
		if _dust_tried:
			return null
		_dust_tried = true
		_dust_frames = _load_strip(DUST_PATH)
		return _dust_frames
	if kind == CLAIM_FANTASY:
		if _sparkle_frames != null:
			return _sparkle_frames
		if _sparkle_tried:
			return null
		_sparkle_tried = true
		_sparkle_frames = _load_strip(SPARKLE_PATH)
		return _sparkle_frames
	return null

func _load_strip(path: String) -> SpriteFrames:
	if path == CONVERT_PUFF_REALITY or path == CONVERT_PUFF_FANTASY or path == SPARKS_PATH:
		return null
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		return null
	var frames := SpriteFrames.new()
	frames.add_animation(ANIM)
	frames.set_animation_loop(ANIM, false)
	frames.set_animation_speed(ANIM, POP_FPS)
	var frame_count: int = mini(FRAME_COUNT, maxi(1, int(tex.get_width()) / FRAME_PX))
	for i in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * FRAME_PX, 0, FRAME_PX, FRAME_PX)
		frames.add_frame(ANIM, atlas)
	return frames

func _node_has_replicator(node: Node) -> bool:
	if node is MultiplayerSynchronizer:
		return true
	for child in node.get_children():
		if _node_has_replicator(child):
			return true
	return false
