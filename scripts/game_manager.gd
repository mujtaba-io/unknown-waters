extends Node

# Signals moved to Events autoload

# --- CONFIG ---
@export_group("Database")
@export var all_items: Array[ItemData] = []
@export var ship_database: Array[ShipData] = []
@export var enemy_ship_database: Array[ShipData] = []

var all_ships: Dictionary = {} # Map name to Resource
var enemy_ships: Dictionary = {} # Map name to Resource

# --- PLAYER STATE PROXIES ---
var gold: int:
	get: return PlayerManager.gold
	set(val): PlayerManager.gold = val

var current_ship_data: ShipData:
	get: return PlayerManager.current_ship_data
	set(val): PlayerManager.current_ship_data = val

var current_hull: int:
	get: return PlayerManager.current_hull
	set(val): PlayerManager.current_hull = val

var inventory: Dictionary:
	get: return InventoryManager.inventory
	set(val): InventoryManager.inventory = val

var avg_costs: Dictionary:
	get: return MarketManager.avg_costs
	set(val): MarketManager.avg_costs = val

var current_location_name: String = "Blackwater Bay"

# --- MARKET STATE PROXIES ---
var current_prices: Dictionary:
	get: return MarketManager.current_prices
	set(val): MarketManager.current_prices = val

func _ready():
	_build_databases()
	
	# Initial Setup
	# Note: Managers init their own defaults, but we can override or sync here if needed.
	# For now, we trust Managers' defaults or set specific start values.
	PlayerManager.set_ship("sloop")
	
	# Pass DB to MarketManager
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
		# Update PlayerManager
		PlayerManager.set_ship(ship_id)

func get_cargo_count() -> int:
	return InventoryManager.get_total_cargo()

func randomize_market_prices():
	MarketManager.randomize_market_prices(all_items)

func transaction(item_name: String, amount: int, is_buying: bool):
	# Calculate
	var result = MarketManager.calculate_transaction(item_name, amount, is_buying, gold)
	
	if result.success:
		if is_buying:
			PlayerManager.deduct_gold(result.cost)
			InventoryManager.add_item(item_name, amount)
			MarketManager.update_avg_cost(item_name, amount, result.cost, InventoryManager.get_item_count(item_name) - amount)
		else:
			PlayerManager.add_gold(result.gain)
			InventoryManager.remove_item(item_name, amount)
			if InventoryManager.get_item_count(item_name) == 0:
				MarketManager.reset_avg_cost(item_name)
		
		Events.emit_signal("transaction_completed", item_name, amount, is_buying)
		Events.emit_signal("stats_changed")
	else:
		push_warning("Transaction failed: " + result.get("reason", "Unknown"))
