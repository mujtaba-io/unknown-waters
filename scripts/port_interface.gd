extends Control
class_name PortInterface

@onready var market_list = $MarketLayer/Margin/VBox/Scroll/ItemContainer
@onready var shipyard_ui = $ShipyardLayer
@onready var trans_panel = $Overlay/TransactionPanel

enum PortView { PORT, MARKET, SHIPYARD }
signal view_requested(view_name: PortView)

var ship_offer_id: String = ""

func _ready():
	var m_btn = $PortLayer/Center/HBox/MarketBtn
	var s_btn = $PortLayer/Center/HBox/ShipyardBtn
	m_btn.pressed.connect(func(): emit_signal("view_requested", PortView.MARKET))
	s_btn.pressed.connect(func(): emit_signal("view_requested", PortView.SHIPYARD))
	
	UIAnimator.pulse_hover(m_btn, 1.05)
	UIAnimator.pulse_hover(s_btn, 1.05)
	
	# Hide Back buttons as they are now handled by main button
	$MarketLayer/Margin/VBox/HBox/BackBtn.visible = false
	$ShipyardLayer/Margin/VBox/BackBtn.visible = false
	
	# Transaction Panel Connections
	var vb = trans_panel.get_node("VBox")
	vb.get_node("HBox/MaxBtn").pressed.connect(_on_trans_max)
	vb.get_node("HBox2/Confirm").pressed.connect(_on_trans_confirm)
	vb.get_node("HBox2/Cancel").pressed.connect(func(): trans_panel.visible = false)
func show_view(v_name: PortView):
	if v_name == PortView.PORT: _show_home()
	elif v_name == PortView.MARKET: _show_market()
	elif v_name == PortView.SHIPYARD: _show_shipyard()

func setup_port():
	_show_home()
	$PortLayer/Header/Label.text = GameManager.current_location_name
	
	# Generate Ship Offer
	ship_offer_id = ""
	if randf() < 0.5:
		var keys = GameManager.all_ships.keys()
		var pick = keys.pick_random()
		if pick != GameManager.current_ship_data.id:
			ship_offer_id = pick

func _show_home():
	$PortLayer.visible = true
	$MarketLayer.visible = false
	$ShipyardLayer.visible = false

func _show_market():
	$PortLayer.visible = false
	$MarketLayer.visible = true
	_refresh_market_list()

func _refresh_market_list():
	for c in market_list.get_children(): c.queue_free()
	
	for item in GameManager.all_items:
		var row = HBoxContainer.new()
		var price = GameManager.current_prices[item.name]
		var owned = GameManager.inventory[item.name]
		var avg = GameManager.avg_costs[item.name]
		
		# Labels
		var lbl = Label.new()
		lbl.text = "%s (%d g) | Owned: %d" % [item.name, price, owned]
		lbl.size_flags_horizontal = 3
		
		# Color Logic
		if owned > 0:
			if price > avg: lbl.add_theme_color_override("font_color", Color.GREEN)
			elif price < avg: lbl.add_theme_color_override("font_color", Color.RED)
		else:
			lbl.add_theme_color_override("font_color", Color.YELLOW)
			
		row.add_child(lbl)
		
		# Buttons
		var btn_buy = Button.new()
		btn_buy.text = "BUY"
		btn_buy.pressed.connect(_open_transaction.bind(item.name, "BUY"))
		
		var btn_sell = Button.new()
		btn_sell.text = "SELL"
		btn_sell.pressed.connect(_open_transaction.bind(item.name, "SELL"))
		if owned == 0: btn_sell.disabled = true
		
		row.add_child(btn_buy)
		row.add_child(btn_sell)
		market_list.add_child(row)

func _show_shipyard():
	$PortLayer.visible = false
	$ShipyardLayer.visible = true
	_update_shipyard_ui()

func _update_shipyard_ui():
	var hull_cost = (GameManager.current_ship_data.max_hull - GameManager.current_hull) * 5
	var lbl = $ShipyardLayer/Margin/VBox/InfoLbl
	lbl.text = "Hull: %d/%d (Repair: %d g)" % [GameManager.current_hull, GameManager.current_ship_data.max_hull, hull_cost]
	
	var repair_btn = $ShipyardLayer/Margin/VBox/RepairBtn
	if repair_btn.is_connected("pressed", _on_repair): repair_btn.disconnect("pressed", _on_repair)
	repair_btn.pressed.connect(_on_repair.bind(hull_cost))
	repair_btn.disabled = (hull_cost == 0 or GameManager.gold < hull_cost)
	
	# Ship Buying Logic (Simplified)
	var buy_lbl = $ShipyardLayer/Margin/VBox/OfferLbl
	var buy_btn = $ShipyardLayer/Margin/VBox/BuyShipBtn
	
	if ship_offer_id != "":
		var s_data = GameManager.all_ships[ship_offer_id]
		buy_lbl.text = "For Sale: %s (%d g)" % [s_data.name, s_data.price]
		buy_btn.visible = true
		if buy_btn.is_connected("pressed", _on_buy_ship): buy_btn.disconnect("pressed", _on_buy_ship)
		buy_btn.pressed.connect(_on_buy_ship.bind(ship_offer_id))
		buy_btn.disabled = (GameManager.gold < s_data.price)
	else:
		buy_lbl.text = "No ships for sale."
		buy_btn.visible = false

func _on_repair(cost):
	GameManager.gold -= cost
	GameManager.current_hull = GameManager.current_ship_data.max_hull
	GameManager.emit_signal("stats_changed")
	_update_shipyard_ui()

func _on_buy_ship(s_id):
	var data = GameManager.all_ships[s_id]
	GameManager.gold -= data.price
	GameManager.set_ship(s_id)
	ship_offer_id = ""
	_update_shipyard_ui()

var t_item: String
var t_mode: String
var t_max: int





func _open_transaction(item, mode):
	t_item = item
	t_mode = mode
	var price = GameManager.current_prices[item]
	
	if mode == "BUY":
		var space = GameManager.current_ship_data.cargo_capacity - GameManager.get_cargo_count()
		var afford = floor(GameManager.gold / float(price))
		t_max = int(min(space, afford))
	else:
		t_max = GameManager.inventory[item]
	
	var vb = trans_panel.get_node("VBox")
	vb.get_node("Title").text = "%s %s" % [mode, item]
	vb.get_node("SpinBox").value = 0
	vb.get_node("SpinBox").max_value = t_max
	trans_panel.visible = true

func _on_trans_max():
	trans_panel.get_node("VBox/SpinBox").value = t_max

func _on_trans_confirm():
	var val = int(trans_panel.get_node("VBox/SpinBox").value)
	if val > 0:
		GameManager.transaction(t_item, val, t_mode == "BUY")
		_refresh_market_list()
	trans_panel.visible = false
