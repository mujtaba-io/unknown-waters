extends Control
class_name BattleView

enum BattleResult { WON, LOST, ESCAPED }
signal battle_finished(result: BattleResult)

const GRAVITY = 350.0

@onready var draw_surface = $BattleDraw

var active_projectiles = []
var enemies = []
var player_pos: Vector2
var player_cooldown: float = 0.0
var is_fleeing: bool = false
var battle_active: bool = false

func start_battle():
	visible = true
	battle_active = true
	is_fleeing = false
	active_projectiles.clear()
	enemies.clear()
	player_cooldown = 0.5
	
	# Setup positions
	var vp_size = get_viewport_rect().size
	var center_x = vp_size.x * 0.65
	player_pos = Vector2(center_x, 600)
	
	# Spawn Enemies
	var count = 0
	if GameManager.gold < 2000:
		count = randi_range(1, 2)
	elif GameManager.gold < 4000:
		count = randi_range(2, 4)
	else:
		count = randi_range(3, 6)
	
	# Determine Enemy Type based on Player Ship Name (e.g. "Sloop" -> "Enemy Sloop")
	# Assuming player ship name is like "Sloop", "Caravel", etc.
	# We want same type.
	var enemy_res: ShipData = null
	if GameManager.current_ship_data:
		var pid = GameManager.current_ship_data.id # e.g. "sloop"
		if pid in GameManager.enemy_ships:
			enemy_res = GameManager.enemy_ships[pid]
	
	if enemy_res == null:
		# Fallback if something fails
		enemy_res = GameManager.enemy_ships.get("sloop")
	
	if enemy_res == null:
		push_error("BATTLE ERROR: No enemy ship resource found! 'Enemy Ship Database' likely empty in GameManager.")
		_end_battle(BattleResult.ESCAPED) # Or handle gracefully
		return

	for i in range(count):
		enemies.append({
			"hp": 40, "max_hp": 40,
			"pos": Vector2(center_x + ((i-1) * 150) + randf_range(-20, 20), 200),
			"cooldown": randf_range(1.0, 3.0),
			"texture": enemy_res.texture,
			"texture_scale": enemy_res.texture_scale * 1.6
		})

func _process(delta):
	if not battle_active: return
	
	# Flee Logic
	if is_fleeing:
		player_pos.x += 15.0 * delta
		if player_pos.x > get_viewport_rect().size.x + 50:
			_end_battle(BattleResult.ESCAPED)
		draw_surface.queue_redraw()
		# return  <-- REMOVED per user request/H.tscn match

	# Player Shoot
	player_cooldown -= delta
	if player_cooldown <= 0 and enemies.size() > 0:
		player_cooldown = 2.4
		_spawn_projectile(player_pos, enemies.pick_random().pos, 0)

	# Enemy Logic
	for e in enemies:
		e.cooldown -= delta
		if e.cooldown <= 0:
			e.cooldown = randf_range(2.1, 4.3)
			_spawn_projectile(e.pos, player_pos, 1)

	# Projectile Physics
	for i in range(active_projectiles.size() - 1, -1, -1):
		var p = active_projectiles[i]
		p.pos += p.vel * delta
		p.vel.y += GRAVITY * delta # Gravity
		
		var hit = false
		if p.type == 0: # Player Bullet
			for e in enemies:
				if p.pos.distance_to(e.pos) < 40:
					e.hp -= 10
					hit = true
					break
		else: # Enemy Bullet
			if p.pos.distance_to(player_pos) < 60:
				GameManager.current_hull -= randi_range(3, 8)
				GameManager.emit_signal("stats_changed")
				hit = true
				if GameManager.current_hull <= 0:
					_end_battle(BattleResult.LOST)
					return
		
		if hit or p.pos.y > 720:
			active_projectiles.remove_at(i)
	
	# Cleanup Dead Enemies
	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i].hp <= 0: enemies.remove_at(i)
	
	if enemies.size() == 0:
		_end_battle(BattleResult.WON)
	
	draw_surface.queue_redraw()

func _spawn_projectile(start, end, type):
	var dist = start.distance_to(end)
	var time = dist / 400.0
	var vel_x = (end.x - start.x) / time
	var vel_y = (end.y - start.y - 0.5 * GRAVITY * (time * time)) / time
	active_projectiles.append({ "pos": start, "vel": Vector2(vel_x, vel_y), "type": type })

func flee():
	is_fleeing = true

func _end_battle(result: BattleResult):
	battle_active = false
	visible = false
	emit_signal("battle_finished", result)

# Sub-component to handle drawing
func _on_draw_request():
	# Draw Projectiles
	for p in active_projectiles:
		draw_surface.draw_circle(p.pos, 4, Color.BLACK)
	
	# Draw Enemies
	for e in enemies:
		# Ship Body
		if e.has("texture") and e.texture:
			var tex = e.texture
			var size = tex.get_size() * e.texture_scale
			var rect = Rect2(e.pos - size / 2, size)
			
			# Draw Enemy Texture (No Rotation, same as player)
			draw_surface.draw_set_transform(e.pos, 0, e.texture_scale) 
			draw_surface.draw_texture(tex, -tex.get_size() / 2)
			draw_surface.draw_set_transform(Vector2.ZERO, 0, Vector2(1,1))
			
			
		else:
			var body = PackedVector2Array([e.pos+Vector2(-30,-10), e.pos+Vector2(30,-10), e.pos+Vector2(20,20), e.pos+Vector2(-20,20)])
			draw_surface.draw_colored_polygon(body, Color(0.2,0.2,0.2))
			# Sail
			var sail = PackedVector2Array([e.pos+Vector2(-5,-10), e.pos+Vector2(-5,-50), e.pos+Vector2(25,-20)])
			draw_surface.draw_colored_polygon(sail, Color.BLACK)
		
		# HP Bar
		var hp_pct = float(e.hp) / float(e.max_hp)
		draw_surface.draw_rect(Rect2(e.pos.x - 20, e.pos.y - 40, 40, 5), Color.RED)
		draw_surface.draw_rect(Rect2(e.pos.x - 20, e.pos.y - 40, 40 * hp_pct, 5), Color.GREEN)
	
	# Draw Player
	if battle_active:
		var p = player_pos
		if GameManager.current_ship_data and GameManager.current_ship_data.texture:
			var tex = GameManager.current_ship_data.texture
			var scale = GameManager.current_ship_data.texture_scale * 2.0
			
			# Player faces UP (0 rotation)
			draw_surface.draw_set_transform(p, 0, scale)
			draw_surface.draw_texture(tex, -tex.get_size() / 2)
			draw_surface.draw_set_transform(Vector2.ZERO, 0, Vector2(1,1))
		else:
			var body = PackedVector2Array([p+Vector2(-50,-20), p+Vector2(50,-20), p+Vector2(35,30), p+Vector2(-35,30)])
			draw_surface.draw_colored_polygon(body, Color(0.6,0.4,0.2))
			var sail = PackedVector2Array([p+Vector2(0,-20), p+Vector2(0,-80), p+Vector2(50,-40)])
			draw_surface.draw_colored_polygon(sail, Color(0.9,0.9,0.9))
