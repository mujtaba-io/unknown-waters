extends Area2D

signal shoot_requested(pos, target, type)

var cooldown: float = 0.0
var hp: int = 100
var max_hp: int = 100
var is_fleeing: bool = false
const SPEED = 200.0

func _ready():
	add_to_group("player")
	# Initialize from PlayerManager/GameManager?
	# Or let BattleView configure it.

func setup(ship_data: ShipData, current_hull: int):
	hp = current_hull
	max_hp = ship_data.max_hull
	
	if ship_data.texture:
		$Visual.texture = ship_data.texture
		$Visual.scale = ship_data.texture_scale * 2.0
	
	# Update HP Bar/Hud? BattleView handles HUD.

func _process(delta):
	# Cooldown
	cooldown -= delta
	if cooldown <= 0:
		# Auto shoot nearest enemy? Or just shoot forward?
		# Original logic: Shoot random enemy.
		# Let's shoot forward or at nearest.
		# For valid "industry standard", player usually controls shooting or auto-fire.
		# Original: player_cooldown 2.4s, shoots random enemy.
		pass
	
	if is_fleeing:
		position.x += 15.0 * delta # Slow escape
	
	# Clamp position?
	
func fire_at(target_pos: Vector2):
	if cooldown > 0: return
	cooldown = 2.4
	
	# Spawn Projectile
	emit_signal("shoot_requested", position, target_pos, 0) # 0 = Player Type

func take_damage(amount: int):
	hp -= amount
	# Update PlayerManager? 
	# Ideally we sync back to PlayerManager at end of battle, OR sync immediately.
	# Direct sync:
	PlayerManager.damage_ship(amount)
	
	if hp <= 0:
		# Die
		pass
