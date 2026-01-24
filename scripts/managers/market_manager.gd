extends Node

var current_prices: Dictionary = {}
var avg_costs: Dictionary = {} # Name: AvgPrice

func _ready():
	avg_costs = {"Timber": 0.0, "Fish": 0.0, "Sugarcane": 0.0}

func randomize_market_prices(all_items: Array[ItemData]):
	for item in all_items:
		var mult = randf_range(0.7, 1.4)
		current_prices[item.name] = int(item.base_price * mult)

func calculate_transaction(item_name: String, amount: int, is_buying: bool, player_gold: int) -> Dictionary:
	var price = current_prices.get(item_name, 0)
	var cost = amount * price
	
	if is_buying:
		if player_gold >= cost:
			return {"success": true, "cost": cost}
		else:
			return {"success": false, "reason": "Not enough gold"}
	else:
		return {"success": true, "gain": cost}

func update_avg_cost(item_name: String, amount: int, cost: int, current_owned: int):
	# Weighted Average
	var old_val = current_owned * avg_costs.get(item_name, 0.0)
	avg_costs[item_name] = (old_val + cost) / (current_owned + amount)

func reset_avg_cost(item_name: String):
	avg_costs[item_name] = 0.0
