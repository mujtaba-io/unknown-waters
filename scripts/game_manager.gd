extends Node

signal stats_changed
signal navigation_requested(target_pos, location_name)
signal battle_started
signal storm_started
signal battle_ended(won)

# --- CONFIG ---
@export_group("Database")
@export var all_items: Array[ItemData] = []
@export var ship_database: Array[ShipData] = []
@export var enemy_ship_database: Array[ShipData] = []

var all_ships: Dictionary = {} # Map name to Resource
var enemy_ships: Dictionary = {} # Map name to Resource

# --- PLAYER STATE ---
var gold: int = 1000
var current_ship_data: ShipData
var current_hull: int = 100
var inventory: Dictionary = {} # Name: Amount
var avg_costs: Dictionary = {} # Name: AvgPrice
var current_location_name: String = "Blackwater Bay"

# --- MARKET STATE ---
var current_prices: Dictionary = {}

func _ready():
	_build_databases()
	# Default setup
	set_ship("sloop")
	inventory = {"Timber": 0, "Fish": 0, "Sugarcane": 0}
	avg_costs = {"Timber": 0.0, "Fish": 0.0, "Sugarcane": 0.0}
	randomize_market_prices()

func _build_databases():
	# Populate dictionaries from exported arrays for O(1) lookup
	for ship in ship_database:
		if ship:
			all_ships[ship.id] = ship
			
	for ship in enemy_ship_database:
		if ship:
			enemy_ships[ship.id] = ship

func set_ship(ship_id: String):
	if ship_id in all_ships:
		current_ship_data = all_ships[ship_id]
		current_hull = current_ship_data.max_hull
		emit_signal("stats_changed")

func get_cargo_count() -> int:
	var total = 0
	for key in inventory:
		total += inventory[key]
	return total

func randomize_market_prices():
	for item in all_items:
		var mult = randf_range(0.7, 1.4)
		current_prices[item.name] = int(item.base_price * mult)

func transaction(item_name: String, amount: int, is_buying: bool):
	var price = current_prices[item_name]
	if is_buying:
		var total_cost = amount * price
		if gold >= total_cost:
			gold -= total_cost
			var old_val = inventory[item_name] * avg_costs[item_name]
			avg_costs[item_name] = (old_val + total_cost) / (inventory[item_name] + amount)
			inventory[item_name] += amount
	else:
		gold += amount * price
		inventory[item_name] -= amount
		if inventory[item_name] == 0:
			avg_costs[item_name] = 0.0
	
	emit_signal("stats_changed")
