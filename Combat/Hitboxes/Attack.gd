# Attack.gd — attach to root Area2D of Attack.tscn
extends Area2D

@export var damage: int = 1
@export var attack_duration: float = 0.12
@export var hit_once_per_enemy: bool = true
@export var hit_knockback: Vector2 = Vector2(160, -120)
@export var attacker_pushback_x: float = 28.0
@export var depth_radius_fallback: float = 8.0

signal hit(target: Node)

var _active: bool = false
var _already_hit := {}

func _ready() -> void:
	monitoring = false
	connect("body_entered", Callable(self, "_on_body_entered"))

func swing(origin_global_pos: Vector2, aim_dir: Vector2, owner_is_grounded: bool) -> void:
	if _active:
		return
	_active = true
	_already_hit.clear()
	monitoring = true
	_self_disable_after(attack_duration)

func _self_disable_after(t: float) -> void:
	await get_tree().create_timer(t).timeout
	_active = false
	monitoring = false

func _player_owner() -> Node:
	# Узел атаки обычно — ребёнок игрока
	var p := get_parent()
	if p and p.is_in_group("Player"):
		return p
	# запасной вариант
	return get_tree().get_first_node_in_group("Player")

func _final_damage() -> int:
	var p := _player_owner()
	var bonus := 0
	if p and p.has_method("get_outgoing_damage_bonus"):
		bonus = int(p.get_outgoing_damage_bonus())
	# Если у игрока есть get_melee_damage — используем его (учтёт базу + бонусы)
	if p and p.has_method("get_melee_damage"):
		return int(p.get_melee_damage())
	return int(max(0, damage + bonus))

func _on_body_entered(body: Node) -> void:
	if not _active:
		return
	if body == null:
		return
	# не бить игрока
	if body == get_parent() or body.is_in_group("Player"):
		return

	var target: Node = null
	if body.has_method("apply_damage"):
		target = body
	elif body.get_parent() != null and body.get_parent().has_method("apply_damage"):
		target = body.get_parent()
	if target == null:
		return
	if hit_once_per_enemy and _already_hit.has(target):
		return
	if not _is_target_in_depth_reach(target):
		return

	var dmg := _final_damage()

	var applied: bool = false
	if target is Node2D:
		var target_n2d: Node2D = target as Node2D
		var kb = Vector2(signf(target_n2d.global_position.x - global_position.x) * hit_knockback.x, hit_knockback.y)
		target.call("apply_damage", dmg, kb, global_position)
		applied = true
	else:
		target.call("apply_damage", dmg, global_position)
		applied = true

	if applied:
		_apply_attacker_pushback(target)
		_already_hit[target] = true
		emit_signal("hit", target)

func _apply_attacker_pushback(target: Node) -> void:
	if attacker_pushback_x <= 0.0:
		return
	var owner := _player_owner()
	if owner == null or not (owner is CharacterBody2D):
		return
	if target == null or not (target is Node2D):
		return

	var attacker := owner as CharacterBody2D
	var target_n2d := target as Node2D
	var dir_x := signf(target_n2d.global_position.x - attacker.global_position.x)
	if dir_x == 0.0:
		return
	attacker.velocity.x -= dir_x * attacker_pushback_x

func _is_target_in_depth_reach(target: Node) -> bool:
	var owner_obj: Object = _player_owner() as Object
	var target_obj: Object = target as Object
	if owner_obj == null or target_obj == null:
		return true
	var my_depth: float = _depth_y_of(owner_obj)
	var target_depth: float = _depth_y_of(target_obj)
	if is_inf(my_depth) or is_inf(target_depth):
		return true
	var my_radius: float = _depth_radius_of(owner_obj)
	var target_radius: float = _depth_radius_of(target_obj)
	return absf(my_depth - target_depth) <= (my_radius + target_radius)

func _depth_y_of(obj: Object) -> float:
	if obj == null:
		return INF
	if obj.has_method("combat_get_depth_y"):
		var mv: Variant = obj.call("combat_get_depth_y")
		if mv is float or mv is int:
			return float(mv)
	var lb: Variant = obj.get("lane_body")
	if lb is Object:
		var lb_obj: Object = lb as Object
		var d1: Variant = lb_obj.get("depth_y")
		if d1 is float or d1 is int:
			return float(d1)
	var d2: Variant = obj.get("depth_y")
	if d2 is float or d2 is int:
		return float(d2)
	return INF

func _depth_radius_of(obj: Object) -> float:
	if obj == null:
		return maxf(0.0, depth_radius_fallback)
	if obj.has_method("combat_get_depth_radius"):
		var mv: Variant = obj.call("combat_get_depth_radius")
		if mv is float or mv is int:
			return maxf(0.0, float(mv))
	var r: Variant = obj.get("depth_radius")
	if r is float or r is int:
		return maxf(0.0, float(r))
	return maxf(0.0, depth_radius_fallback)
