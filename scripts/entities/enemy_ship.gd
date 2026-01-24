extends Area2D

signal died
signal shoot_requested(pos)

var hp: int = 40
var max_hp: int = 40
var cooldown: float = 0.0
var texture_scale: Vector2 = Vector2(1,1)

func _ready():
	add_to_group("enemies")
	$Visual.scale = texture_scale

func setup(data: Dictionary):
	# data: {hp, max_hp, pos, cooldown, texture, texture_scale}
	hp = data.get("hp", 40)
	max_hp = data.get("max_hp", 40)
	position = data.get("pos", Vector2.ZERO)
	cooldown = data.get("cooldown", 2.0)
	
	if data.has("texture"):
		$Visual.texture = data.texture
		texture_scale = data.get("texture_scale", Vector2(1,1)) * 1.6 # Scale up as per original BattleView
		$Visual.scale = texture_scale
	
	# Update HP Bar
	_update_hp_bar()

func _process(delta):
	cooldown -= delta
	if cooldown <= 0:
		cooldown = randf_range(2.1, 4.3)
		fire()
	
	_update_hp_bar()

func fire():
	# Emit signal to spawn projectile or spawn it here?
	# Better to emit signal so Main/BattleView adds it to scene tree root, avoiding nesting issues?
	# Or just add to parent.
	var bullet = load("res://scenes/entities/projectile.tscn").instantiate()
	bullet.position = position
	bullet.type = 1 # Enemy
	# Emit signal
	emit_signal("shoot_requested", position)

func take_damage(amount: int):
	hp -= amount
	_update_hp_bar()
	if hp <= 0:
		emit_signal("died")
		queue_free()

func _update_hp_bar():
	$HPBar.value = hp
	$HPBar.max_value = max_hp
