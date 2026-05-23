extends "res://Enemies/hobo1/hobo1.gd"

@export var poker_walk_speed: float = 58.0
@export var poker_run_speed: float = 96.0
@export var poker_back_offset_px: float = 56.0
@export var poker_stop_distance_px: float = 40.0
@export var poker_attack_range_px: float = 44.0
@export var poker_attack_range_y_px: float = 24.0
@export var poker_attack_damage: int = 3
@export var poker_attack_cooldown_sec: float = 1.18
@export var poker_support_hold_distance_px: float = 96.0
@export var poker_post_attack_reposition_sec: float = 1.0

func _ready() -> void:
	walk_speed = poker_walk_speed
	run_speed = maxf(poker_run_speed, walk_speed)
	use_run_when_close = true
	run_switch_distance = 170.0
	prefer_player_back = true
	back_offset_px = poker_back_offset_px
	stop_distance_px = poker_stop_distance_px
	attack_range_px = poker_attack_range_px
	attack_range_y_px = poker_attack_range_y_px
	attack_damage = poker_attack_damage
	attack_cooldown_sec = poker_attack_cooldown_sec
	support_hold_distance_px = poker_support_hold_distance_px
	post_attack_reposition_sec = poker_post_attack_reposition_sec
	max_attackers_per_lane = 1
	super._ready()
