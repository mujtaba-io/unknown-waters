extends Node

# --- NAVIGATION & WORLD ---
signal navigation_requested(target_pos: Vector2, location_name: String)
signal reached_destination
signal storm_started

# --- BATTLE ---
signal battle_started
signal battle_ended(won: bool)

# --- ECONOMY ---
signal transaction_completed(item_name: String, amount: int, is_buy: bool)

# --- SYSTEM ---
# Generic signals that might be deprecated later but needed for transition
signal stats_changed 
