extends Node

# --- Inventory Signals ---
# Emitted when the local player's inventory changes. 
# 'display_list' will be an Array of Dictionaries: [{"data": ItemData, "quantity": int}]
signal inventory_updated(display_list: Array)
signal inventory_slots_changed
