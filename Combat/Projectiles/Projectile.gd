extends Area2D
# Projectile.gd (SmokeRing piercing)
# - Lane: смещаем только AnimatedSprite2D по depth_y
# - Не удаляемся об НЕ-врагов
# - По врагу: наносим урон + спавним hit-анимацию, но ПРОДОЛЖАЕМ ЛЕТЕТЬ
# - Анти-спам: один хит на цель за жизнь прожектайла (можно поменять)

@export var damage: int = 2
@export var knockback: float = 50.0
@export var enemy_group: String = "Enemy"

@export var lifetime: float = 2.2
@export var rotate_with_flight: bool = false
@export var start_on_ready: bool = false

# grace режет только НЕ-врагов (point-blank по врагам не режем)
@export var spawn_grace: float = 0.06
@export var depth_hit_tolerance: float = 8.0

@export var ignore_groups: Array[String] = ["Player", "attack"]

# --- animations ---
@export var fly_anim: StringName = &"smoke"
@export var hit_anim: StringName = &"smoke_hit"
@export var spawn_hit_fx: bool = true

# анти-спам: 1 = только один раз по каждой цели за жизнь прожектайла
@export var max_hits_per_target: int = 1
@export var dash_combo_enabled: bool = true
@export var dash_combo_speed_mul: float = 1.35
@export var dash_combo_knockback_mul: float = 1.60
@export var dash_combo_pierce_bonus: int = 1
@export var dash_combo_anim: StringName = &"dash2"
@export var dash_combo_consume_projectile: bool = false
@export var dash_combo_trigger_radius: float = 28.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var lifetime_timer: Timer = $LifetimeTimer

var direction: Vector2 = Vector2.RIGHT
var speed: float = 50.0
enum State { IDLE, FLYING, DESTROYED }
var _state: State = State.IDLE
var _active: bool = false
var _alive_time: float = 0.0
var _dash_combo_consumed: bool = false

# instance_id -> hits_count
var _hit_counts: Dictionary = {}

# ===== lane (visual only) =====
var lane_index: int = -1 : set = _set_lane_index
var depth_y: float = 0.0
var _anim_base_y: float = 0.0

func _set_lane_index(v: int) -> void:
	lane_index = v
	depth_y = 0.0
	if lane_index != -1:
		depth_y = LaneSystem.center_from_lane(lane_index)
	_apply_lane_visual()

func set_lane_index(i: int) -> void:
	_set_lane_index(i)

func set_depth_y(v: float) -> void:
	depth_y = v
	_apply_lane_visual()

func _apply_lane_visual() -> void:
	if anim:
		anim.position.y = _anim_base_y + depth_y

func setup(dir: Vector2, spd: float) -> void:
	# FIX: если dir нулевой — прожектайл будет "стоять"
	var d := dir
	if d.length_squared() < 0.000001:
		var sign := 1.0
		if anim and anim.scale.x < 0.0:
			sign = -1.0
		d = Vector2(sign, 0.0)

	direction = d.normalized()
	speed = spd
	_state = State.FLYING
	_active = true
	_alive_time = 0.0
	set_physics_process(true)

	if rotate_with_flight:
		rotation = direction.angle()

func _ready() -> void:
	monitoring = true
	monitorable = true
	add_to_group("attack")

	if anim:
		_anim_base_y = anim.position.y
	_apply_lane_visual()

	if anim and anim.sprite_frames:
		if anim.sprite_frames.has_animation(fly_anim):
			# smoke может быть не-loop — ок
			anim.sprite_frames.set_animation_loop(fly_anim, false)
		if anim.sprite_frames.has_animation(hit_anim):
			# важно: hit не должен лупиться, иначе FX не исчезнет
			anim.sprite_frames.set_animation_loop(hit_anim, false)

	if anim and anim.sprite_frames and anim.sprite_frames.has_animation(fly_anim):
		anim.play(fly_anim)

	if not body_entered.is_connected(_on_hit):
		body_entered.connect(_on_hit)
	if not area_entered.is_connected(_on_hit):
		area_entered.connect(_on_hit)

	if is_instance_valid(lifetime_timer):
		lifetime_timer.one_shot = true
		lifetime_timer.wait_time = lifetime
		if not lifetime_timer.timeout.is_connected(_on_lifetime_timeout):
			lifetime_timer.timeout.connect(_on_lifetime_timeout)
		lifetime_timer.start()

	if start_on_ready:
		setup(direction, speed)
	else:
		set_physics_process(false)

func _physics_process(delta: float) -> void:
	match _state:
		State.FLYING:
			if not _active:
				return
			_alive_time += delta
			position += direction * speed * delta
			if rotate_with_flight:
				rotation = direction.angle()
		_:
			return

func _on_hit(other: Node) -> void:
	if _try_apply_dash_combo(other):
		return

	if _is_in_ignored_group(other):
		return

	var tgt := _resolve_enemy(other)

	# grace режет только НЕ-врагов
	if _alive_time < spawn_grace and tgt == null:
		return

	# НЕ враг → игнор (и НЕ удаляем)
	if tgt == null:
		return

	if not _is_same_lane_or_unknown(tgt):
		return

	# анти-спам по одной цели
	var id := tgt.get_instance_id()
	var cnt := int(_hit_counts.get(id, 0))
	if max_hits_per_target > 0 and cnt >= max_hits_per_target:
		return
	_hit_counts[id] = cnt + 1

	# урон
	if tgt.has_method("apply_damage"):
		tgt.apply_damage(damage, direction * knockback, global_position)

	# hit FX (но ПРОДОЛЖАЕМ ЛЕТЕТЬ)
	if spawn_hit_fx:
		_spawn_hit_fx()

func _spawn_hit_fx() -> void:
	if anim == null or anim.sprite_frames == null:
		return
	if not anim.sprite_frames.has_animation(hit_anim):
		return

	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = anim.sprite_frames
	fx.animation = String(hit_anim)
	fx.frame = 0
	fx.speed_scale = 1.0

	# чтобы выглядело идентично и по lane тоже совпадало
	fx.position = anim.position
	fx.scale = anim.scale
	fx.flip_h = anim.flip_h
	fx.flip_v = anim.flip_v
	fx.z_index = anim.z_index

	add_child(fx)
	fx.play()

	# гарантированно удалить FX после окончания
	fx.animation_finished.connect(func():
		if is_instance_valid(fx):
			fx.queue_free()
	)

func _on_lifetime_timeout() -> void:
	_state = State.DESTROYED
	queue_free()

func try_apply_dash_combo_from_player(player: Node) -> bool:
	if not (player is Node2D):
		return false
	var p2d := player as Node2D
	if global_position.distance_to(p2d.global_position) > dash_combo_trigger_radius:
		return false
	return _try_apply_dash_combo(player)

func _try_apply_dash_combo(other: Node) -> bool:
	if not dash_combo_enabled or _dash_combo_consumed:
		return false

	var player := _resolve_dash_player(other)
	if player == null:
		return false

	var po := player as Object
	if po == null:
		return false
	if not _object_has_property(po, &"is_dashing"):
		return false
	if not bool(po.get("is_dashing")):
		return false
	if not _is_same_lane_player(player):
		return false
	if not player.has_method("apply_projectile_dash_combo"):
		return false

	var payload: Dictionary = {
		"speed_mul": dash_combo_speed_mul,
		"knockback_mul": dash_combo_knockback_mul,
		"pierce_bonus": dash_combo_pierce_bonus,
		"anim_name": dash_combo_anim,
	}
	player.call("apply_projectile_dash_combo", payload)

	_dash_combo_consumed = true
	if dash_combo_consume_projectile:
		_state = State.DESTROYED
		queue_free()
	return true

func _resolve_dash_player(n: Node) -> Node:
	var cur: Node = n
	for i in range(5):
		if cur == null:
			return null
		if cur is CharacterBody2D and cur.has_method("apply_projectile_dash_combo"):
			return cur
		cur = cur.get_parent()
	return null

func _is_same_lane_player(player: Node) -> bool:
	var player_depth: float = _get_target_depth_y(player)
	if is_inf(player_depth):
		return true
	return absf(player_depth - depth_y) <= maxf(0.0, depth_hit_tolerance)

func _object_has_property(o: Object, prop: StringName) -> bool:
	if o == null:
		return false
	for d in o.get_property_list():
		if d.has("name") and StringName(d.name) == prop:
			return true
	return false

func _resolve_enemy(n: Node) -> Node:
	var cur: Node = n
	for i in range(4):
		if cur == null:
			return null
		# враг = в группе ИЛИ имеет apply_damage
		if cur.is_in_group(enemy_group) or cur.has_method("apply_damage"):
			return cur
		cur = cur.get_parent()
	return null

func _is_same_lane_or_unknown(target: Node) -> bool:
	var target_depth: float = _get_target_depth_y(target)
	if is_inf(target_depth):
		return true
	return absf(target_depth - depth_y) <= maxf(0.0, depth_hit_tolerance)

func _get_target_depth_y(target: Node) -> float:
	if target == null:
		return INF
	if not (target is Object):
		return INF

	var to := target as Object
	var lb = to.get("lane_body")
	if lb != null and lb is Object:
		var lbo := lb as Object
		var d1 = lbo.get("depth_y")
		if typeof(d1) == TYPE_FLOAT or typeof(d1) == TYPE_INT:
			return float(d1)

	var d2 = to.get("depth_y")
	if typeof(d2) == TYPE_FLOAT or typeof(d2) == TYPE_INT:
		return float(d2)

	return INF

func _get_target_lane(target: Node) -> int:
	if target == null:
		return -1
	if not (target is Object):
		return -1

	var to := target as Object
	var lb = to.get("lane_body")
	if lb != null and lb is Object:
		var lbo := lb as Object
		var li = lbo.get("lane_index")
		if typeof(li) == TYPE_INT:
			return int(li)

	var li2 = to.get("lane_index")
	if typeof(li2) == TYPE_INT:
		return int(li2)

	return -1

func _is_in_ignored_group(n: Node) -> bool:
	var cur: Node = n
	for i in range(4):
		if cur == null:
			return false
		for g in ignore_groups:
			if cur.is_in_group(g):
				return true
		cur = cur.get_parent()
	return false
