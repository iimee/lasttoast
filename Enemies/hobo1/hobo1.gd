# hobo1.gd — Godot 4.5
# enemy: sight → chase (stop near) → attack (non-loop, timed hit)
# pseudo-3D depth with 3 combat lanes via LaneSystem + LaneBody
# IMPORTANT:
# - Depth moves ONLY visuals (LaneBody.visual_root_path). Physics body Y is not used for lane.
# - Enemy collision mask switches to WORLD + current lane layer (9..11) so old lane obstacles work again.
# - Vertical distance checks use depth_y, not global_position.y.
# - FIX: during ATTACK/HURT depth is LOCKED (no lane drift while attacking or in skills-like states).
# - FIX: default idle faces left.
# - FIX: DEAD anchors root position and forces corpse visual offset (shift back+down) starting from frame 2 of "dead".

extends CharacterBody2D

# ===== movement / physics =====
@export var walk_speed: float = 60.0
@export var run_speed: float = 90.0
@export var use_run_when_close: bool = true
@export var run_switch_distance: float = 120.0
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var max_fall_speed: float = 900.0
@export var stop_distance_px: float = 18.0        # стоп-граница в CHASE

# ===== pseudo-3D / lanes =====
@export var depth_speed: float = 120.0
@export var depth_follow_distance_px: float = 160.0   # когда начинаем подстраиваться по глубине
@export var depth_stop_epsilon: float = 1.0
@export var match_player_lane_when_close: bool = true
@export var snap_to_lane_centers: bool = true         # ехать к центру полосы игрока (а не к его depth_y)

# ===== attack =====
@export var attack_range_px: float = 28.0
@export var attack_range_y_px: float = 20.0
@export var attack_damage: int = 10
@export var attack_cooldown_sec: float = 0.9
@export var attack_hit_delay_sec: float = 0.22
@export var attack_active_time_sec: float = 0.16
@export var attack_offset: Vector2 = Vector2(18, -6)

# ===== hp / hurt =====
@export var hp_max: int = 40
@export var knockback: Vector2 = Vector2(120, -140)

# ===== vision =====
@export var use_line_of_sight: bool = false

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

func _ready() -> void:
	hp = hp_max

	# remember base sprite offset
	if anim:
		corpse_offset_base = anim.offset

	# apply default facing immediately (idle left)
	_set_sprite_facing(facing)

	# "attack" — без зацикливания
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
	set_collision_mask_value(3, false)
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

				var dx: float = player.global_position.x - global_position.x
				var dy: float = 0.0
				if player_lane:
					dy = player_lane.depth_y - lane_body.depth_y

				_apply_facing_from_dx(dx)

				var dist_x: float = absf(dx)
				var dist_y: float = absf(dy)

				var in_attack_box: bool = dist_x <= attack_range_px and dist_y <= attack_range_y_px
				var near_border: bool = dist_x <= max(attack_range_px, stop_distance_px)

				if in_attack_box and is_on_floor() and t_cd.is_stopped():
					_start_attack()
				else:
					var speed: float = run_speed if (use_run_when_close and dist_x < run_switch_distance) else walk_speed
					if near_border:
						velocity.x = move_toward(velocity.x, 0.0, 2000.0 * delta)
						_play_anim_if_needed("idle")
					else:
						velocity.x = float(facing) * speed
						_play_anim_if_needed("run" if speed >= run_speed else "walk")

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

				if dx2 > attack_range_px or dy2 > attack_range_y_px:
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
	collision_mask = LAYER_WORLD | lane_layer

func _follow_player_depth(delta: float) -> void:
	if lane_body == null or player_lane == null:
		return
	# FIX: в атаке/хёрте глубина залочена — не трогаем
	if lane_body.depth_locked:
		return

	var target_depth: float = LaneSystem.center_from_lane(player_lane.lane_index) if snap_to_lane_centers else player_lane.depth_y
	var cur: float = lane_body.depth_y
	if absf(target_depth - cur) <= depth_stop_epsilon:
		return

	var next: float = move_toward(cur, target_depth, depth_speed * delta)
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

func _apply_attack_hits() -> void:
	if not hitbox:
		return
	var bodies: Array = hitbox.get_overlapping_bodies()
	for b in bodies:
		if b and b.is_in_group("Player") and b.has_method("apply_damage"):
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
	# если доиграла "attack" и мы уже в CHASE — снимаем блок, ставим ходьбу
	if attack_anim_lock and state == State.CHASE and anim and anim.animation == "attack":
		attack_anim_lock = false
		_play_anim_if_needed("walk")
		return

	# если почему-то ещё ATTACK — страхуемся
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

	state = State.HURT
	_lock_depth_if_needed()
	t_hurt.start(0.25)

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
