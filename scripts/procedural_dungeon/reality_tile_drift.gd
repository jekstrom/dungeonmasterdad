class_name RealityTileDrift extends Node

## Host-only: stagger Reality-claimed outside tiles onto Reality art.
## Schedules on claim/map changes only. Physics ticks pending due cells, not the whole map.

const DEFAULT_DELAY_MIN := 0.5
const DEFAULT_DELAY_MAX := 8.0
const MAX_CONVERTS_PER_FRAME := 1
const CLAIM_NONE := 0
const CLAIM_REALITY := 1
const CLAIM_FANTASY := -1
const PUFF_PATH := "res://sprites/reality_drift_puff.png"
const PUFF_FRAME_PX := 32
const PUFF_FPS := 16.0
const SYNC_BUDGET_USEC := 3000
const SYNC_DROP := 0
const SYNC_RECONCILE := 1
const SYNC_SCHEDULE := 2

var delay_min: float = DEFAULT_DELAY_MIN
var delay_max: float = DEFAULT_DELAY_MAX
var puff_enabled: bool = true

var _pending: Dictionary = {}
var _tiles_by_cell: Dictionary = {}
var _dungeon_rect: Rect2i = Rect2i()
var _rng := RandomNumberGenerator.new()
var _puff_frames: SpriteFrames = null
var _puff_frames_tried: bool = false
var _sync_active: bool = false
var _sync_phase: int = 0
var _sync_i: int = 0
var _sync_items: Array = []
var _sync_use_flipped: bool = false

func _ready() -> void:
	_rng.randomize()
	set_physics_process(false)
	set_process(false)
	if not SignalBus.reality_claim_changed.is_connected(_on_claim_changed):
		SignalBus.reality_claim_changed.connect(_on_claim_changed)
	if not SignalBus.fantasy_claim_changed.is_connected(_on_claim_changed):
		SignalBus.fantasy_claim_changed.connect(_on_claim_changed)
	if not SignalBus.map_bounds_committed.is_connected(_on_map_bounds_committed):
		SignalBus.map_bounds_committed.connect(_on_map_bounds_committed)
	ZoneDriftClaim.register_worker(flush_zone_work)
	call_deferred("_bootstrap")

func _exit_tree() -> void:
	ZoneDriftClaim.unregister_worker(flush_zone_work)

func _bootstrap() -> void:
	if not _is_host():
		return
	ZoneDriftClaim.queue_listener(_sync_schedules)

func _process(_delta: float) -> void:
	if not _sync_active:
		set_process(false)
		return
	_tick_sync(false)
	if not _sync_active:
		set_process(false)

func _physics_process(_delta: float) -> void:
	if not _is_host():
		set_physics_process(false)
		return
	_fire_due()
	if _pending.is_empty():
		set_physics_process(false)

func _is_host() -> bool:
	if multiplayer.multiplayer_peer == null:
		return true
	return multiplayer.is_server()

func clear_schedules() -> void:
	_pending.clear()
	_sync_active = false
	_sync_items.clear()
	set_physics_process(false)
	set_process(false)

func _on_claim_changed(_unused = null) -> void:
	if not _is_host():
		return
	ZoneDriftClaim.queue_listener(_sync_schedules)

func _on_map_bounds_committed(_interior: Rect2i = Rect2i()) -> void:
	_tiles_by_cell.clear()
	if not _is_host():
		return
	ZoneDriftClaim.queue_listener(_sync_schedules)

func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0

func flush_zone_work() -> void:
	while _sync_active:
		_tick_sync(true)
	set_process(false)

func _sync_schedules() -> void:
	ZoneDriftClaim.ensure_snapshot(get_tree())
	_refresh_dungeon_rect()
	_sync_phase = SYNC_DROP
	_sync_i = 0
	_sync_items = _pending.keys()
	_sync_use_flipped = false
	_sync_active = true
	if ZoneDriftClaim.is_flushing():
		flush_zone_work()
		return
	set_process(true)
	_tick_sync(false)
	if not _sync_active:
		set_process(false)

func _tick_sync(unlimited: bool) -> void:
	var deadline: int = Time.get_ticks_usec() + (1000000000 if unlimited else SYNC_BUDGET_USEC)
	while _sync_active:
		if not unlimited and Time.get_ticks_usec() >= deadline:
			return
		match _sync_phase:
			SYNC_DROP:
				if _sync_i >= _sync_items.size():
					_sync_phase = SYNC_RECONCILE
					_sync_i = 0
					var flipped: Array[Vector2i] = ZoneDriftClaim.flipped_cells()
					_sync_use_flipped = not flipped.is_empty()
					if _sync_use_flipped:
						_sync_items = flipped
					else:
						_sync_items = _iter_outside_tiles()
					continue
				var drop_cell: Vector2i = _sync_items[_sync_i]
				_sync_i += 1
				if not _pending_still_valid(drop_cell):
					_pending.erase(drop_cell)
			SYNC_RECONCILE:
				if _sync_i >= _sync_items.size():
					_sync_phase = SYNC_SCHEDULE
					_sync_i = 0
					if _sync_use_flipped:
						_sync_items = ZoneDriftClaim.flipped_cells()
					continue
				if _sync_use_flipped:
					var flip_cell: Vector2i = _sync_items[_sync_i]
					_sync_i += 1
					if _dungeon_rect.size.x > 0 and _dungeon_rect.size.y > 0 and _dungeon_rect.has_point(flip_cell):
						continue
					var flip_tile: OutsideTile = _tile_at(flip_cell)
					if flip_tile != null:
						_reconcile_tile(flip_cell, flip_tile)
				else:
					var node = _sync_items[_sync_i]
					_sync_i += 1
					if typeof(node) != TYPE_OBJECT or not is_instance_valid(node) or not (node is OutsideTile):
						continue
					var walk_tile: OutsideTile = node
					var walk_cell: Vector2i = DungeonGrid.from_world(walk_tile.position)
					if _dungeon_rect.size.x > 0 and _dungeon_rect.size.y > 0 and _dungeon_rect.has_point(walk_cell):
						continue
					_reconcile_tile(walk_cell, walk_tile)
			SYNC_SCHEDULE:
				if _sync_i >= _sync_items.size():
					_sync_active = false
					if _is_host() and not _pending.is_empty():
						set_physics_process(true)
					return
				var item = _sync_items[_sync_i]
				_sync_i += 1
				var sched_cell := Vector2i.ZERO
				if item is Vector2i:
					sched_cell = item
				elif typeof(item) == TYPE_OBJECT and is_instance_valid(item) and item is OutsideTile:
					sched_cell = DungeonGrid.from_world((item as OutsideTile).position)
				else:
					continue
				if _pending.has(sched_cell):
					continue
				if not _cell_eligible(sched_cell):
					continue
				var sched_tile: OutsideTile = _tile_at(sched_cell)
				if sched_tile == null:
					continue
				if sched_tile.element_presentation == OutsideTile.ElementPresentation.REALITY:
					continue
				var delay: float = _rng.randf_range(delay_min, maxf(delay_min, delay_max))
				_pending[sched_cell] = _now() + delay
			_:
				_sync_active = false

func _pending_still_valid(cell: Vector2i) -> bool:
	if not _cell_eligible(cell):
		return false
	var tile: OutsideTile = _tile_at(cell)
	return tile != null and tile.element_presentation != OutsideTile.ElementPresentation.REALITY

func _cell_eligible(cell: Vector2i) -> bool:
	if _dungeon_rect.size.x > 0 and _dungeon_rect.size.y > 0 and _dungeon_rect.has_point(cell):
		return false
	if _dungeon_rect.size.x <= 0:
		_refresh_dungeon_rect()
		if _dungeon_rect.size.x > 0 and _dungeon_rect.size.y > 0 and _dungeon_rect.has_point(cell):
			return false
	if _tile_at(cell) == null:
		return false
	return drift_claim_for_cell(cell) == CLAIM_REALITY


func _reconcile_tile(cell: Vector2i, tile: OutsideTile) -> void:
	var claim: int = drift_claim_for_cell(cell)
	var pres: int = int(tile.element_presentation)
	if pres == int(OutsideTile.ElementPresentation.FANTASY) and claim != CLAIM_FANTASY:
		_snap_to_neutral(cell, tile)
	elif pres == int(OutsideTile.ElementPresentation.REALITY) and claim != CLAIM_REALITY:
		_snap_to_neutral(cell, tile)

func _iter_outside_tiles() -> Array:
	var level: Node = _level()
	if level:
		var parent: Node = level.get_node_or_null("OutsideTiles")
		if parent:
			return parent.get_children()
	var tree := get_tree()
	if tree == null:
		return []
	return tree.get_nodes_in_group("outside_tiles")

func _snap_to_neutral(cell: Vector2i, tile: OutsideTile) -> void:
	if tile.element_presentation == OutsideTile.ElementPresentation.NEUTRAL:
		return
	if not tile.has_presentation_strip(OutsideTile.ElementPresentation.NEUTRAL):
		push_error("US-025 T005: missing Neutral strip for kind %s variety %s; leaving current presentation" % [tile.ground_kind, tile.variety])
		return
	var kind: OutsideTile.GroundKind = tile.ground_kind
	var variety: int = int(tile.variety)
	tile.element_presentation = OutsideTile.ElementPresentation.NEUTRAL
	if int(tile.ground_kind) != kind or int(tile.variety) != variety:
		tile.ground_kind = kind
		tile.variety = variety
	_broadcast_presentation(cell, int(OutsideTile.ElementPresentation.NEUTRAL))

func _reality_coverage_cells() -> Array[Vector2i]:
	return ZoneDriftClaim.coverage_cells(CLAIM_REALITY)

func is_reality_drift_eligible(cell: Vector2i) -> bool:
	ZoneDriftClaim.ensure_snapshot(get_tree())
	if _dungeon_rect.size.x > 0 and _dungeon_rect.size.y > 0 and _dungeon_rect.has_point(cell):
		return false
	if _dungeon_rect.size.x <= 0:
		_refresh_dungeon_rect()
		if _dungeon_rect.size.x > 0 and _dungeon_rect.size.y > 0 and _dungeon_rect.has_point(cell):
			return false
	if _tile_at(cell) == null:
		return false
	return drift_claim_for_cell(cell) == CLAIM_REALITY

func drift_claim_for_cell(cell: Vector2i) -> int:
	return ZoneDriftClaim.claim_at(cell)

func _refresh_dungeon_rect() -> void:
	var level: Node = _level()
	if level and level.has_method("dungeon_cell_bounds"):
		var dungeon: Rect2i = level.dungeon_cell_bounds()
		if dungeon.size.x > 0 and dungeon.size.y > 0:
			_dungeon_rect = dungeon
			return
	var manager: Node = get_node_or_null("/root/DungeonGenerationManager")
	if manager and manager.has_method("get_dungeon_cell_bounds"):
		var dgm: Rect2i = manager.get_dungeon_cell_bounds()
		if dgm.size.x > 0 and dgm.size.y > 0:
			_dungeon_rect = dgm
			return
	_dungeon_rect = Rect2i()

func _fire_due() -> void:
	var now: float = _now()
	var best_cell: Vector2i = Vector2i(2147483647, 2147483647)
	var best_time: float = INF
	var found := false
	for cell in _pending.keys():
		var fire_at: float = float(_pending[cell])
		if fire_at > now:
			continue
		if not found or fire_at < best_time or (fire_at == best_time and _cell_before(cell, best_cell)):
			best_cell = cell
			best_time = fire_at
			found = true
	if not found:
		return
	_pending.erase(best_cell)
	_convert_cell(best_cell)

func _cell_before(a: Vector2i, b: Vector2i) -> bool:
	if a.y == b.y:
		return a.x < b.x
	return a.y < b.y

func _convert_cell(cell: Vector2i) -> bool:
	var tile: OutsideTile = _tile_at(cell)
	if tile == null:
		return false
	if not is_reality_drift_eligible(cell):
		return false
	if tile.element_presentation == OutsideTile.ElementPresentation.REALITY:
		return false
	if not tile.has_presentation_strip(OutsideTile.ElementPresentation.REALITY):
		push_error("US-002: missing Reality strip for kind %s variety %s; leaving current presentation" % [tile.ground_kind, tile.variety])
		return false
	var kind: OutsideTile.GroundKind = tile.ground_kind
	var variety: int = int(tile.variety)
	tile.element_presentation = OutsideTile.ElementPresentation.REALITY
	if int(tile.ground_kind) != kind or int(tile.variety) != variety:
		tile.ground_kind = kind
		tile.variety = variety
	play_convert_puff(cell)
	_broadcast_presentation(cell, int(OutsideTile.ElementPresentation.REALITY))
	return true

func play_convert_puff(cell: Vector2i) -> void:
	if not puff_enabled:
		return
	var frames: SpriteFrames = _ensure_puff_frames()
	if frames == null:
		return
	var parent: Node = _level()
	if parent == null:
		parent = self
	var sprite := AnimatedSprite2D.new()
	sprite.name = "RealityDriftPuff"
	sprite.sprite_frames = frames
	sprite.centered = true
	sprite.z_as_relative = false
	sprite.z_index = 20
	sprite.position = DungeonGrid.to_world_center(cell)
	parent.add_child(sprite)
	sprite.play("puff")
	sprite.animation_finished.connect(func(_anim = &"puff") -> void:
		if is_instance_valid(sprite):
			sprite.queue_free()
	)

func _ensure_puff_frames() -> SpriteFrames:
	if _puff_frames != null:
		return _puff_frames
	if _puff_frames_tried:
		return null
	_puff_frames_tried = true
	if not ResourceLoader.exists(PUFF_PATH):
		return null
	var tex: Texture2D = load(PUFF_PATH) as Texture2D
	if tex == null:
		return null
	var frames := SpriteFrames.new()
	frames.add_animation("puff")
	frames.set_animation_loop("puff", false)
	frames.set_animation_speed("puff", PUFF_FPS)
	var frame_count: int = maxi(1, int(tex.get_width()) / PUFF_FRAME_PX)
	for i in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * PUFF_FRAME_PX, 0, PUFF_FRAME_PX, PUFF_FRAME_PX)
		frames.add_frame("puff", atlas)
	_puff_frames = frames
	return _puff_frames

func _broadcast_presentation(cell: Vector2i, presentation: int) -> void:
	var level: Node = _level()
	if level and level.has_method("broadcast_outside_presentation"):
		level.broadcast_outside_presentation(cell, presentation)

func _tile_at(cell: Vector2i) -> OutsideTile:
	var cached: Variant = _tiles_by_cell.get(cell, null)
	if typeof(cached) == TYPE_OBJECT:
		if is_instance_valid(cached) and cached is OutsideTile:
			return cached as OutsideTile
		_tiles_by_cell.erase(cell)
	var level: Node = _level()
	if level:
		var parent: Node = level.get_node_or_null("OutsideTiles")
		if parent:
			var child: Node = parent.get_node_or_null(("out_%d_%d" % [cell.x, cell.y]).validate_node_name())
			if child != null and is_instance_valid(child) and child is OutsideTile:
				_tiles_by_cell[cell] = child
				return child as OutsideTile
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("outside_tiles"):
		if typeof(node) != TYPE_OBJECT or not is_instance_valid(node) or not (node is OutsideTile):
			continue
		if DungeonGrid.from_world((node as OutsideTile).position) == cell:
			_tiles_by_cell[cell] = node
			return node as OutsideTile
	return null

func _level() -> Node:
	return get_parent()
