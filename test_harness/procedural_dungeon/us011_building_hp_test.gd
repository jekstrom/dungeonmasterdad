extends Node

func _ready() -> void:
	var smoke: SmokeFactory = load("res://buildings/buildables/smoke_factory.tscn").instantiate() as SmokeFactory
	add_child(smoke)
	await get_tree().process_frame
	smoke.enable()
	smoke.is_ghost = false
	if smoke.max_hitpoints != 8 or smoke.hitpoints != 8:
		_fail("US-011 T001: smoke factory HP must be 8/8, got %s/%s" % [smoke.hitpoints, smoke.max_hitpoints])
		return
	if is_equal_approx(smoke.health_ratio(), 1.0) == false:
		_fail("US-011 T001: smoke health_ratio must be 1.0")
		return
	var smoke_bar: Node = smoke.get_node_or_null("HealthBar")
	if smoke_bar == null or not (smoke_bar as CanvasItem).visible:
		_fail("US-011 T001: enabled smoke factory must show HealthBar")
		return

	var paper: PaperFactory = load("res://buildings/buildables/paper_factory.tscn").instantiate() as PaperFactory
	add_child(paper)
	await get_tree().process_frame
	paper.enable()
	paper.is_ghost = false
	if paper.max_hitpoints != 12 or paper.hitpoints != 12:
		_fail("US-011 T001: paper factory HP must be 12/12, got %s/%s" % [paper.hitpoints, paper.max_hitpoints])
		return

	var irs: IrsBuilding = load("res://buildings/buildables/irs.tscn").instantiate() as IrsBuilding
	add_child(irs)
	await get_tree().process_frame
	irs.enable()
	irs.is_ghost = false
	if irs.max_hitpoints != 20 or irs.hitpoints != 20:
		_fail("US-011 T001: IRS HP must be 20/20, got %s/%s" % [irs.hitpoints, irs.max_hitpoints])
		return

	var ghost: SmokeFactory = load("res://buildings/buildables/smoke_factory.tscn").instantiate() as SmokeFactory
	ghost.name = "ghost"
	add_child(ghost)
	ghost.set_ghost()
	await get_tree().process_frame
	var ghost_bar: Node = ghost.get_node_or_null("HealthBar")
	if ghost_bar != null and (ghost_bar as CanvasItem).visible:
		_fail("US-011 T001: ghost factory must hide HealthBar")
		return

	print("US-011 T001 building HP test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
