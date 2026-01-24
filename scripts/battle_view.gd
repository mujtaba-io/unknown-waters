extends Control
class_name BattleView

enum BattleResult { WON, LOST, ESCAPED }
signal battle_finished(result: BattleResult)

@onready var battle_container = $BattleContainer

var player_ship: Area2D
var enemies: Array[Node] = []
var is_fleeing: bool = false
var battle_active: bool = false

# Preloaded Scenes
var projectile_scene = preload("res://scenes/entities/projectile.tscn")
var enemy_scene = preload("res://scenes/entities/enemy_ship.tscn")
var player_scene = preload("res://scenes/entities/player_ship.tscn")

func _ready():
	visible = false

func start_battle():
	visible = true
	battle_active = true
	is_fleeing = false
	enemies.clear()
	
	# Clear Container
	for c in battle_container.get_children():
		c.queue_free()
	
	# Setup Positions
	var vp_size = get_viewport_rect().size
	var center_x = vp_size.x * 0.65
	var start_pos = Vector2(center_x, 600)
	
	# Spawn Player
	player_ship = player_scene.instantiate()
	player_ship.position = start_pos
	player_ship.setup(PlayerManager.current_ship_data, PlayerManager.current_hull)
	player_ship.connect("shoot_requested", _on_player_shoot_requested)
	battle_container.add_child(player_ship)
	
	# Spawn Enemies
	_spawn_enemies(center_x)

func _spawn_enemies(center_x):
	var count = 0
	if PlayerManager.gold < 2000:
		count = randi_range(1, 2)
	elif PlayerManager.gold < 4000:
		count = randi_range(2, 4)
	else:
		count = randi_range(3, 6)
	
	# Determine Enemy Type
	var enemy_res: ShipData = null
	if PlayerManager.current_ship_data:
		var pid = PlayerManager.current_ship_data.id
		if pid in GameManager.enemy_ships:
			enemy_res = GameManager.enemy_ships[pid]
	
	if enemy_res == null:
		enemy_res = GameManager.enemy_ships.get("sloop")
	
	if enemy_res == null:
		# Fallback
		return

	for i in range(count):
		var enemy = enemy_scene.instantiate()
		var pos = Vector2(center_x + ((i-1) * 150) + randf_range(-20, 20), 200)
		var data = {
			"hp": 40, "max_hp": 40,
			"pos": pos,
			"cooldown": randf_range(1.0, 3.0),
			"texture": enemy_res.texture,
			"texture_scale": enemy_res.texture_scale
		}
		enemy.position = pos
		enemy.setup(data)
		enemy.connect("died", _on_enemy_died.bind(enemy))
		enemy.connect("shoot_requested", _on_enemy_shoot_requested)
		battle_container.add_child(enemy)
		enemies.append(enemy)

func _process(delta):
	if not battle_active: return
	
	# Player Logic (Auto-Fire at random enemy)
	if player_ship and is_instance_valid(player_ship):
		if enemies.size() > 0:
			# Simple AI: Shoot random living enemy
			# Or allow player ship script to handle it if we pass target?
			# Let's handle generic targeting here:
			player_ship.fire_at(enemies.pick_random().position)
		
		if is_fleeing:
			player_ship.is_fleeing = true
			if player_ship.position.x > get_viewport_rect().size.x + 50:
				_end_battle(BattleResult.ESCAPED)

func flee():
	is_fleeing = true

# Called by EnemyShip or PlayerShip via get_parent().request_projectile(...)
func request_projectile(start: Vector2, target: Vector2, type: int):
	# Type: 0 = Player, 1 = Enemy
	# BUT request_projectile signature in previous code was (start, end, type).
	# My new entities call it too.
	
	# However, EnemyShip currently calls: request_projectile(position, 1) -- MISSING TARGET!
	# I need to fix logic.
	
	var proj = projectile_scene.instantiate()
	proj.position = start
	proj.type = type
	
	# Calculate Velocity
	# Same logic as before:
	var GRAVITY = 350.0
	var dist = start.distance_to(target)
	var time = dist / 400.0
	if time == 0: time = 0.1
	var vel_x = (target.x - start.x) / time
	var vel_y = (target.y - start.y - 0.5 * GRAVITY * (time * time)) / time
	proj.velocity = Vector2(vel_x, vel_y)
	
	battle_container.add_child(proj)

# Overload for flexible calling if needed, default to player pos for enemies?
# Wait, EnemyShip.gd line 46: `get_parent().request_projectile(position, 1)` -> Two args!
# I need to fix EnemyShip.gd to pass target, OR handle it here by finding player.
# Since I am "Refactoring carefully", I should probably update EnemyShip.gd to pass player pos?
# But EnemyShip doesn't know Player pos.
# So BattleView should handle target finding.
# I'll update `request_projectile` to accept optional target or find it.

func spawn_projectile_from_enemy(start_pos: Vector2):
	if not player_ship or not is_instance_valid(player_ship): return
	request_projectile(start_pos, player_ship.position, 1)

func _on_player_shoot_requested(pos, target, type):
	request_projectile(pos, target, type)

func _on_enemy_shoot_requested(pos):
	if player_ship and is_instance_valid(player_ship):
		request_projectile(pos, player_ship.position, 1)

func _on_enemy_died(enemy):
	enemies.erase(enemy)
	if enemies.size() == 0:
		_end_battle(BattleResult.WON)

func _end_battle(result: BattleResult):
	battle_active = false
	visible = false
	emit_signal("battle_finished", result)
