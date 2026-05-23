extends "res://Enemies/hobo1/hobo1.gd"

@export var launcher_walk_speed: float = 46.0
@export var launcher_preferred_range_px: float = 150.0
@export var launcher_range_tolerance_px: float = 14.0
@export var launcher_fire_range_px: float = 190.0
@export var launcher_attack_range_y_px: float = 22.0
@export var launcher_depth_follow_distance_px: float = 260.0
@export var launcher_telegraph_sec: float = 0.34
@export var launcher_recovery_sec: float = 0.55
@export var launcher_reload_sec: float = 1.55
@export var launcher_projectile_scene: PackedScene = preload("res://Combat/Projectiles/EnemyBottleFly.tscn")
@export var launcher_projectile_speed: float = 150.0
@export var launcher_projectile_damage: int = 2
@export var launcher_projectile_knockback: float = 80.0
@export var launcher_projectile_lifetime: float = 1.45
@export var launcher_projectile_depth_tolerance: float = 8.0
@export var launcher_projectile_spawn_offset: Vector2 = Vector2(22.0, -18.0)
@export var launcher_throw_anim_name: StringName = &"throw"
@export var launcher_throw_emit_frame: int = 3

var _launcher_attack_token: int = 0

func _ready() -> void:
	walk_speed = launcher_walk_speed
	run_speed = launcher_walk_speed
	use_run_when_close = false
	prefer_player_back = false
	stop_distance_px = maxf(8.0, launcher_range_tolerance_px)
	attack_range_px = launcher_fire_range_px
	attack_range_y_px = launcher_attack_range_y_px
	attack_cooldown_sec = launcher_reload_sec
	attack_hit_delay_sec = launcher_telegraph_sec
	attack_active_time_sec = 0.0
	attack_use_anim_frames = false
	depth_follow_distance_px = launcher_depth_follow_distance_px
	support_hold_distance_px = launcher_preferred_range_px
	max_attackers_per_lane = 1
	super._ready()

func _physics_process(delta: float) -> void:
	if state == State.DEAD or state == State.HURT:
		super._physics_process(delta)
		return

	if not is_on_floor():
		velocity.y = clamp(velocity.y + gravity * delta, -INF, max_fall_speed)

	match state:
		State.IDLE:
			_unlock_depth_if_needed()
			_set_collide_player(false)
			velocity.x = move_toward(velocity.x, 0.0, 1000.0 * delta)
			_play_anim_if_needed("idle")
			if _can_see_player():
				state = State.CHASE

		State.CHASE:
			_unlock_depth_if_needed()
			_set_collide_player(false)
			if hitbox and hitbox.monitoring:
				hitbox.monitoring = false

			if not _can_see_player():
				player = null
				player_lane = null
				target_in_sight = false
				state = State.IDLE
			else:
				if player_lane and match_player_lane_when_close:
					var dist_x_for_depth: float = absf(player.global_position.x - global_position.x)
					if dist_x_for_depth <= depth_follow_distance_px:
						_follow_player_depth(delta)

				var dx_to_player: float = player.global_position.x - global_position.x
				_apply_facing_from_dx(dx_to_player)

				if _launcher_can_fire() and t_cd.is_stopped() and _can_take_attack_slot():
					_start_attack()
				else:
					_update_launcher_spacing(delta)

		State.ATTACK:
			_lock_depth_if_needed()
			_set_collide_player(false)
			if hitbox and hitbox.monitoring:
				hitbox.monitoring = false
			velocity.x = move_toward(velocity.x, 0.0, 2000.0 * delta)
			_play_anim_if_needed(_launcher_attack_anim_name())

	move_and_slide()

func _start_attack() -> void:
	if state == State.DEAD:
		return
	state = State.ATTACK
	attack_active = false
	attack_anim_lock = false
	_launcher_attack_token += 1
	var token := _launcher_attack_token

	if player != null:
		_apply_facing_from_dx(player.global_position.x - global_position.x)
	_lock_depth_if_needed()
	_set_collide_player(false)
	if hitbox:
		hitbox.monitoring = false
	_play_anim_if_needed(_launcher_attack_anim_name())
	t_cd.start()
	_run_launcher_attack(token)

func _run_launcher_attack(token: int) -> void:
	await get_tree().create_timer(_launcher_emit_delay_sec()).timeout
	if not _is_launcher_attack_current(token):
		return
	_fire_launcher_projectile()
	await get_tree().create_timer(maxf(0.0, launcher_recovery_sec)).timeout
	if not _is_launcher_attack_current(token):
		return
	_finish_launcher_attack()

func _fire_launcher_projectile() -> void:
	if launcher_projectile_scene == null:
		return
	var projectile := launcher_projectile_scene.instantiate()
	if projectile == null:
		return

	var dir := Vector2(float(facing), 0.0)
	if dir.x == 0.0:
		dir = Vector2.LEFT
	var spawn_pos := global_position + Vector2(launcher_projectile_spawn_offset.x * dir.x, launcher_projectile_spawn_offset.y)

	if projectile is Object:
		var po := projectile as Object
		po.set("damage", launcher_projectile_damage)
		po.set("knockback", launcher_projectile_knockback)
		po.set("lifetime", launcher_projectile_lifetime)
		po.set("enemy_group", "Player")
		po.set("ignore_groups", ["Enemy", "attack"])
		po.set("depth_hit_tolerance", launcher_projectile_depth_tolerance)
		po.set("dash_combo_enabled", false)

	if projectile is Area2D:
		var area := projectile as Area2D
		area.collision_layer = Layers.E_ATTACK
		area.collision_mask = Layers.PLAYER

	if lane_body != null:
		if projectile.has_method("set_lane_index"):
			projectile.call("set_lane_index", lane_body.lane_index)
		if projectile.has_method("set_depth_y"):
			projectile.call("set_depth_y", lane_body.depth_y)
		elif projectile is Object:
			(projectile as Object).set("depth_y", lane_body.depth_y)

	var parent := get_parent()
	if parent == null:
		parent = get_tree().current_scene
	if parent == null:
		parent = get_tree().root
	parent.add_child(projectile)

	if projectile is Node2D:
		(projectile as Node2D).global_position = spawn_pos

	if projectile.has_method("setup"):
		projectile.call("setup", dir, launcher_projectile_speed)

func _launcher_attack_anim_name() -> String:
	var anim_name := String(launcher_throw_anim_name)
	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(launcher_throw_anim_name):
		return anim_name
	return "attack"

func _launcher_emit_delay_sec() -> float:
	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		return maxf(0.0, launcher_telegraph_sec)
	if not sprite.sprite_frames.has_animation(launcher_throw_anim_name):
		return maxf(0.0, launcher_telegraph_sec)

	var fps := float(sprite.sprite_frames.get_animation_speed(launcher_throw_anim_name))
	if fps <= 0.0:
		return maxf(0.0, launcher_telegraph_sec)
	return maxf(0.0, float(max(0, launcher_throw_emit_frame)) / fps)

func _update_launcher_spacing(delta: float) -> void:
	if player == null:
		velocity.x = move_toward(velocity.x, 0.0, 1000.0 * delta)
		_play_anim_if_needed("idle")
		return

	var target_x := _launcher_spacing_target_x()
	var dx := target_x - global_position.x
	var separation_x: float = _compute_enemy_separation_x()
	if absf(dx) <= launcher_range_tolerance_px:
		velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta) + separation_x
		_play_anim_if_needed("idle")
	else:
		velocity.x = float(_sgn(dx)) * walk_speed * _surface_speed_multiplier() + separation_x
		_play_anim_if_needed("walk")

func _launcher_spacing_target_x() -> float:
	if player == null:
		return global_position.x
	var rel := global_position.x - player.global_position.x
	var side := _sgn(rel)
	if side == 0:
		side = -facing
	if side == 0:
		side = -1
	return player.global_position.x + float(side) * launcher_preferred_range_px

func _launcher_can_fire() -> bool:
	if player == null or player_lane == null:
		return false
	var dx := absf(player.global_position.x - global_position.x)
	var dy := absf(player_lane.depth_y - lane_body.depth_y) if lane_body != null else 0.0
	var depth_reach := attack_range_y_px + _depth_radius_of_target(player)
	return dx <= launcher_fire_range_px and dy <= depth_reach

func _is_launcher_attack_current(token: int) -> bool:
	return token == _launcher_attack_token and state == State.ATTACK and not is_dead()

func _finish_launcher_attack() -> void:
	if state == State.ATTACK:
		attack_active = false
		attack_anim_lock = false
		_finish_attack_to_chase()

func _on_anim_finished() -> void:
	if state == State.ATTACK:
		return
	super._on_anim_finished()

func apply_damage(dmg: int, a: Variant = null, b: Variant = null) -> void:
	_launcher_attack_token += 1
	super.apply_damage(dmg, a, b)
