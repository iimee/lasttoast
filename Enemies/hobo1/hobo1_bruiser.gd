extends "res://Enemies/hobo1/hobo1.gd"

@export var bruiser_walk_speed: float = 42.0
@export var bruiser_attack_range_px: float = 38.0
@export var bruiser_attack_range_y_px: float = 26.0
@export var bruiser_attack_damage: int = 7
@export var bruiser_attack_cooldown_sec: float = 1.35
@export var bruiser_hit_delay_sec: float = 0.26
@export var bruiser_hp_max: int = 16
@export var bruiser_hurt_stun_sec: float = 0.62
@export var bruiser_knockback: Vector2 = Vector2(150, -120)
@export var bruiser_support_hold_distance_px: float = 82.0

func _ready() -> void:
	walk_speed = bruiser_walk_speed
	run_speed = bruiser_walk_speed
	use_run_when_close = false
	stop_distance_px = 20.0
	attack_range_px = bruiser_attack_range_px
	attack_range_y_px = bruiser_attack_range_y_px
	attack_damage = bruiser_attack_damage
	attack_cooldown_sec = bruiser_attack_cooldown_sec
	attack_hit_delay_sec = bruiser_hit_delay_sec
	hp_max = bruiser_hp_max
	hurt_stun_sec = bruiser_hurt_stun_sec
	knockback = bruiser_knockback
	support_hold_distance_px = bruiser_support_hold_distance_px
	max_attackers_per_lane = 1
	prefer_player_back = false
	super._ready()
