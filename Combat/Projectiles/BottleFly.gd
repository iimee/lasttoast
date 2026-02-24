extends Area2D

const FEEDBACK_SCENE: PackedScene = preload("res://Pickups/Feedback/feedback.tscn")

@export var start_on_ready: bool = false
@export var speed: float = 260.0
@export var upward_boost: float = 280.0
@export var gravity_force: float = 800.0
@export var damage: int = 1
@export var knockback: float = 150.0
@export var lifetime: float = 2.0
@export var enemy_group: String = "Enemy"
@export var spawn_grace: float = 0.12
@export var rotate_with_flight: bool = true

@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


var active: bool = false
var direction: Vector2 = Vector2.RIGHT
var velocity: Vector2 = Vector2.ZERO
var _alive_time: float = 0.0
var _hit_cache: Dictionary = {}
var _destroying: bool = false
var _fx_spawned: bool = false

var _skip_first_tick: bool = false
var lane_index: int = -1

var _anim_base_y: float = 0.0
var depth_y: float = 0.0 # визуальная глубина (lane offset)

func setup(dir: Vector2, spd: float) -> void:
	direction = dir.normalized()
	speed = spd

	var dir_sign: float = -1.0 if direction.x < 0.0 else 1.0
	velocity = Vector2(dir_sign * speed, -upward_boost)

	if anim:
		anim.flip_h = (dir_sign < 0.0)

	active = true
	_alive_time = 0.0

	_skip_first_tick = true
	set_physics_process(true)


func _ready() -> void:
	
	if anim:
		_anim_base_y = anim.position.y
	_apply_lane_visual()
	
	# НЕ наследуем трансформы родителя (убирает странные “центр/сдвиги”, если у родителя есть оффсет/скейл)
	var keep_gp: Vector2 = global_position
	top_level = true
	global_position = keep_gp

	monitoring = true
	monitorable = true
	add_to_group("attack")

	# ЛЕЧИМ УРОН: прожектайл должен видеть ENEMY по слоям.
	# Layers.gd у тебя class_name Layers, значит доступен как Layers.ENEMY и т.д.
	collision_layer = Layers.P_ATTACK
	collision_mask = Layers.ENEMY | Layers.WORLD | Layers.TRIGGER | Layers.HAZARD

	# анимация полёта
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("bottlefly"):
		anim.sprite_frames.set_animation_loop("bottlefly", true)
		anim.play("bottlefly")

	# сигналы столкновений
	if not body_entered.is_connected(_on_any_entered):
		body_entered.connect(_on_any_entered)
	if not area_entered.is_connected(_on_any_entered):
		area_entered.connect(_on_any_entered)

	# таймер жизни
	if is_instance_valid(lifetime_timer):
		lifetime_timer.stop()
		lifetime_timer.wait_time = lifetime
		if not lifetime_timer.timeout.is_connected(_on_lifetime_timeout):
			lifetime_timer.timeout.connect(_on_lifetime_timeout)
		lifetime_timer.start()

	# автостарт (редко)
	if start_on_ready:
		setup(direction, speed)
	else:
		set_physics_process(false)

func set_lane(lane: int) -> void:
	lane_index = lane
	depth_y = LaneSystem.center_from_lane(lane_index)
	_apply_lane_visual()
	
func set_lane_index(i: int) -> void:
	set_lane(i)

func set_depth_y(v: float) -> void:
	depth_y = v
	_apply_lane_visual()

func _apply_lane_visual() -> void:
	if anim:
		anim.position.y = _anim_base_y + depth_y

func _physics_process(delta: float) -> void:
	if _destroying or not active:
		return

	if _skip_first_tick:
		_skip_first_tick = false
		return

	_alive_time += delta
	velocity.y += gravity_force * delta
	global_position += velocity * delta

	if rotate_with_flight and anim:
		rotation = velocity.angle()


func _on_any_entered(other: Node) -> void:
	_handle_collision(other)
	
	
func _get_target_lane(target: Node) -> int:
	if target == null:
		return -1

	# 1) target.lane_body.lane_index
	if target is Object:
		var to := target as Object
		# lane_body как свойство
		var lb = to.get("lane_body")
		if lb != null and lb is Object:
			var lbo := lb as Object
			# lane_index как свойство у LaneBody
			var li = lbo.get("lane_index")
			if typeof(li) == TYPE_INT:
				return int(li)

		# 2) target.lane_index
		var li2 = to.get("lane_index")
		if typeof(li2) == TYPE_INT:
			return int(li2)

	return -1

func _handle_collision(hit: Node) -> void:
	if _destroying or hit == null:
		return

	var target: Node = _resolve_enemy(hit)

	if target != null and is_instance_valid(target):
		# анти-дабл-хит по одному врагу
		var id: int = target.get_instance_id()
		if _hit_cache.has(id):
			return
		_hit_cache[id] = true

		# ===== lane filter =====
		var t_lane: int = _get_target_lane(target)
		if lane_index != -1 and t_lane != -1 and t_lane != lane_index:
			# не наша линия — игнор
			return

		# ===== damage =====
		if target.has_method("apply_damage"):
			var dir_vec: Vector2 = velocity.normalized() if velocity.length() > 0.0 else Vector2.RIGHT
			target.call("apply_damage", damage, dir_vec * knockback, global_position)

		_spawn_feedback_once()
		_destroy_self_deferred()
		return

	# первые миллисекунды игнорим не-врагов (пол/игрок и т.п.)
	if _alive_time < spawn_grace:
		return

	_spawn_feedback_once()
	_destroy_self_deferred()


func _resolve_enemy(start: Node) -> Node:
	var n: Node = start
	for i in range(3):
		if n == null or not is_instance_valid(n):
			return null
		if n.is_in_group(enemy_group) or n.has_method("apply_damage"):
			return n
		n = n.get_parent()
	return null


func _spawn_feedback_once() -> void:
	if _fx_spawned:
		return
	_fx_spawned = true
	if FEEDBACK_SCENE == null:
		return

	var fx: Node = FEEDBACK_SCENE.instantiate()

	var parent: Node = null
	var vfx_groups: Array = get_tree().get_nodes_in_group("vfx_layer")
	if vfx_groups.size() > 0:
		parent = vfx_groups[0] as Node
	elif get_tree().current_scene and get_tree().current_scene.has_node("VFX"):
		parent = get_tree().current_scene.get_node("VFX")
	elif get_tree().current_scene:
		parent = get_tree().current_scene
	elif get_parent() != null:
		parent = get_parent()
	else:
		parent = get_tree().root

	parent.add_child(fx)

	if fx is Node2D:
		var spawn_pos := global_position
		spawn_pos.y += depth_y
		(fx as Node2D).global_position = spawn_pos


func _destroy_self_deferred() -> void:
	if _destroying:
		return
	_destroying = true

	monitoring = false
	monitorable = false
	set_physics_process(false)

	if is_instance_valid(lifetime_timer):
		lifetime_timer.stop()

	if body_entered.is_connected(_on_any_entered):
		body_entered.disconnect(_on_any_entered)
	if area_entered.is_connected(_on_any_entered):
		area_entered.disconnect(_on_any_entered)

	call_deferred("queue_free")


func _on_lifetime_timeout() -> void:
	if not _destroying:
		_spawn_feedback_once()
		_destroy_self_deferred()
