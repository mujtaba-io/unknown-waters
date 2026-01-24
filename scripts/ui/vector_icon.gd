@tool
extends Control

enum IconType {
	GOLD,
	CARGO,
	HULL,
	LOCATION,
	NONE
}

@export var icon_type: IconType = IconType.NONE:
	set(value):
		icon_type = value
		queue_redraw()

@export var color: Color = Color(0.9, 0.85, 0.7, 1.0) # Light parchment color

func _draw():
	var center = size / 2.0
	var radius = min(size.x, size.y) * 0.4
	
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	
	match icon_type:
		IconType.GOLD:
			_draw_coin(center, radius)
		IconType.CARGO:
			_draw_crate(center, radius)
		IconType.HULL:
			_draw_ship_hull(center, radius)
		IconType.LOCATION:
			_draw_compass(center, radius)

func _draw_coin(center: Vector2, radius: float):
	# Outer circle
	draw_arc(center, radius, 0, TAU, 32, color, 3.0, true)
	# Inner circle
	draw_arc(center, radius * 0.7, 0, TAU, 24, color, 1.5, true)
	# Dollar/Gold symbol or simple markings
	var w = radius * 0.3
	draw_line(center - Vector2(0, w), center + Vector2(0, w), color, 2.0)

func _draw_crate(center: Vector2, radius: float):
	var s = radius * 1.6 # size of box
	var rect = Rect2(center - Vector2(s/2, s/2), Vector2(s, s))
	# Box outline
	draw_rect(rect, color, false, 3.0)
	# Diagonal lines
	draw_line(rect.position, rect.end, color, 1.5)
	draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), color, 1.5)

func _draw_ship_hull(center: Vector2, radius: float):
	# Simple boat shape
	var w = radius * 1.5
	var h = radius * 0.8
	var bottom_y = center.y + h * 0.5
	var top_y = center.y - h * 0.2
	
	var points = PackedVector2Array([
		Vector2(center.x - w * 0.4, top_y), # Top Left
		Vector2(center.x + w * 0.4, top_y), # Top Right
		Vector2(center.x + w * 0.3, bottom_y), # Bottom Right
		Vector2(center.x - w * 0.3, bottom_y), # Bottom Left
		Vector2(center.x - w * 0.4, top_y) # Close loop
	])
	draw_polyline(points, color, 3.0, true)
	
	# Mast
	draw_line(Vector2(center.x, top_y), Vector2(center.x, top_y - h), color, 3.0)
	# Sail
	var sail_points = PackedVector2Array([
		Vector2(center.x, top_y - h * 0.2),
		Vector2(center.x + w * 0.3, top_y - h * 0.6),
		Vector2(center.x, top_y - h * 0.9)
	])
	draw_polyline(sail_points, color, 2.0)

func _draw_compass(center: Vector2, radius: float):
	# Circle
	draw_arc(center, radius, 0, TAU, 32, color, 2.0, true)
	# Needle
	var needle_len = radius * 0.8
	draw_line(center - Vector2(0, needle_len), center + Vector2(0, needle_len), color, 1.5)
	draw_line(center - Vector2(needle_len, 0), center + Vector2(needle_len, 0), color, 1.5)
	
	# Arrow head (North)
	var arrow_pts = PackedVector2Array([
		center - Vector2(0, needle_len),
		center - Vector2(radius * 0.2, needle_len * 0.6),
		center + Vector2(radius * 0.2, needle_len * 0.6)
	])
	# Fill arrow head
	draw_colored_polygon(arrow_pts, color)
