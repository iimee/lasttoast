extends "res://Enemies/hobo1/hobo1.gd"

# Test dummy variant: stays in place and does not run chase/attack movement logic.
@export_range(0, 2, 1) var static_lane: int = 1
@export var lock_static_lane: bool = true

func _ready() -> void:
	super._ready()
	if lane_body:
		lane_body.depth_locked = false
		var lane: int = LaneSystem.clamp_lane(static_lane)
		lane_body.set_depth_y(LaneSystem.center_from_lane(lane))
		if lock_static_lane:
			lane_body.depth_locked = true
	state = State.IDLE
	player = null
	player_lane = null
	target_in_sight = false
	attack_active = false
	attack_anim_lock = false
	if hitbox:
		hitbox.monitoring = false
	_set_collide_player(false)
	_play_anim_if_needed("idle")

func _physics_process(_delta: float) -> void:
	if state == State.DEAD:
		return
	velocity = Vector2.ZERO
