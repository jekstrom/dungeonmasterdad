extends Node

@warning_ignore("unused_signal")
signal inventory_updated(display_list: Array)
@warning_ignore("unused_signal")
signal inventory_slots_changed
@warning_ignore("unused_signal")
signal build_smoke_building_pressed
signal on_dm_unlock(unlock_name: String)
signal start_spell_cast(spell_id: String)
signal spell_cast(spell_id: String, spell_data: Dictionary)
signal on_explosion(position: Vector2, data: Dictionary)
signal shadow_zone_changed(val: bool)
signal on_item_pickup
signal player_died(player_id: int, death_position: Vector2)
signal inventory_dropped(player_id: int, drop_position: Vector2)
signal player_respawned(player_id: int, respawn_position: Vector2)
