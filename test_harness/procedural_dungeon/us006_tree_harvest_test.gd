extends Node

const WOOD_PATH := "res://pickups/wood.tres"

func _ready() -> void:
	PlayerManager.players_data.clear()
	PlayerManager.register_player(1, "Paper Pusher")
	PlayerManager.register_player(2, "Paper Pusher 2")

	var tree: TreeDoodad = load("res://doodads/tree.tscn").instantiate() as TreeDoodad
	tree.tree_type = 0
	add_child(tree)
	await get_tree().process_frame

	var player: Player = Player.new()
	player.name = "1"

	if tree.hits_required != 3:
		_fail("US-006 T002: default hits_required must be 3")
		return
	if not tree.apply_harvest_hit(player):
		_fail("US-006 T002: first melee must apply a harvest hit")
		return
	if tree.hits_taken != 1 or tree.is_stump:
		_fail("US-006 T002: after 1 hit tree must still be living with hits_taken 1")
		return
	if PlayerManager.get_item_count(1, WOOD_PATH) != 0:
		_fail("US-006 T002: incomplete harvest must not yield wood")
		return

	if not tree.apply_harvest_hit(player):
		_fail("US-006 T002: second hit must apply")
		return
	if tree.hits_taken != 2:
		_fail("US-006 T002: two hits from one player must share the same bar, got %d" % tree.hits_taken)
		return

	var player2: Player = Player.new()
	player2.name = "2"
	if not tree.apply_harvest_hit(player2):
		_fail("US-006 T002: second player must share harvest progress")
		return
	if tree.hits_taken != 3:
		_fail("US-006 T002: two players must share one bar, hits_taken=%d" % tree.hits_taken)
		return
	var hit_shape: CollisionShape2D = tree.get_node_or_null("Hitbox/CollisionShape2D") as CollisionShape2D
	if hit_shape == null or not (hit_shape.shape is CircleShape2D) or (hit_shape.shape as CircleShape2D).radius < 56.0:
		_fail("US-006 T002: harvest hitbox must be a forgiving circle")
		return

	var prompt_tree: TreeDoodad = load("res://doodads/tree.tscn").instantiate() as TreeDoodad
	prompt_tree.tree_type = 0
	prompt_tree.position = Vector2(0, 0)
	add_child(prompt_tree)
	await get_tree().process_frame
	var prompt_player: Player = Player.new()
	prompt_player.name = "1"
	prompt_player.cardinal_direction = Vector2.LEFT
	prompt_player.position = Vector2(60, 0)
	if not prompt_tree.is_harvest_prompt_target(prompt_player):
		_fail("US-006 T002: nearby living tree must prompt SPACE harvest")
		prompt_player.free()
		return
	prompt_player.cardinal_direction = Vector2.RIGHT
	if not prompt_tree.is_harvest_prompt_target(prompt_player):
		_fail("US-006 T002: SPACE must still show when a nearby swing reaches the tree")
		prompt_player.free()
		return
	prompt_player.position = Vector2(400, 0)
	if prompt_tree.is_harvest_prompt_target(prompt_player):
		_fail("US-006 T002: far tree must not prompt harvest")
		prompt_player.free()
		return
	prompt_player.free()
	if not tree.is_stump:
		_fail("US-006 T002: third shared hit must complete the tree")
		return

	var hurt: Hurtbox = Hurtbox.new()
	tree._on_harvest_damaged(hurt)
	tree._on_harvest_damaged(hurt)
	if tree.hits_taken != 3:
		_fail("US-006 T002: same swing must not apply twice")
		return

	print("US-006 T002 tree harvest test passed")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
