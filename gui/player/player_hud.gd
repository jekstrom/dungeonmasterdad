extends CanvasLayer

@onready var build_smoke_factory_button: TextureButton = $MarginContainer/HBoxContainer/ColorRect/TextureButton
@onready var build_paper_factory_button: TextureButton = $MarginContainer/HBoxContainer/ColorRect2/TextureButton
@onready var build_irs_button: TextureButton = $MarginContainer/HBoxContainer/ColorRect3/TextureButton
@onready var build_office_max_button: TextureButton = $MarginContainer/HBoxContainer/ColorRect4/TextureButton

@onready var smoke_count: Label = $ResourceContainer/VBoxContainer/SmokeCount
@onready var paper_count: Label = $ResourceContainer/VBoxContainer/PaperCount
@onready var minimap_widget: Control = $MinimapWidget

func _ready() -> void:
	turn_off()
	smoke_count.visible = false
	paper_count.visible = false
	PlayerManager.smoke_amt_changed.connect(update_smoke_count)
	if not SignalBus.inventory_updated.is_connected(_on_inventory_updated):
		SignalBus.inventory_updated.connect(_on_inventory_updated)
	build_smoke_factory_button.connect("button_down", on_build_smoke_factory_button_pressed)
	build_paper_factory_button.connect("button_down", on_build_paper_factory_button_pressed)
	if build_irs_button:
		build_irs_button.connect("button_down", on_build_irs_button_pressed)
	if build_office_max_button:
		build_office_max_button.connect("button_down", on_build_office_max_button_pressed)
	update_staple_magazine(20, 20)
	if minimap_widget:
		if minimap_widget.has_method("configure"):
			minimap_widget.configure(false)
		elif "role_is_dm" in minimap_widget:
			minimap_widget.role_is_dm = false
		_pass_world_clicks_through(minimap_widget)
	_pass_world_clicks_through(self)

func _pass_world_clicks_through(n: Node) -> void:
	# Factory TextureButtons keep STOP so they still select a building.
	if n is BaseButton:
		(n as Control).mouse_filter = Control.MOUSE_FILTER_STOP
		(n as BaseButton).focus_mode = Control.FOCUS_NONE
		return
	if n is Control:
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in n.get_children():
		_pass_world_clicks_through(child)

func turn_on() -> void:
	self.visible = true
	
func turn_off() -> void:
	self.visible = false
	
func on_build_smoke_factory_button_pressed():
	build_smoke_factory_button.release_focus()
	SignalBus.build_smoke_building_pressed.emit("SmokeFactory")
	
func on_build_paper_factory_button_pressed():
	build_paper_factory_button.release_focus()
	SignalBus.build_paper_building_pressed.emit("PaperFactory")

func on_build_irs_button_pressed():
	if build_irs_button:
		build_irs_button.release_focus()
	SignalBus.build_irs_building_pressed.emit("Irs")

func on_build_office_max_button_pressed():
	if build_office_max_button:
		build_office_max_button.release_focus()
	SignalBus.build_office_max_building_pressed.emit("OfficeMax")
	
func update_smoke_count(smoke_amt: int) -> void:
	smoke_count.visible = true
	smoke_count.text = "Smoke: " + str(smoke_amt) + "/" + str(PlayerManager.max_smoke_amt)

func update_paper_count(paper_amt: int) -> void:
	paper_count.visible = paper_amt > 0
	paper_count.text = "Paper: " + str(paper_amt)

func _on_inventory_updated(display_list: Array) -> void:
	var paper_qty := 0
	for item_qty in display_list:
		if typeof(item_qty) != TYPE_DICTIONARY:
			continue
		var data: ItemData = item_qty.get("data") as ItemData
		if data == null:
			continue
		if data.resource_path == "res://pickups/paper.tres":
			paper_qty = int(item_qty.get("quantity", 0))
	update_paper_count(paper_qty)

func update_staple_magazine(count: int, mag_max: int) -> void:
	var label: Label = get_node_or_null("%StapleCount") as Label
	var icon: TextureRect = get_node_or_null("%StapleIcon") as TextureRect
	if label:
		label.text = "%d/%d" % [count, mag_max]
		label.visible = true
	if icon:
		icon.visible = true
		if icon.texture == null:
			icon.texture = load("res://sprites/staple_hud_icon.png")

func _input(event: InputEvent) -> void:
	# F10 via _input so focused factory buttons / GUI cannot swallow it before unhandled.
	if not visible:
		return
	if not event.is_action_pressed("toggle_minimap_debug_reveal"):
		return
	if minimap_widget and minimap_widget.has_method("toggle_debug_reveal"):
		minimap_widget.toggle_debug_reveal()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("toggle_minimap"):
		if minimap_widget and minimap_widget.has_method("toggle_map"):
			minimap_widget.toggle_map()
			get_viewport().set_input_as_handled()
