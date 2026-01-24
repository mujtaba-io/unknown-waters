extends Node
class_name UIAnimator

static func float_loop(node: Control, amplitude: float = 5.0, duration: float = 2.0):
	if not node: return
	
	var tree = node.get_tree()
	if not tree: return
	
	var tween = tree.create_tween()
	tween.set_loops() # Infinite loop
	
	# Store original position if needed? For relative movement we can just use offset
	# But Control nodes layed out by containers might fight position changes.
	# Better to animate 'position' relative to current, or use 'pivot_offset' rotation if easier.
	# For Container children, modifying 'position' directly is usually persistent until relayout.
	# A safer way for items in containers is to animate 'rotation' slightly or 'scale' slightly, 
	# OR use a wrapping Control that has custom minimum size but the inner content moves.
	
	# Let's try simple bobbing of 'rotation' (rocking boat) and slight scale breath as it's safer in containers
	
	tween.tween_property(node, "rotation_degrees", 2.0, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "rotation_degrees", -2.0, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

static func pulse_hover(node: Control, scale_amount: float = 1.1):
	node.pivot_offset = node.size / 2.0
	
	node.mouse_entered.connect(func():
		var t = node.get_tree().create_tween()
		t.tween_property(node, "scale", Vector2.ONE * scale_amount, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	
	node.mouse_exited.connect(func():
		var t = node.get_tree().create_tween()
		t.tween_property(node, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
