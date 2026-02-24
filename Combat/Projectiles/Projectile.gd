extends Area2D
# Projectile.gd (SmokeRing piercing)
# - Lane: смещаем только AnimatedSprite2D по depth_y
# - Не удаляемся об НЕ-врагов
# - По врагу: наносим урон + спавним hit-анимацию, но ПРОДОЛЖАЕМ ЛЕТЕТЬ
# - Анти-спам: один хит на цель за жизнь прожектайла (можно поменять)

@export var damage: int = 5
@export var knockback: float = 50.0
@export var enemy_group: String = "Enemy"

@export var lifetime: float = 2.2
@export var rotate_with_flight: bool = false
@export var start_on_ready: bool = false

# grace режет только НЕ-врагов (point-blank по врагам не режем)
@export var spawn_grace: float = 0.06

@export var ignore_groups: Array[String] = ["Player", "attack"]

# --- animations ---
@export var fly_anim: StringName = &"smoke"
@export var hit_anim: StringName = &"smoke_hit"
@export var spawn_hit_fx: bool = true

# анти-спам: 1 = только один раз по каждой цели за жизнь прожектайла
@export var max_hits_per_target: int = 1

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var lifetime_timer: Timer = $LifetimeTimer

var direction: Vector2 = Vector2.RIGHT
var speed: float = 50.0
var _active: bool = false
var _alive_time: float = 0.0

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
	if not _active:
		return
	_alive_time += delta
	position += direction * speed * delta
	if rotate_with_flight:
		rotation = direction.angle()

func _on_hit(other: Node) -> void:
	if _is_in_ignored_group(other):
		return

	var tgt := _resolve_enemy(other)

	# grace режет только НЕ-врагов
	if _alive_time < spawn_grace and tgt == null:
		return

	# НЕ враг → игнор (и НЕ удаляем)
	if tgt == null:
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
	queue_free()

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
