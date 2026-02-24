extends Area2D
# Hitbox рвоты: бьёт по врагам и удаляется по таймеру. ВИЗУАЛЬНОЙ АНИМАЦИИ ТУТ НЕТ.

@export var damage: int = 1
@export var knockback: float = 140.0
@export var enemy_group: String = "Enemy"
@export var ignore_groups: Array[String] = ["Player"]

@export var lifetime: float = 0.22 # подгони под длительность анимации "vomit" у игрока

var _facing: Vector2 = Vector2.RIGHT
var _hit_once: bool = true
var _hit_cache: Dictionary = {}

var facing: Vector2:
	set(value):
		_facing = value
	get:
		return _facing

var direction: Vector2:
	set(value):
		facing = value
	get:
		return facing

func _ready() -> void:
	monitoring = true
	monitorable = true
	add_to_group("attack")

	area_entered.connect(_on_area)
	body_entered.connect(_on_body)

	if lifetime > 0.0:
		get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _on_area(a: Area2D) -> void:
	_apply_hit(a)

func _on_body(b: Node2D) -> void:
	_apply_hit(b)

func _should_hit(target: Node) -> bool:
	if target == null:
		return false
	for g in ignore_groups:
		if target.is_in_group(g):
			return false
	if enemy_group != "" and not target.is_in_group(enemy_group):
		return false
	if _hit_once and _hit_cache.has(target.get_instance_id()):
		return false
	return true

func _mark_hit(target: Node) -> void:
	_hit_cache[target.get_instance_id()] = true

func _apply_hit(target: Node) -> void:
	if not _should_hit(target):
		return
	_mark_hit(target)

	if target.has_method("apply_damage"):
		target.apply_damage(damage, _facing * knockback, global_position)
	elif target is Node2D and target.has_node("Health"):
		var h = target.get_node("Health")
		if h and h.has_method("apply_damage"):
			h.apply_damage(damage, _facing * knockback, global_position)
