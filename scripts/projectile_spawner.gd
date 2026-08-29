extends MultiplayerSpawner

# TODO: key this on spell id
@export
var projectile_scene: PackedScene

const STAPLE_PROJECTILE_SCENE: PackedScene = preload("res://player/staple_projectile.tscn")
const CARBONATED_JET_SCENE: PackedScene = preload("res://monsters/carbonated_jet.tscn")

@export
var staple_scene: PackedScene

func _enter_tree():
	set_multiplayer_authority(1)
	add_to_group("projectile_spawner")

func _ready():
	_ensure_spawn_function()
	set_multiplayer_authority(1)
	add_spawnable_scene("res://player/staple_projectile.tscn")
	add_spawnable_scene("res://monsters/carbonated_jet.tscn")
	
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
	# US-027 Carbonated Jet. Keep fireball as the default branch below so
	# US-005 staple_fire_test still instantiates FireballSpell.
	if str(data.get("kind", "")) == "carbonated_jet":
		var jet = CARBONATED_JET_SCENE.instantiate()
		jet.shooter_id = int(data.get("shooter_id", 0))
		jet.position = data.get("position", Vector2.ZERO)
		jet.direction = data.get("direction", Vector2.RIGHT)
		if data.has("damage"):
			jet.damage = int(data.damage)
		if data.has("speed"):
			jet.speed = float(data.speed)
		if data.has("max_range"):
			jet.max_range = float(data.max_range)
		if data.has("shooter_path"):
			jet.shooter_path = data.shooter_path
		return jet
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

func spawn_carbonated_jet(data: Dictionary) -> Node:
	# US-027 Carbonated Jet. Host-only. Not US-018 fireball.
	if !multiplayer.is_server():
		return null
	_ensure_spawn_function()
	data["kind"] = "carbonated_jet"
	return spawn(data)

func on_spell_cast(spell_id: String, spell_data: Dictionary) -> void:
	if spell_id == "fireball":
		spawn_bullet(spell_data)
