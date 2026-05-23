extends "res://Enemies/hobo1/hobo1.gd"

@export var welder_walk_speed: float = 42.0
@export var welder_attack_range_px: float = 64.0
@export var welder_attack_range_y_px: float = 4.0
@export var welder_attack_damage: int = 4
@export var welder_attack_cooldown_sec: float = 1.45
@export var welder_telegraph_sec: float = 0.42
@export var welder_active_sec: float = 0.26
@export var welder_recovery_sec: float = 0.36
@export var welder_depth_follow_distance_px: float = 190.0
@export var welder_arc_size: Vector2 = Vector2(56.0, 24.0)
@export var welder_arc_local_center: Vector2 = Vector2(28.0, -19.0)

var _welder_attack_token: int = 0

func _ready() -> void:
	walk_speed = welder_walk_speed
	run_speed = welder_walk_speed
	use_run_when_close = false
	prefer_player_back = false
	stop_distance_px = welder_attack_range_px
	attack_range_px = welder_attack_range_px
	attack_range_y_px = welder_attack_range_y_px
	attack_damage = welder_attack_damage
	attack_cooldown_sec = welder_attack_cooldown_sec
	attack_hit_delay_sec = welder_telegraph_sec
	attack_active_time_sec = welder_active_sec
	attack_use_anim_frames = false
	depth_follow_distance_px = welder_depth_follow_distance_px
	support_hold_distance_px = welder_attack_range_px + 28.0
	post_attack_reposition_sec = welder_recovery_sec
	max_attackers_per_lane = 1
	super._ready()
	_configure_welder_arc()

func _physics_process(delta: float) -> void:
	if state != State.ATTACK:
		super._physics_process(delta)
		return

	_lock_depth_if_needed()
	velocity.x = move_toward(velocity.x, 0.0, 2000.0 * delta)
	_play_anim_if_needed("attack")
	if attack_active:
		_apply_attack_hits()
	move_and_slide()

func _start_attack() -> void:
	state = State.ATTACK
	attack_active = false
	attack_anim_lock = false
	_welder_attack_token += 1

	_lock_depth_if_needed()
	_play_anim_if_needed("attack")
	_update_hitbox_facing()
	t_cd.start()
	_set_collide_player(false)

	if hitbox:
		hitbox.monitoring = false
		hitbox.set_deferred("monitoring", false)

	t_hit.start(welder_telegraph_sec)

func _on_attack_hit_window_timeout() -> void:
	var token := _welder_attack_token
	attack_active = true
	if hitbox:
		hitbox.monitoring = true
		hitbox.set_deferred("monitoring", true)

	await get_tree().create_timer(maxf(0.0, welder_active_sec)).timeout
	if not _is_welder_attack_current(token):
		return
	attack_active = false
	if hitbox:
		hitbox.monitoring = false
		hitbox.set_deferred("monitoring", false)
	attack_anim_lock = true

	await get_tree().create_timer(maxf(0.0, welder_recovery_sec)).timeout
	if not _is_welder_attack_current(token):
		return
	_finish_welder_attack()

func _configure_welder_arc() -> void:
	if hitbox == null:
		return
	var shape_node := hitbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return
	var arc_shape := RectangleShape2D.new()
	arc_shape.size = welder_arc_size
	shape_node.shape = arc_shape
	shape_node.position = welder_arc_local_center
	_update_hitbox_facing()

func _is_welder_attack_current(token: int) -> bool:
	return token == _welder_attack_token and state == State.ATTACK and not is_dead()

func _finish_welder_attack() -> void:
	if state == State.ATTACK:
		attack_active = false
		attack_anim_lock = false
		if hitbox:
			hitbox.monitoring = false
		_finish_attack_to_chase()

func _on_anim_finished() -> void:
	if state == State.ATTACK:
		return
	super._on_anim_finished()

func apply_damage(dmg: int, a: Variant = null, b: Variant = null) -> void:
	_welder_attack_token += 1
	super.apply_damage(dmg, a, b)
