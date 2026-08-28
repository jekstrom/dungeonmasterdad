extends MultiplayerSpawner

# TODO: key this on spell id
@export
var projectile_scene: PackedScene

func _enter_tree():
	set_multiplayer_authority(1)

func _ready():
	spawn_function = _custom_spawn
	set_multiplayer_authority(1)
	
	# Only connect to signals on server - clients shouldn't handle spawning  
	if multiplayer.is_server():
		SignalBus.spell_cast.connect(on_spell_cast)

func _custom_spawn(data: Dictionary) -> Node2D:
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

func on_spell_cast(spell_id: String, spell_data: Dictionary) -> void:
	if spell_id == "fireball":
		spawn_bullet(spell_data)
