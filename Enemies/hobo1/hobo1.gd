# hobo1.gd - Godot 4.5
# enemy: sight -> chase (stop near) -> attack (non-loop, timed hit)
# pseudo-3D depth with 3 combat lanes via LaneSystem + LaneBody
# IMPORTANT:
# - Depth moves ONLY visuals (LaneBody.visual_root_path). Physics body Y is not used for lane.
# - Enemy collision mask switches to WORLD + current lane layer (9..11) so old lane obstacles work again.
# - Vertical distance checks use depth_y, not global_position.y.
# - FIX: during ATTACK/HURT depth is LOCKED (no lane drift while attacking or in skills-like states).
# - FIX: default idle faces left.
# - FIX: DEAD anchors root position and forces corpse visual offset (shift back+down) starting from frame 2 of "dead".

extends CharacterBody2D
const SURFACE_SLOW_MIN: float = 0.1

# ===== movement / physics =====
@export var walk_speed: float = 60.0
@export var run_speed: float = 90.0
@export var use_run_when_close: bool = false
@export var run_switch_distance: float = 120.0
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var max_fall_speed: float = 900.0
@export var stop_distance_px: float = 24.0

@export var prefer_player_back: bool = false
@export var back_offset_px: float = 34.0

# ===== pseudo-3D / lanes =====
@export var depth_speed: float = 120.0
@export var depth_radius: float = 8.0
@export var depth_follow_distance_px: float = 160.0   # когда начинаем подстраиваться по глубине
@export var depth_stop_epsilon: float = 1.0
@export var match_player_lane_when_close: bool = true
@export var snap_to_lane_centers: bool = true         # ехать к центру полосы игрока (а не к его depth_y)
@export_range(-1, 2, 1) var start_lane: int = -1      # -1 = оставить lane из LaneBody, 0..2 = принудительный стартовый lane
@export var lock_start_lane: bool = false              # true = зафиксировать lane на старте (для манекенов/тестов)

# ===== attack =====
@export var attack_range_px: float = 28.0
@export var attack_range_y_px: float = 20.0
@export var attack_damage: int = 3
@export var attack_cooldown_sec: float = 1.15
@export var attack_hit_delay_sec: float = 0.22
@export var attack_active_time_sec: float = 0.16
@export var attack_offset: Vector2 = Vector2(18, -6)
@export var attack_use_anim_frames: bool = true
@export var attack_hit_start_frame: int = 4   # 0-based: 4 = 5th frame
@export var attack_hit_end_frame: int = 4     # inclusive

# ===== hp / hurt =====
@export var hp_max: int = 6
@export var knockback: Vector2 = Vector2(120, -140)
@export var hurt_stun_sec: float = 0.5

# ===== vision =====
@export var use_line_of_sight: bool = false
@export var enable_enemy_separation: bool = true
@export var separation_radius_px: float = 20.0
@export var separation_push_speed: float = 45.0
@export var max_attackers_per_lane: int = 1
@export var support_hold_distance_px: float = 64.0
@export var support_hold_jitter_px: float = 6.0
@export var post_attack_reposition_sec: float = 0.70
@export var support_switch_cooldown_sec: float = 0.55
@export var facing_deadzone_px: float = 12.0
@export var enemy_body_collision: bool = false
@export var enable_blocked_repath: bool = false
@export var blocked_probe_px: float = 18.0
@export var blocked_repath_cooldown_sec: float = 0.35
@export var wait_if_blocked: bool = true

# ===== drop =====
@export var drop_on_death: bool = true
@export var drop_scene: PackedScene = preload("res://Pickups/Bottle/bottle.tscn")
@export var drop_chance: float = 0.7
@export var drop_amount: int = 1
@export var drop_floor_probe_px: float = 64.0
@export var drop_clearance_px: float = 6.0
@export var drop_jitter_px: float = 6.0
@export var drop_world_mask: int = 1                    # WORLD (бит 1)

# ===== corpse =====
@export var corpse_lifetime_sec: float = 6.0            # сколько лежит труп после смерти
@export var corpse_shift_back_px: float = 10.0           # назад (против facing)
@export var corpse_shift_down_px: float = 24.0           # вниз к земле
@export var corpse_offset_start_frame: int = 3          # на каком кадре "dead" включать смещение (1 = 2-й кадр)

# ===== state =====
enum State { IDLE, CHASE, ATTACK, HURT, DEAD }
var state: State = State.IDLE
var hp: int = 0
var player: Node2D = null
var target_in_sight: bool = false

# default idle facing LEFT
var facing: int = -1

var attack_active: bool = false
var attack_anim_lock: bool = false      # не перебиваем "attack" автологикой
var _surface_slow_multiplier: float = 1.0
var _surface_slow_until_msec: int = 0

# anchor to prevent corpse drift
var death_pos: Vector2 = Vector2.ZERO

# base offset of sprite (so corpse shift is stable)
var corpse_offset_base: Vector2 = Vector2.ZERO
var death_fx_started: bool = false

# ===== lane refs =====
var player_lane: LaneBody = null

# ===== nodes =====
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sight: Area2D = $SightArea
@onready var hitbox: Area2D = $AttackArea
@onready var wall_check: RayCast2D = $wall_check
@onready var ground_check: RayCast2D = $ground_check
@onready var t_cd: Timer = $attack_cooldown
@onready var t_hit: Timer = $attack_hit_window
@onready var t_hurt: Timer = $hurt_stun

# LaneBody is required as a child node named "LaneBody"
@onready var lane_body: LaneBody = $LaneBody

# ===== collision bits =====
const LAYER_WORLD: int = 1 << 0        # Physics layer 1
const LAYER_ENEMY: int = 1 << 2        # Physics layer 3
var _blocked_repath_until_msec: int = 0
var _post_attack_until_msec: int = 0
var _support_sign: int = 1
var _support_active: bool = false
var _support_switch_until_msec: int = 0

func apply_surface_slow(multiplier: float, duration_sec: float = 0.12) -> void:
	var m: float = clampf(multiplier, SURFACE_SLOW_MIN, 1.0)
	_surface_slow_multiplier = m
	var until: int = Time.get_ticks_msec() + int(maxf(0.0, duration_sec) * 1000.0)
	if until > _surface_slow_until_msec:
		_surface_slow_until_msec = until

func _surface_speed_multiplier() -> float:
	if _surface_slow_until_msec <= 0:
		return 1.0
	if Time.get_ticks_msec() > _surface_slow_until_msec:
		_surface_slow_until_msec = 0
		_surface_slow_multiplier = 1.0
		return 1.0
	return _surface_slow_multiplier

func _ready() -> void:
	hp = hp_max
	_support_sign = _compute_support_sign()

	# remember base sprite offset
	if anim:
		corpse_offset_base = anim.offset

	# apply default facing immediately (idle left)
	_set_sprite_facing(facing)

	# "attack" - без зацикливания
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("attack"):
		anim.sprite_frames.set_animation_loop("attack", false)

	# таймеры
	t_cd.wait_time = attack_cooldown_sec
	t_cd.one_shot = true
	t_hit.one_shot = true
	t_hurt.one_shot = true

	# sight
	if sight:
		if not sight.body_entered.is_connected(_on_sight_enter): sight.body_entered.connect(_on_sight_enter)
		if not sight.body_exited.is_connected(_on_sight_exit):   sight.body_exited.connect(_on_sight_exit)
		if not sight.area_entered.is_connected(_on_sight_area_enter): sight.area_entered.connect(_on_sight_area_enter)
		if not sight.area_exited.is_connected(_on_sight_area_exit):   sight.area_exited.connect(_on_sight_area_exit)

	# attack area
	if hitbox and not hitbox.body_entered.is_connected(_on_attackarea_body_entered):
		hitbox.body_entered.connect(_on_attackarea_body_entered)
	if hitbox:
		hitbox.monitoring = false
		hitbox.monitorable = true
		_update_hitbox_facing()

	# события
	if anim and not anim.animation_finished.is_connected(_on_anim_finished):
		anim.animation_finished.connect(_on_anim_finished)
	if not t_cd.timeout.is_connected(_on_attack_cooldown_timeout):
		t_cd.timeout.connect(_on_attack_cooldown_timeout)
	if not t_hurt.timeout.is_connected(_on_hurt_stun_timeout):
		t_hurt.timeout.connect(_on_hurt_stun_timeout)
	if not t_hit.timeout.is_connected(_on_attack_hit_window_timeout):
		t_hit.timeout.connect(_on_attack_hit_window_timeout)

	# frame_changed (для старта смещения трупа со 2-го кадра)
	if anim and not anim.frame_changed.is_connected(_on_anim_frame_changed):
		anim.frame_changed.connect(_on_anim_frame_changed)

	# ===== COLLISION MATRIX =====
	set_collision_layer_value(1, false)
	set_collision_layer_value(2, false)
	set_collision_layer_value(3, true)
	set_collision_mask_value(1, true)    # WORLD
	set_collision_mask_value(2, false)   # PLAYER off в CHASE
	set_collision_mask_value(3, enemy_body_collision)    # ENEMY (soft avoidance preferred)
	set_collision_mask_value(8, true)    # HAZARD (если нужно)

	# RayCasts только WORLD
	if wall_check:   wall_check.collision_mask = 1
	if ground_check: ground_check.collision_mask = 1

	# AttackArea: слой 5 E_ATTACK, маска 2 PLAYER
	if hitbox:
		hitbox.set_collision_layer_value(5, true)
		hitbox.set_collision_mask_value(2, true)
		hitbox.set_collision_mask_value(3, false)

	# ===== LANE INIT =====
	if lane_body and not lane_body.lane_changed.is_connected(_on_lane_changed):
		lane_body.lane_changed.connect(_on_lane_changed)

	if lane_body:
		if start_lane >= 0:
			lane_body.depth_locked = false
			var lane: int = LaneSystem.clamp_lane(start_lane)
			lane_body.set_depth_y(LaneSystem.center_from_lane(lane))
		if lock_start_lane:
			lane_body.depth_locked = true

	_apply_lane_collision_mask(lane_body.lane_index)
	_play_anim_if_needed("idle")

func _physics_process(delta: float) -> void:
	# DEAD: anchor root and force corpse visual offset (so nothing can "drag" the corpse)
	if state == State.DEAD:
		global_position = death_pos
		velocity = Vector2.ZERO
		if death_fx_started:
			_apply_corpse_visual_offset()
		return

	# гравитация
	if not is_on_floor():
		velocity.y = clamp(velocity.y + gravity * delta, -INF, max_fall_speed)

	match state:
		State.IDLE:
			_unlock_depth_if_needed()
			velocity.x = move_toward(velocity.x, 0.0, 1000.0 * delta)
			_play_anim_if_needed("idle")
			if _can_see_player():
				state = State.CHASE

		State.CHASE:
			_unlock_depth_if_needed()
			var surface_mul: float = _surface_speed_multiplier()

			if hitbox and hitbox.monitoring:
				hitbox.monitoring = false

			# в погоне телом по игроку не коллимся
			_set_collide_player(false)

			if not _can_see_player():
				player = null
				player_lane = null
				target_in_sight = false
				state = State.IDLE
			else:
				# --- depth follow (ONLY in CHASE) ---
				if player_lane and match_player_lane_when_close:
					var dist_x_for_depth: float = absf(player.global_position.x - global_position.x)
					if dist_x_for_depth <= depth_follow_distance_px:
						_follow_player_depth(delta)

				var target_x: float = _get_chase_target_x()
				var can_attack_slot: bool = _can_take_attack_slot()
				var want_support: bool = not can_attack_slot
				if _can_switch_support_mode(want_support):
					_support_active = want_support
					_mark_support_mode_switch()
				if _support_active:
					target_x = _get_support_hold_x()
				var dx: float = target_x - global_position.x
				var dx_to_player: float = player.global_position.x - global_position.x
				var dy: float = 0.0
				if player_lane:
					dy = player_lane.depth_y - lane_body.depth_y

				# Always face the player, not support point, to avoid spin-flips.
				_apply_facing_from_dx(dx_to_player)

				var dist_x: float = absf(dx)
				var dist_x_player: float = absf(dx_to_player)
				var dist_y: float = absf(dy)

				var depth_reach: float = attack_range_y_px + _depth_radius_of_target(player)
				var in_attack_box: bool = dist_x_player <= attack_range_px and dist_y <= depth_reach
				var near_border: bool = dist_x <= max(attack_range_px, stop_distance_px)

				if in_attack_box and is_on_floor() and t_cd.is_stopped() and can_attack_slot:
					_start_attack()
				else:
					var use_run_anim: bool = use_run_when_close and dist_x < run_switch_distance
					var speed: float = (run_speed if use_run_anim else walk_speed) * surface_mul
					var separation_x: float = _compute_enemy_separation_x()
					var chase_dir: int = _sgn(dx)
					var blocked: bool = enable_blocked_repath and _is_path_blocked_by_enemy(chase_dir)
					if blocked:
						if _can_try_blocked_repath():
							_try_repath_around_blocker()
							_mark_blocked_repath()
						if wait_if_blocked:
							velocity.x = move_toward(velocity.x, 0.0, 2000.0 * delta) + (separation_x * 0.3)
							_play_anim_if_needed("idle")
						else:
							velocity.x = separation_x
							_play_anim_if_needed("walk")
					elif near_border:
						velocity.x = move_toward(velocity.x, 0.0, 2000.0 * delta) + separation_x
						_play_anim_if_needed("idle")
					else:
						velocity.x = float(chase_dir) * speed + separation_x
						_play_anim_if_needed("run" if use_run_anim else "walk")

		State.ATTACK:
			# FIX: запрет любых смен глубины в атаке
			_lock_depth_if_needed()

			# замораживаем по X, чтобы включённая коллизия не толкала
			velocity.x = move_toward(velocity.x, 0.0, 2000.0 * delta)

			if not _can_see_player():
				_finish_attack_to_chase()
			else:
				var dx2: float = absf(player.global_position.x - global_position.x)
				var dy2: float = 0.0
				if player_lane:
					dy2 = absf(player_lane.depth_y - lane_body.depth_y)

				var depth_reach2: float = attack_range_y_px + _depth_radius_of_target(player)
				if dx2 > attack_range_px or dy2 > depth_reach2:
					_finish_attack_to_chase()
				elif attack_active:
					_apply_attack_hits()

		State.HURT:
			# FIX: во время hurt тоже не меняем глубину
			_lock_depth_if_needed()

			_play_anim_if_needed("hurt")
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			if t_hurt.is_stopped() and hp > 0:
				state = State.CHASE if _can_see_player() else State.IDLE

	move_and_slide()

# ===== corpse visual =====
func _apply_corpse_visual_offset() -> void:
	if anim == null:
		return
	# назад (против facing) и вниз
	anim.offset = corpse_offset_base + Vector2(-float(facing) * corpse_shift_back_px, corpse_shift_down_px)

func _on_anim_frame_changed() -> void:
	if attack_use_anim_frames:
		_update_attack_window_from_anim_frame()
	# старт смещения трупа с заданного кадра анимации death
	if state != State.DEAD:
		return
	if anim == null:
		return
	if anim.animation != "dead":
		return
	if death_fx_started:
		return

	if anim.frame >= corpse_offset_start_frame:
		death_fx_started = true
		_apply_corpse_visual_offset()

# ===== facing helpers =====
func _apply_facing_from_dx(dx: float) -> void:
	if absf(dx) <= maxf(0.0, facing_deadzone_px):
		return
	var dir: int = _sgn(dx)
	if dir == 0:
		return
	if dir != facing:
		facing = dir
		_set_sprite_facing(facing)
		_update_hitbox_facing()

func _set_sprite_facing(dir: int) -> void:
	if anim:
		anim.flip_h = (dir < 0)

func _update_hitbox_facing() -> void:
	if not hitbox:
		return
	var dir: float = float(max(-1, min(1, facing)))
	hitbox.position = Vector2(attack_offset.x * dir, attack_offset.y)

# ===== depth lock helpers =====
func _lock_depth_if_needed() -> void:
	if lane_body and not lane_body.depth_locked:
		lane_body.lock_depth()

func _unlock_depth_if_needed() -> void:
	if lane_body and lane_body.depth_locked:
		lane_body.unlock_depth()

# ===== lane helpers =====
func _on_lane_changed(_old: int, new_lane: int) -> void:
	_apply_lane_collision_mask(new_lane)

func _apply_lane_collision_mask(lane: int) -> void:
	var lane_layer := LaneSystem.layer_from_lane(lane)
	# Enemy body collides with WORLD + current lane obstacles
	var enemy_mask: int = LAYER_ENEMY if enemy_body_collision else 0
	collision_mask = LAYER_WORLD | lane_layer | enemy_mask

func _follow_player_depth(delta: float) -> void:
	if lane_body == null or player_lane == null:
		return
	# FIX: в атаке/хёрте глубина залочена - не трогаем
	if lane_body.depth_locked:
		return

	var target_depth: float = LaneSystem.center_from_lane(player_lane.lane_index) if snap_to_lane_centers else player_lane.depth_y
	var cur: float = lane_body.depth_y
	if absf(target_depth - cur) <= depth_stop_epsilon:
		return

	var next: float = move_toward(cur, target_depth, depth_speed * _surface_speed_multiplier() * delta)
	next = LaneSystem.clamp_depth(next)

	var next_lane: int = LaneSystem.lane_from_depth(next)
	if next_lane != lane_body.lane_index:
		if _can_switch_to_lane(next_lane):
			# apply depth (LaneBody сам обновит lane_index и эмитнет lane_changed)
			lane_body.depth_y = next
		else:
			# stop at boundary to avoid overlap
			if next_lane > lane_body.lane_index:
				lane_body.depth_y = min(lane_body.depth_y, float(LaneSystem.LANE_BOUNDS[1]))
			else:
				lane_body.depth_y = max(lane_body.depth_y, float(LaneSystem.LANE_BOUNDS[0]))
	else:
		lane_body.depth_y = next

func _can_switch_to_lane(target_lane: int) -> bool:
	var cs: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs == null or cs.shape == null:
		return true

	var space := get_world_2d().direct_space_state
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = cs.shape
	q.transform = cs.global_transform
	q.margin = 0.01
	q.exclude = [self.get_rid()]

	var lane_layer := LaneSystem.layer_from_lane(target_lane)
	q.collision_mask = LAYER_WORLD | lane_layer

	var hits := space.intersect_shape(q, 1)
	return hits.is_empty()

func _get_chase_target_x() -> float:
	if player == null:
		return global_position.x
	if not prefer_player_back:
		return player.global_position.x
	var player_dir: int = _get_player_facing_dir()
	if player_dir == 0:
		return player.global_position.x
	return player.global_position.x - float(player_dir) * back_offset_px

func _get_player_facing_dir() -> int:
	if player == null:
		return 0
	if player.has_method("skills_get_aim_dir"):
		var aim_v: Variant = player.call("skills_get_aim_dir")
		if aim_v is Vector2:
			var aim_dir: Vector2 = aim_v
			if absf(aim_dir.x) > 0.001:
				return _sgn(aim_dir.x)
	var p_anim: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if p_anim != null:
		return -1 if p_anim.flip_h else 1
	return 0

func _compute_enemy_separation_x() -> float:
	if not enable_enemy_separation:
		return 0.0
	if separation_radius_px <= 0.0 or separation_push_speed <= 0.0:
		return 0.0
	var tree: SceneTree = get_tree()
	if tree == null:
		return 0.0
	var enemies: Array[Node] = tree.get_nodes_in_group("Enemy")
	var steer: float = 0.0
	var self_lane: int = _extract_lane_index(self)
	for n in enemies:
		if n == self or not (n is Node2D):
			continue
		if not _is_enemy_alive(n):
			continue
		var n2: Node2D = n as Node2D
		var other_lane: int = _extract_lane_index(n2)
		if self_lane >= 0 and other_lane >= 0 and self_lane != other_lane:
			continue
		var dx: float = global_position.x - n2.global_position.x
		var dist_x: float = absf(dx)
		if dist_x >= separation_radius_px:
			continue
		var side: float = 0.0
		if dist_x <= 0.01:
			side = -1.0 if get_instance_id() < n2.get_instance_id() else 1.0
		else:
			side = signf(dx)
		var strength: float = 1.0 - (dist_x / separation_radius_px)
		steer += side * strength
	return clampf(steer, -1.0, 1.0) * separation_push_speed

func _extract_lane_index(n: Node) -> int:
	if n == null:
		return -1
	if n.has_node("LaneBody"):
		var lb: Node = n.get_node("LaneBody")
		if lb != null:
			var lane_v: Variant = lb.get("lane_index")
			if lane_v is int:
				return lane_v
	var lane_prop: Variant = n.get("lane_index")
	if lane_prop is int:
		return lane_prop
	return -1

func _is_enemy_alive(n: Node) -> bool:
	if n == null:
		return false
	if n.has_method("is_dead"):
		var dead_v: Variant = n.call("is_dead")
		if dead_v is bool:
			return not dead_v
	var st: Variant = n.get("state")
	if st is int and int(st) == int(State.DEAD):
		return false
	var col: CollisionShape2D = n.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col != null and col.disabled:
		return false
	return true

func _is_path_blocked_by_enemy(dir: int) -> bool:
	if dir == 0 or blocked_probe_px <= 0.0:
		return false
	var space := get_world_2d().direct_space_state
	var from: Vector2 = global_position
	var to: Vector2 = from + Vector2(float(dir) * blocked_probe_px, 0.0)
	var q := PhysicsRayQueryParameters2D.create(from, to)
	q.collision_mask = LAYER_ENEMY
	q.exclude = [self.get_rid()]
	var hit: Dictionary = space.intersect_ray(q)
	if hit.is_empty():
		return false
	var c: Object = hit.get("collider")
	var n: Node = c as Node
	if n == null or not n.is_in_group("Enemy"):
		return false
	return _is_enemy_alive(n)

func _can_try_blocked_repath() -> bool:
	return Time.get_ticks_msec() >= _blocked_repath_until_msec

func _mark_blocked_repath() -> void:
	_blocked_repath_until_msec = Time.get_ticks_msec() + int(maxf(0.0, blocked_repath_cooldown_sec) * 1000.0)

func _try_repath_around_blocker() -> void:
	if lane_body == null:
		return
	var current_lane: int = lane_body.lane_index
	var order: Array[int] = _lane_repath_order(current_lane)
	for lane in order:
		var target_lane: int = LaneSystem.clamp_lane(lane)
		if target_lane == current_lane:
			continue
		if _can_switch_to_lane(target_lane):
			lane_body.set_depth_y(LaneSystem.center_from_lane(target_lane))
			return

func _lane_repath_order(current_lane: int) -> Array[int]:
	var lanes: Array[int] = []
	var p_lane: int = current_lane
	if player_lane != null:
		p_lane = LaneSystem.clamp_lane(player_lane.lane_index)
	if current_lane < p_lane:
		lanes.append(current_lane + 1)
		lanes.append(current_lane - 1)
	elif current_lane > p_lane:
		lanes.append(current_lane - 1)
		lanes.append(current_lane + 1)
	else:
		lanes.append(current_lane - 1)
		lanes.append(current_lane + 1)
	return lanes

func _compute_support_sign() -> int:
	var id_sign: int = -1 if (get_instance_id() & 1) == 0 else 1
	if player != null:
		var rel: float = global_position.x - player.global_position.x
		if absf(rel) > 4.0:
			return _sgn(rel)
	return id_sign

func _get_support_hold_x() -> float:
	if player == null:
		return global_position.x
	var jitter_span: float = maxf(0.0, support_hold_jitter_px)
	var jitter: float = fmod(float(get_instance_id() % 1000), jitter_span * 2.0 + 1.0) - jitter_span
	var dist: float = maxf(0.0, support_hold_distance_px) + jitter
	return player.global_position.x + float(_support_sign) * dist

func _is_in_post_attack_reposition() -> bool:
	return Time.get_ticks_msec() < _post_attack_until_msec

func _mark_post_attack_reposition() -> void:
	_post_attack_until_msec = Time.get_ticks_msec() + int(maxf(0.0, post_attack_reposition_sec) * 1000.0)

func _can_switch_support_mode(want_support: bool) -> bool:
	if want_support == _support_active:
		return false
	return Time.get_ticks_msec() >= _support_switch_until_msec

func _mark_support_mode_switch() -> void:
	_support_switch_until_msec = Time.get_ticks_msec() + int(maxf(0.0, support_switch_cooldown_sec) * 1000.0)

func _can_take_attack_slot() -> bool:
	var limit: int = maxi(1, max_attackers_per_lane)
	var current: int = 0
	var my_lane: int = _extract_lane_index(self)
	var enemies: Array[Node] = get_tree().get_nodes_in_group("Enemy")
	for n in enemies:
		if n == null or not (n is Node2D):
			continue
		if not _is_enemy_alive(n):
			continue
		var st: Variant = n.get("state")
		if not (st is int) or int(st) != int(State.ATTACK):
			continue
		var n_lane: int = _extract_lane_index(n)
		if my_lane >= 0 and n_lane >= 0 and n_lane != my_lane:
			continue
		current += 1
		if current >= limit:
			return false
	return true

func is_dead() -> bool:
	return state == State.DEAD

func combat_get_depth_y() -> float:
	if lane_body != null:
		return float(lane_body.depth_y)
	return global_position.y

func combat_get_depth_radius() -> float:
	return maxf(0.0, depth_radius)

func _depth_y_of_target(target: Object) -> float:
	if target == null:
		return INF
	if target.has_method("combat_get_depth_y"):
		var dm: Variant = target.call("combat_get_depth_y")
		if dm is float or dm is int:
			return float(dm)
	var lb: Variant = target.get("lane_body")
	if lb is Object:
		var lb_obj: Object = lb as Object
		var d1: Variant = lb_obj.get("depth_y")
		if d1 is float or d1 is int:
			return float(d1)
	var d2: Variant = target.get("depth_y")
	if d2 is float or d2 is int:
		return float(d2)
	return INF

func _depth_radius_of_target(target: Object) -> float:
	if target == null:
		return 0.0
	if target.has_method("combat_get_depth_radius"):
		var rm: Variant = target.call("combat_get_depth_radius")
		if rm is float or rm is int:
			return maxf(0.0, float(rm))
	var rv: Variant = target.get("depth_radius")
	if rv is float or rv is int:
		return maxf(0.0, float(rv))
	return 0.0

func _is_target_in_depth_reach(target: Object, reach: float = 0.0) -> bool:
	if target == null:
		return false
	var my_depth: float = combat_get_depth_y()
	var target_depth: float = _depth_y_of_target(target)
	if is_inf(my_depth) or is_inf(target_depth):
		return true
	var total_reach: float = maxf(0.0, reach) + combat_get_depth_radius() + _depth_radius_of_target(target)
	return absf(my_depth - target_depth) <= total_reach

# ===== attack =====
func _start_attack() -> void:
	state = State.ATTACK
	attack_active = false
	attack_anim_lock = false

	# FIX: сразу лочим глубину на старте атаки
	_lock_depth_if_needed()

	_play_anim_if_needed("attack")
	_update_hitbox_facing()
	t_cd.start()

	# коллизия с игроком только во время атаки
	_set_collide_player(true)

	if hitbox:
		hitbox.monitoring = true
		hitbox.set_deferred("monitoring", true)

	if attack_use_anim_frames and anim and anim.sprite_frames and anim.sprite_frames.has_animation("attack"):
		_update_attack_window_from_anim_frame()
	else:
		t_hit.start(attack_hit_delay_sec)

func _on_attack_hit_window_timeout() -> void:
	attack_active = true
	var stt: SceneTreeTimer = get_tree().create_timer(attack_active_time_sec)
	stt.timeout.connect(func ():
		attack_active = false
		if hitbox:
			hitbox.monitoring = false
		attack_anim_lock = true
		_finish_attack_to_chase()
	)

func _update_attack_window_from_anim_frame() -> void:
	if state != State.ATTACK:
		return
	if anim == null:
		return
	if anim.animation != "attack":
		return

	var f: int = anim.frame
	var start_f: int = maxi(0, attack_hit_start_frame)
	var end_f: int = maxi(start_f, attack_hit_end_frame)
	var in_window: bool = f >= start_f and f <= end_f

	if in_window:
		attack_active = true
		if hitbox:
			hitbox.monitoring = true
	else:
		if attack_active:
			attack_active = false
			if hitbox:
				hitbox.monitoring = false

func _apply_attack_hits() -> void:
	if not hitbox:
		return
	var bodies: Array = hitbox.get_overlapping_bodies()
	for b in bodies:
		if b and b.is_in_group("Player") and b.has_method("apply_damage") and _is_target_in_depth_reach(b, attack_range_y_px):
			b.apply_damage(attack_damage, global_position)
			attack_active = false
			if hitbox:
				hitbox.monitoring = false
			attack_anim_lock = true
			_finish_attack_to_chase()
			break

func _on_attackarea_body_entered(body: Node) -> void:
	# запасной путь
	if not attack_active or body == null or not body.is_in_group("Player"):
		return
	if not _is_target_in_depth_reach(body, attack_range_y_px):
		return
	if body.has_method("apply_damage"):
		body.apply_damage(attack_damage, global_position)
	attack_active = false
	if hitbox:
		hitbox.monitoring = false
	attack_anim_lock = true
	_finish_attack_to_chase()

func _finish_attack_to_chase() -> void:
	if state == State.ATTACK:
		state = State.CHASE
		_set_collide_player(false)
		# глубину отпустим только после выхода в CHASE (в начале CHASE мы unlock делаем)

func _on_anim_finished() -> void:
	# если доиграла "attack" и мы уже в CHASE - снимаем блок, ставим ходьбу
	if attack_anim_lock and state == State.CHASE and anim and anim.animation == "attack":
		attack_anim_lock = false
		_play_anim_if_needed("walk")
		return

	# если почему-то ещё ATTACK - страхуемся
	if state == State.ATTACK:
		_set_collide_player(false)
		_finish_attack_to_chase()

# ===== damage / death =====
func apply_damage(dmg: int, a: Variant = null, b: Variant = null) -> void:
	if state == State.DEAD:
		return

	var from_pos: Vector2 = global_position
	var knock_vec: Vector2 = Vector2.ZERO
	if a is Vector2 and b is Vector2:
		knock_vec = a
		from_pos = b
	elif a is Vector2 and b == null:
		from_pos = a

	hp = max(hp - max(dmg, 0), 0)

	var dir_x: float = 0.0
	if knock_vec != Vector2.ZERO:
		dir_x = signf(knock_vec.x)
	elif from_pos != global_position:
		dir_x = signf(global_position.x - from_pos.x)
	if dir_x != 0.0:
		velocity.x = dir_x * absf(knockback.x)
		velocity.y = knockback.y

	if hp == 0:
		_die()
		return

	attack_active = false
	attack_anim_lock = false
	_set_collide_player(false)
	if hitbox and hitbox.monitoring:
		hitbox.monitoring = false
	if t_hit and not t_hit.is_stopped():
		t_hit.stop()

	state = State.HURT
	_lock_depth_if_needed()
	_play_hurt_anim()
	t_hurt.start(_get_hurt_stun_duration())

func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO

	# anchor corpse position immediately
	death_pos = global_position
	death_fx_started = false

	# отпускаем лок глубины (на всякий случай)
	_unlock_depth_if_needed()

	attack_anim_lock = false

	# отключаем коллизии и сенсоры
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col:
		col.disabled = true
	if sight:
		sight.monitoring = false
	if hitbox:
		hitbox.monitoring = false

	_spawn_drop()

	# принудительно играем "dead"
	if anim:
		if anim.sprite_frames and anim.sprite_frames.has_animation("dead"):
			anim.sprite_frames.set_animation_loop("dead", false)
		anim.play("dead")

		# если кадр уже >= нужного (например, анимация мгновенно перескочила), включим сразу
		if anim.frame >= corpse_offset_start_frame:
			death_fx_started = true
			_apply_corpse_visual_offset()

		# удаляемся после завершения анимации смерти + пауза
		anim.animation_finished.connect(func ():
			if anim.animation != "dead":
				return

			if corpse_lifetime_sec <= 0.0:
				queue_free()
				return

			var t := get_tree().create_timer(corpse_lifetime_sec)
			t.timeout.connect(func ():
				queue_free()
			)
		)
	else:
		if corpse_lifetime_sec <= 0.0:
			queue_free()
		else:
			var t2 := get_tree().create_timer(corpse_lifetime_sec)
			t2.timeout.connect(func ():
				queue_free()
			)

# ===== drop =====
func _spawn_drop() -> void:
	if not drop_on_death or drop_scene == null:
		return
	if randf() > clamp(drop_chance, 0.0, 1.0):
		return

	var n: Node = drop_scene.instantiate()
	var root: Node = get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	root.add_child(n)

	if n is Node2D:
		var pos: Vector2 = global_position
		pos.y -= drop_clearance_px
		pos.x += randf_range(-drop_jitter_px, drop_jitter_px)

		# Рейкаст вниз до WORLD
		var space := get_world_2d().direct_space_state
		var from: Vector2 = pos
		var to: Vector2 = pos + Vector2(0, drop_floor_probe_px)
		var q := PhysicsRayQueryParameters2D.create(from, to)
		q.collision_mask = drop_world_mask
		var hit := space.intersect_ray(q)
		if hit.has("position"):
			pos.y = (hit.position as Vector2).y - drop_clearance_px

		(n as Node2D).global_position = pos

	n.set("amount", drop_amount)

# ===== sight / helpers =====
func _on_sight_enter(body: Node) -> void:
	var p: Node2D = _resolve_player(body)
	if p:
		player = p
		player_lane = player.get_node_or_null("LaneBody") as LaneBody
		_support_sign = _compute_support_sign()
		target_in_sight = true
		if state == State.IDLE:
			state = State.CHASE

func _on_sight_exit(body: Node) -> void:
	var p: Node2D = _resolve_player(body)
	if p and p == player:
		target_in_sight = false
		player = null
		player_lane = null
		if state == State.ATTACK:
			_set_collide_player(false)
			_finish_attack_to_chase()

func _on_sight_area_enter(area: Area2D) -> void:
	_on_sight_enter(area)

func _on_sight_area_exit(area: Area2D) -> void:
	_on_sight_exit(area)

func _can_see_player() -> bool:
	if player == null or not target_in_sight:
		return false
	if not use_line_of_sight:
		return true
	# TODO: LOS ray
	return true

func _resolve_player(n: Node) -> Node2D:
	var cur: Node = n
	for i in range(3):
		if cur == null:
			break
		if cur.is_in_group("Player") and cur is Node2D:
			return cur as Node2D
		cur = cur.get_parent()
	return null

func _play_anim_if_needed(name: String) -> void:
	# не перебиваем активную "attack", если стоит блок
	if attack_anim_lock and anim and anim.animation == "attack" and anim.is_playing():
		return
	if anim and anim.animation != name:
		if name == "run" and not (anim.sprite_frames and anim.sprite_frames.has_animation("run")):
			anim.play("walk")
		else:
			anim.play(name)

func _play_hurt_anim() -> void:
	if anim == null:
		return
	if anim.sprite_frames == null or not anim.sprite_frames.has_animation("hurt"):
		return
	anim.stop()
	anim.play("hurt")

func _get_hurt_stun_duration() -> float:
	var fallback: float = maxf(0.0, hurt_stun_sec)
	if anim == null or anim.sprite_frames == null or not anim.sprite_frames.has_animation("hurt"):
		return fallback
	var hurt_duration: float = anim.sprite_frames.get_frame_count("hurt") / maxf(anim.sprite_frames.get_animation_speed("hurt"), 0.001)
	if hurt_duration <= 0.0:
		return fallback
	return maxf(fallback, minf(hurt_duration, 0.75))

func _on_attack_cooldown_timeout() -> void:
	pass

func _on_hurt_stun_timeout() -> void:
	# выходим из hurt (unlock произойдёт в следующем кадре IDLE/CHASE)
	pass

func _set_collide_player(on: bool) -> void:
	# переключаем бит маски на слой 2 (PLAYER)
	set_collision_mask_value(2, on)

func _sgn(x: float) -> int:
	if x < 0.0:
		return -1
	elif x > 0.0:
		return 1
	return 0



