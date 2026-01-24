extends Node2D

var points: PackedVector2Array = PackedVector2Array()
@export var color: Color = Color("8a2e2e")
@export var width: float = 2.0
@export var dash_length: float = 10.0

func add_point(pos: Vector2):
	points.append(pos)
	queue_redraw()

func clear_points():
	points.clear()
	queue_redraw()

func _draw():
	if points.size() < 2: return
	
	# Draw dashed line
	draw_dashed_line_poly(points, color, width, dash_length)
	
	# Draw X mark at the last point
	if not points.is_empty():
		var end_pos = points[points.size() - 1]
		var s = 2.0 # Scale for the X mark
		# Similar style to the user's reference X_MARK
		draw_line(end_pos + Vector2(-5*s, -5*s), end_pos + Vector2(5*s, 5*s), color, 3.0)
		draw_line(end_pos + Vector2(5*s, -5*s), end_pos + Vector2(-5*s, 5*s), color, 3.0)

func draw_dashed_line_poly(points_list: PackedVector2Array, line_color: Color, line_width: float, dash: float):
	for i in range(points_list.size() - 1):
		var p1 = points_list[i]
		var p2 = points_list[i+1]
		var dist = p1.distance_to(p2)
		var steps = int(dist / (dash * 2))
		for s in range(steps):
			var t1 = float(s) / steps
			var t2 = float(s) / steps + (dash / dist)
			if t2 > 1.0: t2 = 1.0
			draw_line(p1.lerp(p2, t1), p1.lerp(p2, t2), line_color, line_width)

