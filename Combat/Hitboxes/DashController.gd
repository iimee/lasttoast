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
@export var damage: int = 10
@export var knockback_force: float = 220.0
@export var hit_radius: float = 18.0
@export var enemy_collision_mask: int = 0 # 0 = искать по всем слоям и фильтровать по методам

# Столкновения со стеной
@export var stop_on_wall: bool = true
@export var stop_anim_on_wall: bool = true

var user: CharacterBody2D

var _t: float = 0.0
var _t_inertia: float = 0.0
var _phase: int = 0 # 0=dash, 1=inertia, 2=done

var _had_flag: bool = false
var _saved_flag: bool = false

var _hit_once: Dictionary = {} # instance_id -> true

func _ready() -> void:
	if user == null:
		queue_free()
		return

	_t = duration
	_t_inertia = max(0.0, inertia_time)

	if "is_dashing" in user:
		_had_flag = true
		_saved_flag = bool(user.is_dashing)
		user.is_dashing = true

	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if user == null:
		queue_free()
		return

	match _phase:
		0:
			_dash_step(delta)
		1:
			_inertia_step(delta)
		_:
			_finish()

func _dash_step(delta: float) -> void:
	_t -= delta

	user.velocity = dir * speed
	user.move_and_slide()

	_apply_hits()

	if stop_on_wall and _hit_blocking_surface():
		_stop_on_collision()
		return

	if _t <= 0.0:
		if _t_inertia > 0.0:
			_phase = 1
		else:
			_phase = 2

func _inertia_step(delta: float) -> void:
	_t_inertia -= delta

	var k: float = maxf(0.0, 1.0 - inertia_damping * delta)
	user.velocity *= k
	user.move_and_slide()

	if stop_on_wall and _hit_blocking_surface():
		_stop_on_collision()
		return

	if _t_inertia <= 0.0 or user.velocity.length() < 5.0:
		user.velocity = Vector2.ZERO
		_phase = 2

func _hit_blocking_surface() -> bool:
	return user.is_on_wall() or user.is_on_ceiling()

func _stop_on_collision() -> void:
	user.velocity = Vector2.ZERO

	if stop_anim_on_wall and user.has_node("AnimatedSprite2D"):
		var spr: AnimatedSprite2D = user.get_node("AnimatedSprite2D") as AnimatedSprite2D
		if spr and spr.animation == "dash":
			spr.stop()

	_phase = 2

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
	if user and _had_flag:
		user.is_dashing = _saved_flag
	queue_free()
