extends Area2D
# Огненное дыхание: проигрывает клип, дамажит и самоуничтожается.

@export var damage: int = 1
@export var knockback: float = 140.0
@export var enemy_group: String = "Enemy"
@export var ignore_groups: Array[String] = ["Player"]
@export var animation_name: StringName = "default"

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var _facing: Vector2 = Vector2.RIGHT
var _hit_once: bool = true
var _hit_cache: Dictionary = {}
var _dead: bool = false

var facing: Vector2:
	set(value):
		_facing = value
		_apply_facing()
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

	# гарантируем незацикленный клип
	if anim and anim.sprite_frames:
		if not anim.sprite_frames.has_animation(String(animation_name)):
			var names := anim.sprite_frames.get_animation_names()
			if names.size() > 0:
				animation_name = StringName(names[0])
		anim.sprite_frames.set_animation_loop(String(animation_name), false)

	_apply_facing()

	if anim:
		# подключаемся ДО play на всякий
		anim.animation_finished.connect(_on_anim_finished)
		anim.play(String(animation_name))
		_start_autokill_failsafe()  # на случай, если сигнал не придёт

	area_entered.connect(_on_area)
	body_entered.connect(_on_body)

func _apply_facing() -> void:
	if anim == null:
		return
	anim.flip_h = (_facing.x < 0.0)

func _start_autokill_failsafe() -> void:
	# Авто-удаление по длительности клипа (если animation_finished вдруг не стрельнет)
	if anim == null or anim.sprite_frames == null:
		return
	var frames := anim.sprite_frames
	var name := String(animation_name)
	var count := frames.get_frame_count(name)
	var fps := frames.get_animation_speed(name)
	if fps <= 0.0:
		fps = 12.0
	var dur := float(count) / fps
	var t := get_tree().create_timer(dur + 0.05)
	t.timeout.connect(_on_anim_finished)

func _on_anim_finished() -> void:
	if _dead:
		return
	_dead = true
	queue_free()

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
		var h: Node = target.get_node("Health")
		if h and h.has_method("apply_damage"):
			h.apply_damage(damage, _facing * knockback, global_position)
