extends Node

var inventory: Dictionary = {} # Name: Amount

func _ready():
	# Default inventory
	inventory = {"Timber": 0, "Fish": 0, "Sugarcane": 0}

func add_item(item_name: String, amount: int):
	if item_name not in inventory:
		inventory[item_name] = 0
	inventory[item_name] += amount
	Events.emit_signal("stats_changed")

func remove_item(item_name: String, amount: int) -> bool:
	if get_item_count(item_name) >= amount:
		inventory[item_name] -= amount
		Events.emit_signal("stats_changed")
		return true
	return false

func get_item_count(item_name: String) -> int:
	return inventory.get(item_name, 0)

func get_total_cargo() -> int:
	var total = 0
	for key in inventory:
		total += inventory[key]
	return total
