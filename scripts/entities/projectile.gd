extends Area2D

var velocity: Vector2 = Vector2.ZERO
var type: int = 0 # 0 = Player, 1 = Enemy
const GRAVITY = 350.0

func _ready():
	connect("area_entered", _on_area_entered)

func _process(delta):
	position += velocity * delta
	velocity.y += GRAVITY * delta
	
	# Rotation aligned with velocity?
	rotation = velocity.angle()
	
	if position.y > 800:
		queue_free()

func _on_body_entered(body):
	# If we use physics bodies later
	pass

func _on_area_entered(area):
	if type == 0 and area.is_in_group("enemies"):
		area.take_damage(10)
		queue_free()
	elif type == 1 and area.is_in_group("player"):
		area.take_damage(randi_range(3, 8))
		queue_free()
