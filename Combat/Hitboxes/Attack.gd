# Attack.gd — attach to root Area2D of Attack.tscn
extends Area2D

@export var damage: int = 1
@export var attack_duration: float = 0.12
@export var hit_once_per_enemy: bool = true
@export var hit_knockback: Vector2 = Vector2(160, -120)

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
	if hit_once_per_enemy and _already_hit.has(body):
		return

	var applied: bool = false
	var dmg := _final_damage()

	if body.has_method("apply_damage"):
		var kb = Vector2(sign(body.global_position.x - global_position.x) * hit_knockback.x, hit_knockback.y)
		body.apply_damage(dmg, global_position, kb)
		applied = true
	elif body.get_parent() != null and body.get_parent().has_method("apply_damage"):
		var p = body.get_parent()
		var kb2 = Vector2(sign(p.global_position.x - global_position.x) * hit_knockback.x, hit_knockback.y)
		p.apply_damage(dmg, global_position, kb2)
		applied = true

	if applied:
		_already_hit[body] = true
		emit_signal("hit", body)
