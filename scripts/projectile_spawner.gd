extends MultiplayerSpawner

# TODO: key this on spell id
@export
var projectile_scene: PackedScene

const STAPLE_PROJECTILE_SCENE: PackedScene = preload("res://player/staple_projectile.tscn")

@export
var staple_scene: PackedScene

func _enter_tree():
	set_multiplayer_authority(1)
	add_to_group("projectile_spawner")

func _ready():
	_ensure_spawn_function()
	set_multiplayer_authority(1)
	add_spawnable_scene("res://player/staple_projectile.tscn")
	
	# Only connect to signals on server - clients shouldn't handle spawning  
	if multiplayer.is_server():
		SignalBus.spell_cast.connect(on_spell_cast)

func _ensure_spawn_function() -> void:
	spawn_function = _custom_spawn
	set_multiplayer_authority(1)

func _custom_spawn(data: Dictionary) -> Node2D:
	if str(data.get("kind", "")) == "staple":
		var scene: PackedScene = staple_scene if staple_scene else STAPLE_PROJECTILE_SCENE
		var p = scene.instantiate()
		p.shooter_id = int(data.get("shooter_id", 0))
		p.position = data.get("position", Vector2.ZERO)
		p.direction = data.get("direction", Vector2.RIGHT)
		if data.has("damage"):
			p.damage = int(data.damage)
		if data.has("speed"):
			p.speed = float(data.speed)
		if data.has("max_range"):
			p.max_range = float(data.max_range)
		return p
	var p = projectile_scene.instantiate()
	p.shooter_id = data.shooter_id
	p.position = data.position
	p.target = data.target
	p.radius += data.radius_bonus
	p.base_damage += data.base_damage_bonus
	p.speed += data.speed_bonus
	return p

func spawn_bullet(data: Dictionary):
	if !multiplayer.is_server(): return
	spawn(data)

func spawn_staple(data: Dictionary) -> Node:
	if !multiplayer.is_server():
		return null
	_ensure_spawn_function()
	data["kind"] = "staple"
	return spawn(data)

func on_spell_cast(spell_id: String, spell_data: Dictionary) -> void:
	if spell_id == "fireball":
		spawn_bullet(spell_data)
