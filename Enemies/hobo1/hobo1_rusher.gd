extends "res://Enemies/hobo1/hobo1.gd"

@export var rusher_walk_speed: float = 72.0
@export var rusher_run_speed: float = 124.0
@export var rusher_run_switch_distance: float = 200.0
@export var rusher_stop_distance_px: float = 12.0
@export var rusher_attack_range_px: float = 24.0
@export var rusher_attack_damage: int = 4
@export var rusher_attack_cooldown_sec: float = 0.82
@export var rusher_attack_hit_delay_sec: float = 0.18
@export var rusher_depth_follow_distance_px: float = 240.0
@export var rusher_support_hold_distance_px: float = 36.0
@export var rusher_max_attackers: int = 2

func _ready() -> void:
	walk_speed = rusher_walk_speed
	run_speed = maxf(rusher_run_speed, walk_speed)
	use_run_when_close = true
	run_switch_distance = rusher_run_switch_distance
	stop_distance_px = rusher_stop_distance_px
	attack_range_px = rusher_attack_range_px
	attack_damage = rusher_attack_damage
	attack_cooldown_sec = rusher_attack_cooldown_sec
	attack_hit_delay_sec = rusher_attack_hit_delay_sec
	depth_follow_distance_px = rusher_depth_follow_distance_px
	support_hold_distance_px = rusher_support_hold_distance_px
	max_attackers_per_lane = rusher_max_attackers
	prefer_player_back = false
	super._ready()
