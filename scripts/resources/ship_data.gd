extends Resource
class_name ShipData

@export var id: String
@export var name: String
@export var price: int
@export var cargo_capacity: int
@export var max_hull: int
@export var color: Color
@export var visual_polygon: PackedVector2Array
@export var texture: Texture2D
@export var texture_scale: Vector2 = Vector2(1, 1)

enum Type { PLAYER, ENEMY }
@export var type: Type = Type.PLAYER
