extends Node2D

signal reached_destination

const SHIP_SPEED = 125.0
const EVENT_CHANCE_TICK = 0.004

@onready var ship = $Ship
@onready var trail_line = $TrailLine 
@onready var dest_mark = $DestMark
@onready var nav_agent = $Ship/NavigationAgent2D

var target_pos: Vector2
var is_moving: bool = false
var nav_timer: float = 0.0
var trip_time: float = 0.0
var current_port_node: Node2D = null

func _ready():
	# Initialize ship look
	update_ship_visuals()
	GameManager.stats_changed.connect(update_ship_visuals)
	
	# Connect Islands
	for node in $Islands.get_children():
		if node is Area2D:
			node.input_event.connect(_on_island_input.bind(node))
	
	# Set initial port correctly if we have a location
	_update_current_port_from_manager()
	
	# Initialize Trail Line
	if trail_line:
		trail_line.clear_points()
		trail_line.add_point(ship.position)
	
	if dest_mark:
		dest_mark.visible = false

func update_ship_visuals():
	if GameManager.current_ship_data:
		if GameManager.current_ship_data.texture:
			$Ship/Sprite2D.texture = GameManager.current_ship_data.texture
			$Ship/Sprite2D.scale = GameManager.current_ship_data.texture_scale
			$Ship/Sprite2D.visible = true
		else:
			$Ship/Gfx.polygon = GameManager.current_ship_data.visual_polygon
			$Ship/Gfx.color = GameManager.current_ship_data.color
			$Ship/Gfx.visible = true

func set_destination(pos: Vector2):
	target_pos = pos
	is_moving = true
	
	# Setup Navigation
	nav_agent.target_position = target_pos
	
	ship.modulate = Color(1, 1, 1, 1) # Force visible
	trip_time = 0.0
	
	# Show X Mark
	if dest_mark:
		dest_mark.position = pos
		dest_mark.visible = true
	
	# Reset trail for new journey
	if trail_line:
		trail_line.clear_points()
		trail_line.add_point(ship.position)
	
	# Make all ports fully visible when leaving
	_set_all_ports_visible(true)
	current_port_node = null

func _process(delta):
	if is_moving:
		_process_movement(delta)
	else:
		_process_idle_port_anim(delta)

func _process_movement(delta):
	# Check if reached destination
	if nav_agent.is_navigation_finished():
		ship.position = target_pos # Snap to exact target
		is_moving = false
		if dest_mark: dest_mark.visible = false
		_update_current_port_from_manager()
		emit_signal("reached_destination")
		return

	trip_time += delta
	
	# Get next path position from navigation agent
	var next_path_pos = nav_agent.get_next_path_position()
	var dir = ship.position.direction_to(next_path_pos)
	
	# ship.rotation = lerp_angle(ship.rotation, dir.angle(), 8.0 * delta) # DISABLED ROTATION
	ship.position += dir * SHIP_SPEED * delta
	
	nav_timer += delta
	if nav_timer > 0.1:
		if trail_line: trail_line.add_point(ship.position)
		nav_timer = 0.0
	
	# Random Encounter Check
	var dist_to_target = ship.position.distance_to(target_pos)
	if trip_time > 1.0 and dist_to_target > 50.0 and randf() < EVENT_CHANCE_TICK:
		is_moving = false # Pause movement
		if randf() < 0.3:
			GameManager.emit_signal("storm_started")
		else:
			GameManager.emit_signal("battle_started")

func _process_idle_port_anim(delta):
	# Port should be static
	if current_port_node:
		current_port_node.get_node("Visual").modulate = Color(1, 1, 1, 1)
	
	# Hard Blink for Ship (0.0 or 1.0)
	var time = Time.get_ticks_msec() * 0.005
	var blink_on = sin(time) > 0.0
	ship.modulate = Color(1, 1, 1, 1.0 if blink_on else 0.0)

func resume_journey():
	is_moving = true
	ship.modulate = Color(1, 1, 1, 1) # Ensure visible immediately
	_set_all_ports_visible(true)

func _on_island_input(_vp, event, _idx, node):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_moving:
			var dest_name = node.get_meta("name")
			if dest_name != GameManager.current_location_name:
				GameManager.emit_signal("navigation_requested", node.position, dest_name)

func _update_current_port_from_manager():
	current_port_node = null
	for node in $Islands.get_children():
		if node is Area2D and node.get_meta("name") == GameManager.current_location_name:
			current_port_node = node
			break

func _set_all_ports_visible(vis: bool):
	for node in $Islands.get_children():
		if node is Area2D:
			node.get_node("Visual").modulate = Color(1, 1, 1, 1)
