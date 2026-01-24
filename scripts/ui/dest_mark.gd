@tool
extends Node2D

@export var color: Color = Color(0.8, 0.2, 0.2, 1.0)
@export var size: float = 40.0

func _draw():
	var stroke_width = 4.0
	var offset = size / 2.0
	
	# Hand-drawn feel: Use curves instead of straight lines
	# Stroke 1: Top-Left to Bottom-Right
	var p1 = Vector2(-offset, -offset)
	var p2 = Vector2(offset, offset)
	var c1 = Vector2(5, -5) # Control point slight bend
	_draw_curved_line(p1, p2, c1, color, stroke_width)
	
	# Stroke 2: Top-Right to Bottom-Left
	var p3 = Vector2(offset, -offset)
	var p4 = Vector2(-offset, offset)
	var c2 = Vector2(-5, -5) # Control point slight bend
	_draw_curved_line(p3, p4, c2, color, stroke_width)
	
	# Ink dots at ends
	for p in [p1, p2, p3, p4]:
		draw_circle(p, stroke_width * 0.7, color)

func _draw_curved_line(start, end, control, col, width):
	var points = PackedVector2Array()
	var steps = 10
	for i in range(steps + 1):
		var t = float(i) / steps
		# Quadratic Bezier: (1-t)^2 * P0 + 2(1-t)t * P1 + t^2 * P2
		var q = start.lerp(control, t).lerp(control.lerp(end, t), t)
		points.append(q)
	draw_polyline(points, col, width, true)

func _process(delta):
	queue_redraw()
	# Bob/Pulse
	scale = Vector2.ONE * (1.0 + 0.1 * sin(Time.get_ticks_msec() * 0.005))
