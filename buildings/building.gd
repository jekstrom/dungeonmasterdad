class_name Building extends Node2D

const HEALTH_BAR_SCENE: PackedScene = preload("res://monsters/enemy_health_bar.tscn")
const HITBOX_SCENE: PackedScene = preload("res://hitbox.tscn")
const SMOKE_RUBBLE: Texture2D = preload("res://sprites/smoke_factory_rubble.png")
const PAPER_RUBBLE: Texture2D = preload("res://sprites/paper_factory_rubble.png")
const IRS_RUBBLE: Texture2D = preload("res://sprites/irs_building_rubble.png")
const OFFICE_MAX_RUBBLE: Texture2D = preload("res://sprites/office_max_rubble.png")
const IRON_ITEM := "res://pickups/metal.tres"
const RAID_HITBOX_LAYER := 32
const HARVEST_HITBOX_LAYER := 8
const HARVEST_HINT_RANGE := 64.0
const BLIZZARD_FACTORY_INTERVAL_FACTOR := 2.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@export var interval: float = 1.0
@export var max_hitpoints: int = 10
@export var hitpoints: int = 10:
	set(value):
		var cap: int = maxi(1, max_hitpoints) if max_hitpoints > 0 else maxi(0, value)
		hitpoints = clampi(value, 0, cap)
		_refresh_health_bar()
@export var blizzard_factory_interval_factor: float = BLIZZARD_FACTORY_INTERVAL_FACTOR
@export var timer: float = 0.0
@export var is_ghost: bool = true
@export var destroyed: bool = false:
	set(value):
		var was: bool = destroyed
		destroyed = value
		if destroyed and not was:
			_apply_destroyed_visuals()
@export var salvage_hits_required: int = 4
@export var salvage_hits_taken: int = 0

var _baseline_interval: float = -1.0
var _applied_blizzard_factor: float = 1.0
var _health_bar: Node2D
var _hit_hurtboxes: Dictionary = {}
var _salvage_done: bool = false

func _enter_tree() -> void:
	_ensure_baseline_interval()
	add_to_group("buildings")
	if self is SmokeFactory or self is PaperFactory:
		add_to_group("factories")
	if not SignalBus.spell_cast.is_connected(_on_blizzard_spell_cast):
		SignalBus.spell_cast.connect(_on_blizzard_spell_cast)
	if not SignalBus.fantasy_pocket_expired.is_connected(_on_blizzard_pocket_expired):
		SignalBus.fantasy_pocket_expired.connect(_on_blizzard_pocket_expired)
	if not SignalBus.map_bounds_cleared.is_connected(_on_blizzard_map_cleared):
		SignalBus.map_bounds_cleared.connect(_on_blizzard_map_cleared)

func _exit_tree() -> void:
	if SignalBus.spell_cast.is_connected(_on_blizzard_spell_cast):
		SignalBus.spell_cast.disconnect(_on_blizzard_spell_cast)
	if SignalBus.fantasy_pocket_expired.is_connected(_on_blizzard_pocket_expired):
		SignalBus.fantasy_pocket_expired.disconnect(_on_blizzard_pocket_expired)
	if SignalBus.map_bounds_cleared.is_connected(_on_blizzard_map_cleared):
		SignalBus.map_bounds_cleared.disconnect(_on_blizzard_map_cleared)

func _ready() -> void:
	if max_hitpoints < hitpoints:
		max_hitpoints = hitpoints
	if max_hitpoints <= 0:
		max_hitpoints = 1
	hitpoints = mini(hitpoints, max_hitpoints)
	_ensure_hitbox()
	_spawn_health_bar()
	_configure_hp_replication()
	if destroyed:
		_apply_destroyed_visuals()
	_refresh_health_bar()

func set_ghost() -> void:
	is_ghost = true
	if collision_shape_2d:
		collision_shape_2d.set_deferred("disabled", true)
	_refresh_health_bar()

func enable() -> void:
	if destroyed:
		return
	is_ghost = false
	if collision_shape_2d:
		collision_shape_2d.set_deferred("disabled", false)
	set_deferred("collision_layer", 1)
	set_deferred("collision_mask", 1)
	sync_blizzard_interval()
	_refresh_health_bar()
	SignalBus.occupancy_solids_changed.emit()

func is_operating() -> bool:
	if destroyed:
		return false
	if not is_ghost:
		return true
	if collision_shape_2d and not collision_shape_2d.disabled:
		return true
	return false

func is_raidable() -> bool:
	if destroyed:
		return false
	if is_ghost:
		return false
	if str(name) == "ghost":
		return false
	if not is_inside_tree():
		return false
	if get_parent() is Player:
		return false
	return is_operating()

func factory_origin() -> Vector2:
	return global_position

func raid_hull_rect(pad: float = 16.0) -> Rect2:
	var size := Vector2(116, 69)
	var local := Vector2(5, -35)
	if collision_shape_2d and collision_shape_2d.shape is RectangleShape2D:
		size = (collision_shape_2d.shape as RectangleShape2D).size
		local = collision_shape_2d.position
	var center: Vector2 = global_position + local
	var grow := Vector2(pad, pad)
	return Rect2(center - size * 0.5 - grow, size + grow * 2.0)


func closest_hull_point(world: Vector2, pad: float = 0.0) -> Vector2:
	var hull: Rect2 = raid_hull_rect(pad)
	return Vector2(
		clampf(world.x, hull.position.x, hull.end.x),
		clampf(world.y, hull.position.y, hull.end.y)
	)


func hull_distance(world: Vector2, pad: float = 0.0) -> float:
	return world.distance_to(closest_hull_point(world, pad))

func health_ratio() -> float:
	return float(hitpoints) / float(maxi(1, max_hitpoints))

func take_damage(hurt_box: Hurtbox) -> void:
	if not multiplayer.is_server():
		return
	if destroyed or is_ghost or not is_operating():
		return
	if not _is_raid_hurtbox(hurt_box):
		return
	hitpoints = hitpoints - hurt_box.damage
	if hitpoints <= 0:
		destroy()


func apply_explosion_damage(amount: int) -> void:
	if not multiplayer.is_server():
		return
	if destroyed or is_ghost or not is_operating():
		return
	hitpoints = hitpoints - maxi(1, amount)
	if hitpoints <= 0:
		destroy()

func destroy() -> void:
	if destroyed:
		return
	if not multiplayer.is_server():
		return
	hitpoints = 0
	destroyed = true
	SignalBus.occupancy_solids_changed.emit()

func production_remaining() -> float:
	return maxf(0.0, interval - timer)

func to_timer_sync_dict() -> Dictionary:
	_ensure_baseline_interval()
	return {
		"name": str(name),
		"x": global_position.x,
		"y": global_position.y,
		"interval": interval,
		"timer": timer,
		"remaining": production_remaining(),
		"factor": _applied_blizzard_factor,
		"baseline": _baseline_interval,
		"hitpoints": hitpoints,
		"destroyed": destroyed,
		"salvage_hits_taken": salvage_hits_taken,
	}

func apply_timer_sync_dict(payload: Dictionary) -> void:
	_ensure_baseline_interval()
	if payload.has("baseline"):
		var baseline: float = float(payload["baseline"])
		if baseline > 0.0:
			_baseline_interval = baseline
	if payload.has("factor"):
		_applied_blizzard_factor = float(payload["factor"])
	if payload.has("interval"):
		interval = float(payload["interval"])
	if payload.has("timer"):
		timer = float(payload["timer"])
	elif payload.has("remaining"):
		timer = interval - float(payload["remaining"])
	if payload.has("hitpoints"):
		hitpoints = int(payload["hitpoints"])
	if payload.has("destroyed"):
		destroyed = bool(payload["destroyed"])
	if payload.has("salvage_hits_taken"):
		salvage_hits_taken = int(payload["salvage_hits_taken"])

func sync_blizzard_interval(ignore_pocket_id: int = -1) -> void:
	if not multiplayer.is_server():
		return
	if is_ghost or destroyed:
		return
	var in_pocket: bool = DmManager.is_in_blizzard_slow_rect(factory_origin(), ignore_pocket_id)
	var factor: float = blizzard_factory_interval_factor if in_pocket else 1.0
	if factor <= 0.0:
		factor = BLIZZARD_FACTORY_INTERVAL_FACTOR if in_pocket else 1.0
	_apply_blizzard_interval_factor(factor)

func _ensure_baseline_interval() -> void:
	if _baseline_interval < 0.0:
		_baseline_interval = interval

func _apply_blizzard_interval_factor(new_factor: float) -> void:
	_ensure_baseline_interval()
	if new_factor <= 0.0:
		new_factor = 1.0
	if is_equal_approx(new_factor, _applied_blizzard_factor):
		return
	var remaining: float = production_remaining()
	remaining *= new_factor / _applied_blizzard_factor
	interval = _baseline_interval * new_factor
	timer = interval - remaining
	_applied_blizzard_factor = new_factor

func _on_blizzard_spell_cast(spell_id: String, _spell_data: Dictionary) -> void:
	if spell_id != "bemidji_blizzard":
		return
	sync_blizzard_interval()

func _on_blizzard_pocket_expired(pocket_id: int) -> void:
	sync_blizzard_interval(pocket_id)

func _on_blizzard_map_cleared() -> void:
	_apply_blizzard_interval_factor(1.0)

func _process(_delta: float) -> void:
	if is_ghost or destroyed:
		return

func _is_raid_hurtbox(hurt_box: Hurtbox) -> bool:
	if hurt_box == null or not is_instance_valid(hurt_box):
		return false
	var owner_node: Node = hurt_box.get_parent()
	if owner_node is Enemy:
		return bool((owner_node as Enemy).raids_buildings)
	return false

func _ensure_hitbox() -> void:
	var hitbox: Node = get_node_or_null("Hitbox")
	if hitbox == null and HITBOX_SCENE:
		hitbox = HITBOX_SCENE.instantiate()
		hitbox.name = "Hitbox"
		add_child(hitbox)
		if collision_shape_2d and collision_shape_2d.shape:
			var shape_node := CollisionShape2D.new()
			shape_node.shape = collision_shape_2d.shape
			shape_node.position = collision_shape_2d.position
			hitbox.add_child(shape_node)
	if hitbox is Area2D:
		var area: Area2D = hitbox as Area2D
		area.collision_layer = RAID_HITBOX_LAYER
		area.collision_mask = 0
		area.monitoring = false
		area.monitorable = true
		if area.has_signal("Damaged"):
			if area.Damaged.is_connected(take_damage):
				area.Damaged.disconnect(take_damage)
			if not area.Damaged.is_connected(_on_hitbox_damaged):
				area.Damaged.connect(_on_hitbox_damaged)

func _spawn_health_bar() -> void:
	if HEALTH_BAR_SCENE == null:
		return
	if get_node_or_null("HealthBar") != null:
		_health_bar = get_node("HealthBar") as Node2D
		return
	_health_bar = HEALTH_BAR_SCENE.instantiate() as Node2D
	_health_bar.name = "HealthBar"
	var bar_y: float = -100.0
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		bar_y = sprite.position.y - 50.0
	_health_bar.position = Vector2(0.0, bar_y)
	add_child(_health_bar)

func _refresh_health_bar() -> void:
	if _health_bar == null or not is_instance_valid(_health_bar):
		_health_bar = get_node_or_null("HealthBar") as Node2D
	if _health_bar == null or not is_instance_valid(_health_bar):
		return
	var show_bar: bool = (not is_ghost) and (not destroyed) and str(name) != "ghost"
	_health_bar.visible = show_bar
	if _health_bar.has_method("set_health_ratio"):
		_health_bar.call("set_health_ratio", health_ratio())

func _configure_hp_replication() -> void:
	var sync := get_node_or_null("MultiplayerSynchronizer")
	if sync == null or sync.replication_config == null:
		return
	var config: SceneReplicationConfig = sync.replication_config
	for path in [NodePath(".:hitpoints"), NodePath(".:destroyed"), NodePath(".:salvage_hits_taken")]:
		if not config.has_property(path):
			config.add_property(path)
		config.property_set_spawn(path, true)
		config.property_set_replication_mode(path, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)

func _apply_destroyed_visuals() -> void:
	if collision_shape_2d:
		collision_shape_2d.disabled = true
		collision_shape_2d.set_deferred("disabled", true)
	set("collision_layer", 0)
	set("collision_mask", 0)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	_enable_salvage_hitbox()
	if not is_in_group("harvest_nodes"):
		add_to_group("harvest_nodes")
	if animation_player:
		animation_player.stop()
	_apply_rubble_sprite()
	_refresh_health_bar()

func _apply_rubble_sprite() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	if self is SmokeFactory:
		sprite.texture = SMOKE_RUBBLE
		sprite.hframes = 1
		sprite.vframes = 1
		sprite.frame = 0
		var stack_a := get_node_or_null("Sprite2D2")
		if stack_a is CanvasItem:
			(stack_a as CanvasItem).visible = false
		var stack_b := get_node_or_null("Sprite2D3")
		if stack_b is CanvasItem:
			(stack_b as CanvasItem).visible = false
	elif self is PaperFactory:
		sprite.texture = PAPER_RUBBLE
		sprite.hframes = 1
		sprite.vframes = 1
		sprite.frame = 0
		sprite.region_enabled = false
	elif self is IrsBuilding:
		sprite.texture = IRS_RUBBLE
		sprite.hframes = 1
		sprite.vframes = 1
		sprite.frame = 0
	elif has_method("try_restock_staples"):
		# Office Max: duck-type (avoid class_name cache holes in headless).
		sprite.texture = OFFICE_MAX_RUBBLE
		sprite.modulate = Color(1, 1, 1, 1)
		sprite.hframes = 1
		sprite.vframes = 1
		sprite.frame = 0
	elif has_method("apply_ruined_placeholder_visuals"):
		call("apply_ruined_placeholder_visuals")

func _on_hitbox_damaged(hurt_box: Hurtbox) -> void:
	if destroyed:
		_on_salvage_damaged(hurt_box)
	else:
		take_damage(hurt_box)

func _on_salvage_damaged(hurt_box: Hurtbox) -> void:
	if hurt_box == null:
		return
	var token: int = hurt_box.get_instance_id()
	if _hit_hurtboxes.has(token):
		return
	_hit_hurtboxes[token] = true
	apply_harvest_hit(hurt_box.get_parent())
	var scene_tree := get_tree()
	if scene_tree:
		scene_tree.create_timer(0.2).timeout.connect(func() -> void:
			_hit_hurtboxes.erase(token)
		)

func can_harvest_from(striker: Node) -> bool:
	if not destroyed or _salvage_done:
		return false
	if striker == null or not is_instance_valid(striker):
		return false
	if striker is DM:
		return false
	if not (striker is Player):
		return false
	if _is_fantasy_claimed(_world_of(striker)):
		return false
	if _is_fantasy_claimed(factory_origin()):
		return false
	return true

func is_harvest_prompt_target(striker: Node) -> bool:
	if not can_harvest_from(striker):
		return false
	if not (striker is Node2D):
		return false
	return (striker as Node2D).global_position.distance_to(factory_origin()) <= HARVEST_HINT_RANGE

func shows_harvest_progress() -> bool:
	if not destroyed or _salvage_done:
		return false
	return salvage_hits_taken > 0 and salvage_hits_required > 0

func harvest_progress() -> float:
	if salvage_hits_required <= 0:
		return 0.0
	return clampf(float(salvage_hits_taken) / float(salvage_hits_required), 0.0, 1.0)

func apply_harvest_hit(striker: Node) -> bool:
	if not multiplayer.is_server():
		return false
	if not can_harvest_from(striker):
		return false
	salvage_hits_taken += 1
	if salvage_hits_taken < salvage_hits_required:
		_replicate_salvage()
		return true
	_grant_iron(striker)
	_clear_ruins()
	return true

func _enable_salvage_hitbox() -> void:
	var hitbox := get_node_or_null("Hitbox")
	if not (hitbox is Area2D):
		return
	var area: Area2D = hitbox as Area2D
	area.collision_layer = HARVEST_HITBOX_LAYER
	area.collision_mask = 0
	area.monitoring = false
	area.set_deferred("monitorable", true)

func _grant_iron(striker: Node) -> void:
	var player_id: int = 0
	if striker is Player:
		player_id = int((striker as Player).get_multiplayer_authority())
		if player_id <= 0 and striker.name.is_valid_int():
			player_id = int(striker.name)
	var iron: ItemData = ItemDatabase.get_item(IRON_ITEM)
	if iron == null:
		iron = load(IRON_ITEM) as ItemData
	if iron == null:
		return
	PlayerManager.grant_item_or_drop(player_id, iron, 1, factory_origin())

func _clear_ruins() -> void:
	if _salvage_done:
		return
	_salvage_done = true
	queue_free()

func _replicate_salvage() -> void:
	if not multiplayer.is_server():
		return
	sync_salvage_hits.rpc(salvage_hits_taken)

@rpc("authority", "call_remote", "reliable")
func sync_salvage_hits(hits: int) -> void:
	salvage_hits_taken = hits

func _world_of(node: Node) -> Vector2:
	if node is Node2D:
		return (node as Node2D).global_position
	return factory_origin()

func _is_fantasy_claimed(world: Vector2) -> bool:
	var scene_tree := get_tree()
	if scene_tree == null:
		return false
	var zone: Node = scene_tree.get_first_node_in_group("FantasyZone")
	if zone == null or not zone.has_method("is_claimed_world"):
		return false
	return bool(zone.is_claimed_world(world))
