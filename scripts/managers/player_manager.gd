extends Node

var gold: int = 1000
var current_ship_data: ShipData
var current_hull: int = 100

func set_ship(ship_id: String):
	# We access the ship database via GameManager for now, or we can load it here
	# To keep it simple, we'll assume GameManager still holds the DB references until Phase 5
	if ship_id in GameManager.all_ships:
		current_ship_data = GameManager.all_ships[ship_id]
		current_hull = current_ship_data.max_hull
		Events.emit_signal("stats_changed")

func deduct_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		Events.emit_signal("stats_changed")
		return true
	return false

func add_gold(amount: int):
	gold += amount
	Events.emit_signal("stats_changed")

func damage_ship(amount: int):
	current_hull -= amount
	if current_hull < 0: current_hull = 0
	Events.emit_signal("stats_changed")

func repair_full(cost: int):
	if deduct_gold(cost):
		current_hull = current_ship_data.max_hull
		Events.emit_signal("stats_changed")
