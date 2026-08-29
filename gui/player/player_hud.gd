extends CanvasLayer

@onready var build_smoke_factory_button: TextureButton = $MarginContainer/HBoxContainer/ColorRect/TextureButton
@onready var build_paper_factory_button: TextureButton = $MarginContainer/HBoxContainer/ColorRect2/TextureButton

@onready var smoke_count: Label = $ResourceContainer/VBoxContainer/SmokeCount
@onready var paper_count: Label = $ResourceContainer/VBoxContainer/PaperCount

func _ready() -> void:
	turn_off()
	smoke_count.visible = false
	paper_count.visible = false
	PlayerManager.smoke_amt_changed.connect(update_smoke_count)
	build_smoke_factory_button.connect("button_down", on_build_smoke_factory_button_pressed)
	build_paper_factory_button.connect("button_down", on_build_paper_factory_button_pressed)
	update_staple_magazine(20, 20)
	_pass_world_clicks_through(self)

func _pass_world_clicks_through(n: Node) -> void:
	# Factory TextureButtons keep STOP so they still select a building.
	if n is BaseButton:
		(n as Control).mouse_filter = Control.MOUSE_FILTER_STOP
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
	SignalBus.build_smoke_building_pressed.emit("SmokeFactory")
	
func on_build_paper_factory_button_pressed():
	SignalBus.build_paper_building_pressed.emit("PaperFactory")
	
func update_smoke_count(smoke_amt: int) -> void:
	smoke_count.visible = true
	smoke_count.text = "Smoke: " + str(smoke_amt) + "/" + str(PlayerManager.max_smoke_amt)

func update_paper_count(paper_amt: int) -> void:
	paper_count.visible = true
	paper_count.text = "Paper: " + str(paper_amt) + "/" + str(PlayerManager.paper_amt)

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
