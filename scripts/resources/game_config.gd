extends Resource
class_name GameConfig

@export_group("Navigation")
@export var ship_speed: float = 125.0
@export var rotation_speed: float = 8.0

@export_group("Encounters")
@export var event_chance_tick: float = 0.004
@export var battle_probability: float = 0.7 # 70% battle, 30% storm
@export var min_trip_time_before_event: float = 1.0
@export var min_dist_before_event: float = 50.0
