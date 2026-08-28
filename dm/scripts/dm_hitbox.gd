class_name DmHitbox extends Hitbox

func take_damage(hurt_box: Hurtbox) -> void:
	if not multiplayer.is_server():
		return
	var dm := get_parent() as DM
	if dm == null or dm.invulnerable:
		return
	var attacker: Node = hurt_box.get_parent() if hurt_box else null
	if attacker and attacker.has_method("can_damage_dm") and not attacker.can_damage_dm():
		return
	Damaged.emit(hurt_box)
	dm.apply_fantasy_hit(maxi(1, hurt_box.damage))
