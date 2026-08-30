extends CanvasLayer

const WOOD_TEX: Texture2D = preload("res://pickups/wood/wood.png")
const PAPER_TEX: Texture2D = preload("res://pickups/paper/paper.png")
const ICON_PX := 36.0
const BUFFER_ICON_PX := 22.0
const BAR_WIDTH := 36.0
const BAR_HEIGHT := 5.0
const WORLD_LIFT := Vector2(0, -78)
const MINE_WORLD_LIFT := Vector2(0, -48)

var _markers: Dictionary = {}
var _mine_markers: Dictionary = {}
var _pulse_t: float = 0.0

func _ready() -> void:
	layer = 100
	follow_viewport_enabled = false

func _process(delta: float) -> void:
	_pulse_t += delta
	var scene_tree := get_tree()
	if scene_tree == null:
		return
	_sync_factory_markers(scene_tree)
	_sync_mine_markers(scene_tree)

func wood_visible(factory: PaperFactory) -> bool:
	var marker: Control = _marker_of(factory)
	if marker == null:
		return false
	var wood: TextureRect = marker.get_node_or_null("Wood") as TextureRect
	return marker.visible and wood != null and wood.visible

func paper_visible(factory: PaperFactory) -> bool:
	var marker: Control = _marker_of(factory)
	if marker == null:
		return false
	var paper: TextureRect = marker.get_node_or_null("Paper") as TextureRect
	return marker.visible and paper != null and paper.visible

func bar_fill_width(factory: PaperFactory) -> float:
	var marker: Control = _marker_of(factory)
	if marker == null:
		return 0.0
	var fill: ColorRect = marker.get_node_or_null("BarFill") as ColorRect
	if fill == null:
		return 0.0
	return fill.size.x

func buffer_visible(factory: PaperFactory) -> bool:
	var marker: Control = _marker_of(factory)
	if marker == null or not marker.visible:
		return false
	var buf: TextureRect = marker.get_node_or_null("BufferWood") as TextureRect
	return buf != null and buf.visible

func buffer_count_text(factory: PaperFactory) -> String:
	var marker: Control = _marker_of(factory)
	if marker == null:
		return ""
	var label: Label = marker.get_node_or_null("BufferCount") as Label
	if label == null:
		return ""
	return label.text

func _sync_factory_markers(scene_tree: SceneTree) -> void:
	var seen: Dictionary = {}
	for node in scene_tree.get_nodes_in_group("paper_factories"):
		if not (node is PaperFactory) or not is_instance_valid(node) or not node.is_inside_tree():
			continue
		var factory: PaperFactory = node
		var id: int = factory.get_instance_id()
		seen[id] = true
		var marker: Control = _markers.get(id)
		if marker == null:
			marker = _make_marker()
			add_child(marker)
			_markers[id] = marker
		_update_marker(marker, factory)
	_free_stale_markers(_markers, seen)

func _sync_mine_markers(scene_tree: SceneTree) -> void:
	var seen: Dictionary = {}
	for node in scene_tree.get_nodes_in_group("mines"):
		if not (node is MineDoodad) or not is_instance_valid(node) or not node.is_inside_tree():
			continue
		var mine: MineDoodad = node
		var id: int = mine.get_instance_id()
		seen[id] = true
		var marker: Control = _mine_markers.get(id)
		if marker == null:
			marker = _make_mine_marker()
			add_child(marker)
			_mine_markers[id] = marker
		_update_mine_marker(marker, mine)
	_free_stale_markers(_mine_markers, seen)

func _free_stale_markers(store: Dictionary, seen: Dictionary) -> void:
	var stale: Array = []
	for id in store.keys():
		if not seen.has(id):
			stale.append(id)
	for id in stale:
		var old: Control = store[id]
		store.erase(id)
		if is_instance_valid(old):
			old.queue_free()

func mine_bar_visible(mine: MineDoodad) -> bool:
	var marker: Control = _mine_marker_of(mine)
	if marker == null:
		return false
	var fill: ColorRect = marker.get_node_or_null("BarFill") as ColorRect
	return marker.visible and fill != null and fill.visible

func mine_bar_fill_width(mine: MineDoodad) -> float:
	var marker: Control = _mine_marker_of(mine)
	if marker == null:
		return 0.0
	var fill: ColorRect = marker.get_node_or_null("BarFill") as ColorRect
	if fill == null:
		return 0.0
	return fill.size.x

func _marker_of(factory: PaperFactory) -> Control:
	if factory == null:
		return null
	return _markers.get(factory.get_instance_id()) as Control

func _mine_marker_of(mine: MineDoodad) -> Control:
	if mine == null:
		return null
	return _mine_markers.get(mine.get_instance_id()) as Control

func _make_marker() -> Control:
	var root := Control.new()
	root.name = "FactoryStatus"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.size = Vector2(80.0, ICON_PX + 24.0)
	root.visible = false

	var wood := TextureRect.new()
	wood.name = "Wood"
	wood.texture = WOOD_TEX
	wood.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wood.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wood.position = Vector2.ZERO
	wood.size = Vector2(ICON_PX, ICON_PX)
	wood.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wood.visible = false
	root.add_child(wood)

	var buffer_wood := TextureRect.new()
	buffer_wood.name = "BufferWood"
	buffer_wood.texture = WOOD_TEX
	buffer_wood.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	buffer_wood.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	buffer_wood.position = Vector2.ZERO
	buffer_wood.size = Vector2(BUFFER_ICON_PX, BUFFER_ICON_PX)
	buffer_wood.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buffer_wood.visible = false
	root.add_child(buffer_wood)

	var buffer_count := Label.new()
	buffer_count.name = "BufferCount"
	buffer_count.position = Vector2(BUFFER_ICON_PX + 1.0, 2.0)
	buffer_count.size = Vector2(24.0, 22.0)
	buffer_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	buffer_count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	buffer_count.add_theme_font_size_override("font_size", 14)
	buffer_count.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	buffer_count.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	buffer_count.add_theme_constant_override("outline_size", 4)
	buffer_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buffer_count.visible = false
	root.add_child(buffer_count)

	var paper := TextureRect.new()
	paper.name = "Paper"
	paper.texture = PAPER_TEX
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	paper.position = Vector2.ZERO
	paper.size = Vector2(ICON_PX, ICON_PX)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.visible = false
	root.add_child(paper)

	var bar_back := ColorRect.new()
	bar_back.name = "BarBack"
	bar_back.position = Vector2(0, ICON_PX + 4.0)
	bar_back.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	bar_back.color = Color(0.08, 0.08, 0.08, 0.95)
	bar_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_back.visible = false
	root.add_child(bar_back)

	var bar_fill := ColorRect.new()
	bar_fill.name = "BarFill"
	bar_fill.position = Vector2(0, ICON_PX + 4.0)
	bar_fill.size = Vector2(0, BAR_HEIGHT)
	bar_fill.color = Color(1.0, 0.95, 0.55, 1)
	bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_fill.visible = false
	root.add_child(bar_fill)
	return root

func _update_marker(marker: Control, factory: PaperFactory) -> void:
	var show_need: bool = factory.needs_wood()
	var show_buffer: bool = factory.is_operating() and factory.stored_wood > 0
	var show_paper: bool = factory.is_producing_paper()
	marker.visible = show_need or show_buffer or show_paper
	var wood: TextureRect = marker.get_node("Wood") as TextureRect
	var buffer_wood: TextureRect = marker.get_node("BufferWood") as TextureRect
	var buffer_count: Label = marker.get_node("BufferCount") as Label
	var paper: TextureRect = marker.get_node("Paper") as TextureRect
	var bar_back: ColorRect = marker.get_node("BarBack") as ColorRect
	var bar_fill: ColorRect = marker.get_node("BarFill") as ColorRect
	wood.visible = show_need
	buffer_wood.visible = show_buffer
	buffer_count.visible = show_buffer
	paper.visible = show_paper
	bar_back.visible = show_paper
	bar_fill.visible = show_paper
	var screen: Vector2 = factory.get_global_transform_with_canvas() * WORLD_LIFT
	marker.position = screen - Vector2(ICON_PX * 0.5, ICON_PX)
	if show_need:
		var wave: float = 0.5 + 0.5 * sin(_pulse_t * TAU * 2.0)
		var s: float = 0.88 + 0.22 * wave
		wood.pivot_offset = Vector2(ICON_PX, ICON_PX) * 0.5
		wood.scale = Vector2(s, s)
		wood.modulate = Color(1, 1, 1, 1)
	if show_buffer:
		buffer_wood.scale = Vector2.ONE
		buffer_wood.modulate = Color(1, 1, 1, 1)
		buffer_count.text = str(factory.stored_wood)
		if show_paper:
			paper.position = Vector2(BUFFER_ICON_PX + 18.0, 0)
			bar_back.position = Vector2(BUFFER_ICON_PX + 18.0, ICON_PX + 4.0)
			bar_fill.position = Vector2(BUFFER_ICON_PX + 18.0, ICON_PX + 4.0)
		else:
			paper.position = Vector2.ZERO
			bar_back.position = Vector2(0, ICON_PX + 4.0)
			bar_fill.position = Vector2(0, ICON_PX + 4.0)
	else:
		paper.position = Vector2.ZERO
		bar_back.position = Vector2(0, ICON_PX + 4.0)
		bar_fill.position = Vector2(0, ICON_PX + 4.0)
	if show_paper:
		bar_fill.size = Vector2(BAR_WIDTH * factory.production_progress(), BAR_HEIGHT)

func _make_mine_marker() -> Control:
	var root := Control.new()
	root.name = "MineHarvestStatus"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	root.visible = false

	var bar_back := ColorRect.new()
	bar_back.name = "BarBack"
	bar_back.position = Vector2.ZERO
	bar_back.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	bar_back.color = Color(0.08, 0.08, 0.08, 0.95)
	bar_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar_back)

	var bar_fill := ColorRect.new()
	bar_fill.name = "BarFill"
	bar_fill.position = Vector2.ZERO
	bar_fill.size = Vector2(0, BAR_HEIGHT)
	bar_fill.color = Color(1.0, 0.95, 0.55, 1)
	bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar_fill)
	return root

func _update_mine_marker(marker: Control, mine: MineDoodad) -> void:
	var show_bar: bool = mine.shows_harvest_progress()
	marker.visible = show_bar
	var bar_fill: ColorRect = marker.get_node("BarFill") as ColorRect
	bar_fill.visible = show_bar
	var screen: Vector2 = mine.get_global_transform_with_canvas() * MINE_WORLD_LIFT
	marker.position = screen - Vector2(BAR_WIDTH * 0.5, BAR_HEIGHT * 0.5)
	if show_bar:
		bar_fill.size = Vector2(BAR_WIDTH * mine.harvest_progress(), BAR_HEIGHT)
