extends Node

@onready var world_map = $GameWorld
@onready var port_ui: PortInterface = $UI/PortInterface
@onready var battle_view: BattleView = $UI/BattleLayer
@onready var hud = $UI/Sidebar
@onready var popup = $UI/Overlay/MessagePopup
@onready var story_panel = $UI/Overlay/StoryPanel
@onready var action_btn = $UI/ActionButton

enum State { PORT, SAILING, BATTLE, PORT_SUBMENU }
var current_state: State = State.PORT

func _ready():
	# Connect Global Signals
	GameManager.navigation_requested.connect(_on_sail_requested)
	GameManager.battle_started.connect(_on_battle_encounter)
	GameManager.storm_started.connect(_on_storm_encounter)
	GameManager.stats_changed.connect(_update_hud)
	
	# Connect Local Signals
	world_map.reached_destination.connect(_on_arrival)
	battle_view.battle_finished.connect(_on_battle_end)
	action_btn.pressed.connect(_on_action_btn)
	port_ui.view_requested.connect(_on_port_view_changed)
	
	# Sidebar Buttons
	var btns = $UI/Sidebar/Margin/VBox/Buttons
	btns.get_node("ExitBtn").pressed.connect(_on_exit_btn)
	btns.get_node("StoryBtn").pressed.connect(_on_story_btn)
	# Optional: Map MenuBtn to same exit logic or other menu
	btns.get_node("MenuBtn").pressed.connect(_on_exit_btn)
	
	story_panel.get_node("CloseBtn").pressed.connect(func(): story_panel.visible = false)
	
	_update_hud()
	port_ui.setup_port()
	_switch_to_port()
	
	# Animations
	var vbox = $UI/Sidebar/Margin/VBox
	UIAnimator.float_loop(vbox.get_node("GoldPanel/GoldRow/GoldIcon"), 5.0, 3.0)
	UIAnimator.float_loop(vbox.get_node("CargoPanel/CargoRow/CargoIcon"), 5.0, 3.5)
	UIAnimator.float_loop(vbox.get_node("HullPanel/HullRow/HullIcon"), 5.0, 4.0)
	UIAnimator.float_loop(vbox.get_node("LocPanel/LocRow/LocIcon"), 5.0, 4.5)
	
	UIAnimator.pulse_hover(action_btn, 1.05)

func _on_story_btn():
	story_panel.visible = true

func _on_exit_btn():
	# Return to Main Menu
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_port_view_changed(view_name: PortInterface.PortView):
	# MARKET or SHIPYARD
	if view_name == PortInterface.PortView.MARKET or view_name == PortInterface.PortView.SHIPYARD:
		port_ui.show_view(view_name)
		action_btn.text = "Back to Port"
		current_state = State.PORT_SUBMENU

func _on_storm_encounter():
	_show_popup("STORM WARNING", "The winds are blowing you off course!")
	await popup.find_child("OkBtn").pressed
	popup.visible = false
	
	# Pick random different port
	var islands = world_map.get_node("Islands").get_children()
	var candidates = []
	for node in islands:
		if node is Area2D and node.get_meta("name") != GameManager.current_location_name:
			candidates.append(node)
	
	if candidates.size() > 0:
		var dest = candidates.pick_random()
		GameManager.current_location_name = dest.get_meta("name")
		world_map.set_destination(dest.position)
		_update_hud()
	
	world_map.resume_journey()

func _update_hud():
	var h = $UI/Sidebar/Margin/VBox
	h.get_node("GoldPanel/GoldRow/GoldVal").text = str(GameManager.gold) + " Gold"
	h.get_node("CargoPanel/CargoRow/CargoVal").text = "%d / %d" % [GameManager.get_cargo_count(), GameManager.current_ship_data.cargo_capacity]
	h.get_node("HullPanel/HullRow/HullVal").text = "%d / %d" % [GameManager.current_hull, GameManager.current_ship_data.max_hull]
	h.get_node("LocPanel/LocRow/LocationVal").text = GameManager.current_location_name

func _on_sail_requested(pos: Vector2, dest_name: String):
	_switch_to_sailing()
	GameManager.current_location_name = dest_name
	world_map.set_destination(pos)
	_update_hud()

func _switch_to_port():
	current_state = State.PORT
	port_ui.visible = true
	port_ui.show_view(PortInterface.PortView.PORT)
	world_map.visible = false
	battle_view.visible = false
	action_btn.text = "Set Sail"
	action_btn.disabled = false

func _switch_to_sailing():
	current_state = State.SAILING
	port_ui.visible = false
	world_map.visible = true
	battle_view.visible = false
	action_btn.text = "Sailing..."
	action_btn.disabled = true

func _on_arrival():
	GameManager.randomize_market_prices()
	port_ui.setup_port()
	_switch_to_port()

func _on_action_btn():
	if current_state == State.SAILING and not world_map.is_moving:
		_switch_to_port()
	elif current_state == State.PORT:
		_switch_to_sailing()
		# Logic to just show map without moving
		action_btn.text = "Back to Port"
		action_btn.disabled = false
	elif current_state == State.PORT_SUBMENU:
		_switch_to_port()
	elif current_state == State.BATTLE:
		battle_view.flee()

# --- BATTLE LOGIC ---
func _on_battle_encounter():
	current_state = State.BATTLE
	popup.visible = true
	popup.find_child("Title").text = "PIRATES!"
	popup.find_child("Msg").text = "Click OK to fight!"
	
	# Pause map until popup accepted
	await popup.find_child("OkBtn").pressed
	popup.visible = false
	
	world_map.visible = false
	battle_view.start_battle()
	action_btn.text = "FLEE"
	action_btn.disabled = false

func _on_battle_end(result: BattleView.BattleResult):
	if result == BattleView.BattleResult.WON:
		var loot = randi_range(50, 200)
		GameManager.gold += loot
		_show_popup("VICTORY", "Looted %d Gold." % loot)
		await popup.find_child("OkBtn").pressed
		popup.visible = false
		_resume_sailing()
	elif result == BattleView.BattleResult.ESCAPED:
		_show_popup("ESCAPED", "You outran them.")
		await popup.find_child("OkBtn").pressed
		popup.visible = false
		_resume_sailing()
	elif result == BattleView.BattleResult.LOST:
		_show_popup("GAME OVER", "You lost your ship! (Penalty: 500 Gold)")
		await popup.find_child("OkBtn").pressed
		popup.visible = false
		
		# Reset Logic
		GameManager.gold = max(0, GameManager.gold - 500)
		GameManager.set_ship("sloop")
		GameManager.inventory = {"Timber": 0, "Fish": 0, "Sugarcane": 0}
		GameManager.current_location_name = "Alpha Harbor"
		GameManager.current_hull = 100
		
		# Move ship visually to Alpha Harbor
		var alpha_harbor = world_map.get_node("Islands/IslandAlpha")
		if alpha_harbor:
			world_map.ship.position = alpha_harbor.position
		
		GameManager.emit_signal("stats_changed")
		_switch_to_port()

func _resume_sailing():
	current_state = State.SAILING
	world_map.visible = true
	battle_view.visible = false
	action_btn.text = "Sailing..."
	action_btn.disabled = true
	world_map.resume_journey()

func _show_popup(title, msg):
	popup.visible = true
	popup.find_child("Title").text = title
	popup.find_child("Msg").text = msg
