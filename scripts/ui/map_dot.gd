@tool
extends Node2D

@export var radius: float = 8.0 # Smaller
@export var color: Color = Color(0.8, 0.2, 0.2, 0.8) # Red like trail

func _draw():
	# Imperfect filled circle (blob)
	var points = PackedVector2Array()
	var segments = 16
	
	# Create a noisy loop
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		# Slight radius variation for imperfection
		var r = radius * randf_range(0.85, 1.15)
		var p = Vector2(cos(angle), sin(angle)) * r
		points.append(p)
	
	draw_colored_polygon(points, color)
	# Simple smooth outline to make it crisp
	draw_polyline(points, color, 1.5, true)
