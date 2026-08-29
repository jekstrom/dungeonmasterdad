extends Node

@warning_ignore("unused_signal")
signal inventory_updated(display_list: Array)
@warning_ignore("unused_signal")
signal inventory_slots_changed
@warning_ignore("unused_signal")
signal build_smoke_building_pressed
@warning_ignore("unused_signal")
signal build_paper_building_pressed(building: String)

@warning_ignore("unused_signal")
signal on_dm_unlock(unlock_name: String)
@warning_ignore("unused_signal")
signal on_dm_lock(unlock_name: String)
@warning_ignore("unused_signal")
signal start_spell_cast(spell_id: String)
@warning_ignore("unused_signal")
signal spell_cast(spell_id: String, spell_data: Dictionary)
@warning_ignore("unused_signal")
signal on_explosion(position: Vector2, data: Dictionary)
@warning_ignore("unused_signal")
signal shadow_zone_changed(val: bool)
@warning_ignore("unused_signal")
signal on_item_pickup(player_id: int)
@warning_ignore("unused_signal")
signal shadow_increased(data: Dictionary)
@warning_ignore("unused_signal")
signal player_registered(player_id: int, player_name: String)
@warning_ignore("unused_signal")
signal player_unregistered(player_id: int)

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
signal on_item_drop(item_data: Dictionary)

# Respawn system signals
@warning_ignore("unused_signal")
signal player_respawn_delay_started(player_id: int, delay: float)
@warning_ignore("unused_signal")
signal respawn_location_selected(player_id: int, position: Vector2)
@warning_ignore("unused_signal")
signal player_respawn_completed(player_id: int, position: Vector2)

# Procedural dungeon generation lifecycle signals
@warning_ignore("unused_signal")
signal dungeon_generation_requested(request_id: String, requester_peer_id: int)
@warning_ignore("unused_signal")
signal dungeon_generation_succeeded(request_id: String, layout_id: String)
@warning_ignore("unused_signal")
signal dungeon_generation_failed(request_id: String, error_code: String, message: String)
@warning_ignore("unused_signal")
signal map_bounds_committed(interior: Rect2i)
@warning_ignore("unused_signal")
signal map_bounds_cleared

@warning_ignore("unused_signal")
signal reality_home_changed(home_rect: Rect2i)
@warning_ignore("unused_signal")
signal reality_pocket_created(pocket_id: int, rect: Rect2i, duration: float)
@warning_ignore("unused_signal")
signal reality_pocket_expired(pocket_id: int)
@warning_ignore("unused_signal")
signal reality_claim_changed
@warning_ignore("unused_signal")
signal reality_pocket_requested(origin: Vector2i, size: Vector2i, duration: float)

@warning_ignore("unused_signal")
signal fantasy_home_changed(home_rect: Rect2i)
@warning_ignore("unused_signal")
signal fantasy_pocket_created(pocket_id: int, rect: Rect2i, duration: float)
@warning_ignore("unused_signal")
signal fantasy_pocket_expired(pocket_id: int)
@warning_ignore("unused_signal")
signal fantasy_claim_changed
@warning_ignore("unused_signal")
signal fantasy_pocket_requested(origin: Vector2i, size: Vector2i, duration: float)
