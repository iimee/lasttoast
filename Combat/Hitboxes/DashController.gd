# DashController.gd — Godot 4.6 (hits + knockback robust)
extends Node
class_name DashController

@export var duration: float = 0.14
@export var speed: float = 620.0
@export var dir: Vector2 = Vector2.RIGHT

# Инерция
@export var inertia_time: float = 0.12
@export var inertia_damping: float = 22.0

# Урон / попадания
@export var damage: int = 3
@export var knockback_force: float = 220.0
@export var hit_radius: float = 18.0
@export var enemy_collision_mask: int = 0 # 0 = искать по всем слоям и фильтровать по методам
@export var depth_hit_tolerance: float = 8.0

# Столкновения со стеной
@export var stop_on_wall: bool = true
@export var stop_anim_on_wall: bool = true

var user: CharacterBody2D

var _t: float = 0.0
var _t_inertia: float = 0.0
enum State {
	DASH,
	INERTIA,
	DONE,
}
var _state: State = State.DASH

var _had_flag: bool = false
var _gravity: float = 0.0
var _dash_anim_name: StringName = &"dash"
var _anim_prev_loops: Dictionary = {}
var pierce_bonus: int = 0 # на будущее: можно использовать для пробивания спец-коллизий/целей
var _projectile_synergy_applied: bool = false

var _hit_once: Dictionary = {} # instance_id -> true
const _DASH_META_COUNT: StringName = &"_dash_controller_count"
const _DASH_META_PREV: StringName = &"_dash_controller_prev_flag"

func _ready() -> void:
	if user == null:
		queue_free()
		return

	_t = duration
	_t_inertia = max(0.0, inertia_time)
	_gravity = float(ProjectSettings.get_setting("physics/2d/default_gravity"))

	if "is_dashing" in user:
		_had_flag = true
		var count: int = int(user.get_meta(_DASH_META_COUNT, 0))
		if count <= 0:
			user.set_meta(_DASH_META_PREV, bool(user.is_dashing))
		user.set_meta(_DASH_META_COUNT, count + 1)
		user.is_dashing = true
	_set_dash_anim_loop(true)
	if user.has_method("_consume_pending_projectile_dash_combo"):
		var pending: Variant = user.call("_consume_pending_projectile_dash_combo")
		if typeof(pending) == TYPE_DICTIONARY:
			apply_projectile_synergy(pending as Dictionary)

	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if user == null:
		queue_free()
		return

	match _state:
		State.DASH:
			_dash_step(delta)
		State.INERTIA:
			_inertia_step(delta)
		_:
			_finish()

func _dash_step(delta: float) -> void:
	_t -= delta

	_ensure_dash_anim_playing()
	user.velocity.x = dir.x * speed
	if not user.is_on_floor():
		user.velocity.y += _gravity * delta
	user.move_and_slide()
	_ensure_dash_anim_playing()

	_try_projectile_synergy()
	_apply_hits()

	if stop_on_wall and _hit_blocking_surface():
		_stop_on_collision()
		return

	if _t <= 0.0:
		if _t_inertia > 0.0:
			_state = State.INERTIA
		else:
			_state = State.DONE

func _inertia_step(delta: float) -> void:
	_t_inertia -= delta

	_ensure_dash_anim_playing()
	var k: float = maxf(0.0, 1.0 - inertia_damping * delta)
	user.velocity.x *= k
	if not user.is_on_floor():
		user.velocity.y += _gravity * delta
	user.move_and_slide()
	_ensure_dash_anim_playing()

	if stop_on_wall and _hit_blocking_surface():
		_stop_on_collision()
		return

	if _t_inertia <= 0.0 or user.velocity.length() < 5.0:
		user.velocity = Vector2.ZERO
		_state = State.DONE

func _hit_blocking_surface() -> bool:
	return user.is_on_wall() or user.is_on_ceiling()

func _stop_on_collision() -> void:
	user.velocity = Vector2.ZERO

	if stop_anim_on_wall and user.has_node("AnimatedSprite2D"):
		var spr: AnimatedSprite2D = user.get_node("AnimatedSprite2D") as AnimatedSprite2D
		var dash_anim: StringName = _get_dash_anim_name_for_sprite(spr)
		if spr and dash_anim != StringName() and spr.animation == dash_anim:
			spr.stop()

	_state = State.DONE

func _set_dash_anim_loop(enabled: bool) -> void:
	if user == null or not user.has_node("AnimatedSprite2D"):
		return
	var spr: AnimatedSprite2D = user.get_node("AnimatedSprite2D") as AnimatedSprite2D
	if spr == null or spr.sprite_frames == null:
		return
	var anim_name: StringName = _get_dash_anim_name_for_sprite(spr)
	if anim_name == StringName():
		return

	if not _anim_prev_loops.has(anim_name):
		_anim_prev_loops[anim_name] = bool(spr.sprite_frames.get_animation_loop(anim_name))

	spr.sprite_frames.set_animation_loop(anim_name, enabled)
	if enabled and spr.animation == anim_name and not spr.is_playing():
		spr.play(String(anim_name))

func _ensure_dash_anim_playing() -> void:
	if user == null or not user.has_node("AnimatedSprite2D"):
		return
	var spr: AnimatedSprite2D = user.get_node("AnimatedSprite2D") as AnimatedSprite2D
	if spr == null or spr.sprite_frames == null:
		return
	var anim_name: StringName = _get_dash_anim_name_for_sprite(spr)
	if anim_name == StringName():
		return
	if not bool(spr.sprite_frames.get_animation_loop(anim_name)):
		spr.sprite_frames.set_animation_loop(anim_name, true)
	if spr.speed_scale <= 0.0:
		spr.speed_scale = 1.0
	if spr.animation != anim_name or not spr.is_playing():
		spr.play(String(anim_name))

func _get_dash_anim_name_for_sprite(spr: AnimatedSprite2D) -> StringName:
	if spr == null or spr.sprite_frames == null:
		return StringName()
	if _dash_anim_name != StringName() and spr.sprite_frames.has_animation(_dash_anim_name):
		return _dash_anim_name
	if spr.sprite_frames.has_animation(&"dash"):
		return &"dash"
	return StringName()

func set_dash_anim_name(anim_name: StringName) -> void:
	if anim_name == StringName():
		return
	_dash_anim_name = anim_name
	_set_dash_anim_loop(true)
	_ensure_dash_anim_playing()

func apply_projectile_synergy(payload: Dictionary) -> void:
	if payload.is_empty():
		return

	var speed_mul: float = maxf(0.05, float(payload.get("speed_mul", 1.0)))
	var knock_mul: float = maxf(0.05, float(payload.get("knockback_mul", 1.0)))
	var add_pierce: int = max(0, int(payload.get("pierce_bonus", 0)))
	var anim_name: StringName = StringName(payload.get("anim_name", &""))

	speed *= speed_mul
	knockback_force *= knock_mul
	pierce_bonus += add_pierce

	if anim_name != StringName():
		_dash_anim_name = anim_name

	_set_dash_anim_loop(true)
	_ensure_dash_anim_playing()
	_projectile_synergy_applied = true

func _try_projectile_synergy() -> void:
	if _projectile_synergy_applied:
		return
	if user == null:
		return

	var nodes: Array = get_tree().get_nodes_in_group("attack")
	for n in nodes:
		if n == null or n == user:
			continue
		if not (n is Node2D):
			continue
		var o := n as Object
		if o == null:
			continue
		if not o.has_method("try_apply_dash_combo_from_player"):
			continue
		if bool(o.call("try_apply_dash_combo_from_player", user)):
			return

# -------------------------
# HITS / DAMAGE / KNOCKBACK
# -------------------------
func _apply_hits() -> void:
	if damage <= 0 or hit_radius <= 0.0:
		return

	var space := user.get_world_2d().direct_space_state
	if space == null:
		return

	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = hit_radius

	var params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, user.global_position)
	params.collide_with_areas = true
	params.collide_with_bodies = true

	# FIX: игрок маской врагов не видит — поэтому по умолчанию ищем по всем слоям
	params.collision_mask = enemy_collision_mask if enemy_collision_mask != 0 else 0x7FFFFFFF
	params.exclude = [user.get_rid()]

	var results: Array = space.intersect_shape(params, 32)

	for r in results:
		var raw: Object = r.get("collider") as Object
		if raw == null:
			continue

		var target: Object = _resolve_damage_target(raw)
		if target == null or target == user:
			continue

		# Фильтр: не бьём мир/тайлы. Бьём тех, у кого есть damage API или кто в группе.
		if not _is_damageable(target):
			continue
		if not _is_same_lane_or_unknown(target):
			continue

		var id: int = target.get_instance_id()
		if _hit_once.has(id):
			continue
		_hit_once[id] = true

		var kb: Vector2 = dir * knockback_force

		_deal_damage(target, kb)
		_apply_knockback_to(target, kb)

func _resolve_damage_target(obj: Object) -> Object:
	# Если попали в Area2D-хёртбокс — часто реальный враг в parent.
	if obj is Area2D:
		var a := obj as Area2D
		var p := a.get_parent()
		if p != null:
			return p
	return obj

func _is_same_lane_or_unknown(obj: Object) -> bool:
	if user == null:
		return true
	var uo := user as Object
	if uo == null:
		return true
	var user_depth: float = _extract_depth_y(uo)
	if is_inf(user_depth):
		return true
	var target_depth: float = _extract_depth_y(obj)
	if is_inf(target_depth):
		return true
	return absf(target_depth - user_depth) <= maxf(0.0, depth_hit_tolerance)

func _extract_depth_y(obj: Object) -> float:
	if obj == null:
		return INF
	var lb = obj.get("lane_body")
	if lb != null and lb is Object:
		var lbo := lb as Object
		var d = lbo.get("depth_y")
		if typeof(d) == TYPE_FLOAT or typeof(d) == TYPE_INT:
			return float(d)
	var d2 = obj.get("depth_y")
	if typeof(d2) == TYPE_FLOAT or typeof(d2) == TYPE_INT:
		return float(d2)
	return INF

func _extract_lane_index(obj: Object) -> int:
	if obj == null:
		return -1

	var lb = obj.get("lane_body")
	if lb != null and lb is Object:
		var lbo := lb as Object
		var li = lbo.get("lane_index")
		if typeof(li) == TYPE_INT:
			return int(li)

	var li2 = obj.get("lane_index")
	if typeof(li2) == TYPE_INT:
		return int(li2)

	return -1

func _is_damageable(obj: Object) -> bool:
	if obj.has_method("take_damage"):
		return true
	if obj.has_method("apply_damage"):
		return true
	if obj.has_method("hurt"):
		return true
	if obj is Node:
		var n := obj as Node
		# поддержка групп, если у тебя есть
		if n.is_in_group("Enemy") or n.is_in_group("Enemies"):
			return true
	return false

func _deal_damage(obj: Object, kb: Vector2) -> void:
	# разные сигнатуры
	if obj.has_method("take_damage"):
		# (damage, attacker, knockback)
		obj.call("take_damage", damage, user, kb)
	elif obj.has_method("apply_damage"):
		# твой player принимает apply_damage(amount, a, b)
		# для врагов сделаем так же: (amount, knock_vec, from_pos)
		obj.call("apply_damage", damage, kb, user.global_position)
	elif obj.has_method("hurt"):
		obj.call("hurt", damage, user)

func _apply_knockback_to(obj: Object, kb: Vector2) -> void:
	# 1) если у врага есть нормальный API — используем
	if obj.has_method("apply_knockback"):
		obj.call("apply_knockback", kb)
		return
	if obj.has_method("add_knockback"):
		obj.call("add_knockback", kb)
		return
	if obj.has_method("knockback"):
		obj.call("knockback", kb)
		return

	# 2) если у врага есть поле под импульс — закидываем туда
	if obj.has_method("set"):
		# common patterns
		if obj.get("external_impulse") != null:
			obj.set("external_impulse", (obj.get("external_impulse") as Vector2) + kb)
			return
		if obj.get("knockback_velocity") != null:
			obj.set("knockback_velocity", (obj.get("knockback_velocity") as Vector2) + kb)
			return

	# 3) fallback для CharacterBody2D
	if obj is CharacterBody2D:
		var e := obj as CharacterBody2D
		e.velocity += kb

func _finish() -> void:
	if user and user.has_node("AnimatedSprite2D"):
		var spr: AnimatedSprite2D = user.get_node("AnimatedSprite2D") as AnimatedSprite2D
		if spr and spr.sprite_frames:
			for k in _anim_prev_loops.keys():
				var anim_name: StringName = StringName(k)
				if spr.sprite_frames.has_animation(anim_name):
					spr.sprite_frames.set_animation_loop(anim_name, bool(_anim_prev_loops[k]))
	_anim_prev_loops.clear()

	if user and _had_flag:
		var count: int = maxi(0, int(user.get_meta(_DASH_META_COUNT, 0)) - 1)
		if count > 0:
			user.set_meta(_DASH_META_COUNT, count)
			user.is_dashing = true
		else:
			if user.has_meta(_DASH_META_COUNT):
				user.remove_meta(_DASH_META_COUNT)
			var prev_flag: bool = bool(user.get_meta(_DASH_META_PREV, false))
			if user.has_meta(_DASH_META_PREV):
				user.remove_meta(_DASH_META_PREV)
			user.is_dashing = prev_flag

	# Если дэш закончен и на спрайте остался стоп/0 speed_scale,
	# просим игрока вернуть locomotion.
	if user and user.has_node("AnimatedSprite2D"):
		var spr: AnimatedSprite2D = user.get_node("AnimatedSprite2D") as AnimatedSprite2D
		if spr and spr.speed_scale <= 0.0:
			spr.speed_scale = 1.0
	if user and user.has_method("_return_to_motion_anim") and (not bool(user.is_dashing)):
		user.call("_return_to_motion_anim")
	queue_free()
