extends Node

@warning_ignore("unused_signal")
signal inventory_updated(display_list: Array)
@warning_ignore("unused_signal")
signal inventory_slots_changed
@warning_ignore("unused_signal")
signal build_smoke_building_pressed
@warning_ignore("unused_signal")
signal on_dm_unlock(unlock_name: String)
@warning_ignore("unused_signal")
signal start_spell_cast(spell_id: String)
@warning_ignore("unused_signal")
signal spell_cast(spell_id: String, spell_data: Dictionary)
@warning_ignore("unused_signal")
signal on_explosion(position: Vector2, data: Dictionary)
@warning_ignore("unused_signal")
signal shadow_zone_changed(val: bool)
@warning_ignore("unused_signal")
signal on_item_pickup

# Death event signals (existing)
@warning_ignore("unused_signal")
signal player_died(player_id: int, death_position: Vector2)
@warning_ignore("unused_signal")
signal inventory_dropped(player_id: int, drop_position: Vector2)
@warning_ignore("unused_signal")
signal player_respawned(player_id: int, respawn_position: Vector2)

# Enhanced death event signals for new system
@warning_ignore("unused_signal")
signal player_death_requested(player_id: int, position: Vector2)
@warning_ignore("unused_signal")
signal player_death_processed(player_id: int, items: Array)

# Item system signals  
@warning_ignore("unused_signal")
signal items_dropped_at_location(items: Array, position: Vector2)
@warning_ignore("unused_signal")
signal item_pickup_requested(item_id: String, player_id: int)
@warning_ignore("unused_signal")
signal item_collected_successfully(item_id: String, collector: int)
@warning_ignore("unused_signal")
signal on_item_drop(item_data: Dictionary)

# Respawn system signals
@warning_ignore("unused_signal")
signal player_respawn_delay_started(player_id: int, delay: float)
@warning_ignore("unused_signal")
signal respawn_location_selected(player_id: int, position: Vector2)
@warning_ignore("unused_signal")
signal player_respawn_completed(player_id: int, position: Vector2)
