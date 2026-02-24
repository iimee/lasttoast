extends Area2D
# MolotovFly.gd — Godot 4.6
# Полёт коктейля: парабола (дуга). При попадании → взрыв + лужа огня (только на земле).
#
# LANE FIX:
# - lane в проекте визуальный → смещаем ТОЛЬКО AnimatedSprite2D по depth_y
# - FX (взрыв/огонь) спавним на той же визуальной линии (global_y + depth_y)
#
# FIXES:
# 1) Движение начинается ТОЛЬКО после setup() (или start_on_ready) — чтобы spawn не "съезжал" на первом кадре.
# 2) Пропуск первого физ-тика после setup — убирает микросдвиг сразу после спавна.
# 3) Ротация по вектору полёта предпочтительно крутит спрайт (иначе смещение по Y вращается "по орбите").

@export_group("Flight")
@export var start_on_ready: bool = false
@export var speed: float = 200.0
@export var upward_boost: float = 200.0      # чем больше — тем выше дуга
@export var gravity_force: float = 800.0     # чем больше — тем круче падение
@export var rotate_with_flight: bool = true
@export var lifetime: float = 2.0
@export var spawn_grace: float = 0.12        # секунды иммунитета к коллизии (чтобы не ловить себя/спавн)

@export_group("Hit")
@export var enemy_group: String = "Enemy"
@export var damage_direct: int = 1
@export var knockback: float = 160.0

@export_group("FX Scenes")
@export var explosion_scene: PackedScene     # res://VFX/Explosion.tscn
@export var fire_scene: PackedScene          # res://VFX/FireArea.tscn

@export_group("Ground Snap")
@export var ground_collision_mask: int = 1           # маска «мира/пола». Поставь сюда слой мира.
@export var ground_search_up: float = 12.0           # от точки удара сначала чуть вверх (чтобы не быть внутри тайла)
@export var ground_search_down: float = 200.0        # насколько вниз ищем пол
@export var fire_lift_along_normal: float = 1.5      # слегка поднимаем над полом по нормали

@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var direction: Vector2 = Vector2.RIGHT
var velocity: Vector2 = Vector2.ZERO

var _armed: bool = false
var _skip_first_tick: bool = true

var _alive_time: float = 0.0
var _hit_cache: Dictionary = {}
var _destroying: bool = false
var _exploded: bool = false

# ===== lane (visual only) =====
var lane_index: int = -1
var _anim_base_y: float = 0.0
var depth_y: float = 0.0


func setup(dir: Vector2, spd: float) -> void:
	direction = dir.normalized()
	speed = spd

	# Дуга: X — по направлению, Y — вверх
	var dir_sign: float = -1.0 if direction.x < 0.0 else 1.0
	velocity = Vector2(dir_sign * speed, -upward_boost)

	if anim:
		anim.flip_h = (dir_sign < 0.0)

	# FIX: разрешаем движение только после setup()
	_arm_motion()


func _ready() -> void:
	# lane visual base
	if anim:
		_anim_base_y = anim.position.y
	_apply_lane_visual()

	monitoring = true
	monitorable = true
	add_to_group("attack")

	# FIX: до setup() прожектайл НЕ двигается
	set_physics_process(false)

	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("bottlefly"):
		anim.sprite_frames.set_animation_loop("bottlefly", true)
		anim.play("bottlefly")

	# lifetime
	if is_instance_valid(lifetime_timer):
		lifetime_timer.stop()
		lifetime_timer.one_shot = true
		lifetime_timer.wait_time = lifetime
		if not lifetime_timer.timeout.is_connected(_on_lifetime_timeout):
			lifetime_timer.timeout.connect(_on_lifetime_timeout)
		lifetime_timer.start()

	# collisions
	if not body_entered.is_connected(_on_any_entered):
		body_entered.connect(_on_any_entered)
	if not area_entered.is_connected(_on_any_entered):
		area_entered.connect(_on_any_entered)

	# если хотят запуск без setup()
	if start_on_ready:
		setup(direction, speed)


# ===== lane API (Player spawner expects set_lane_index if present) =====
func set_lane(lane: int) -> void:
	lane_index = lane
	depth_y = LaneSystem.center_from_lane(lane_index)
	_apply_lane_visual()

func set_lane_index(i: int) -> void:
	set_lane(i)

func _apply_lane_visual() -> void:
	if anim:
		anim.position.y = _anim_base_y + depth_y


func _arm_motion() -> void:
	_armed = true
	_skip_first_tick = true
	_alive_time = 0.0
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if _destroying or not _armed:
		return

	# FIX: пропускаем первый тик после setup(), чтобы не было микросдвига сразу после спавна
	if _skip_first_tick:
		_skip_first_tick = false
		return

	_alive_time += delta

	velocity.y += gravity_force * delta
	position += velocity * delta

	if rotate_with_flight:
		# ВАЖНО: если спрайт смещён по lane, лучше крутить спрайт, а не корень
		if anim:
			anim.rotation = velocity.angle()
		else:
			rotation = velocity.angle()


func _on_any_entered(other: Node) -> void:
	_handle_collision(other)


func _handle_collision(hit: Node) -> void:
	if _destroying or hit == null:
		return

	# сначала — урон по врагу
	var target: Node = _resolve_enemy(hit)
	if target != null and is_instance_valid(target):
		var id: int = target.get_instance_id()
		if not _hit_cache.has(id):
			_hit_cache[id] = true
			if target.has_method("apply_damage"):
				var dir_vec: Vector2 = velocity.normalized() if velocity.length() > 0.0 else Vector2.RIGHT
				target.call("apply_damage", damage_direct, dir_vec * knockback, global_position)
		_explode_and_die()
		return

	# защита от самоколлизии/спавна
	if _alive_time < spawn_grace:
		return

	# любое другое касание (мир/объекты) — взрыв
	_explode_and_die()


func _resolve_enemy(start: Node) -> Node:
	var n: Node = start
	for i in range(3):
		if n == null or not is_instance_valid(n):
			return null
		if n.is_in_group(enemy_group) or n.has_method("apply_damage"):
			return n
		n = n.get_parent()
	return null


func _explode_and_die() -> void:
	if _exploded:
		return
	_exploded = true

	var parent: Node = _resolve_vfx_parent()

	# визуальная позиция на lane: физический X/Y + depth_y
	var vpos: Vector2 = global_position
	vpos.y += depth_y

	# --- ВЗРЫВ (сразу, сверху) ---
	if explosion_scene != null:
		var boom: Node = explosion_scene.instantiate()
		if boom is Node2D:
			var b2d: Node2D = boom as Node2D
			b2d.global_position = vpos
			b2d.z_index = 1000
		parent.add_child(boom)

	# --- ОГОНЬ (только если нашли пол под точкой удара) ---
	# Поиск пола делаем по ФИЗИКЕ (без depth_y), иначе луч будет искать "не там".
	if fire_scene != null:
		var hit: Dictionary = _find_ground_hit(global_position)
		if hit.size() > 0:
			var fire: Node = fire_scene.instantiate()

			# позицию огня смещаем по lane визуально
			var hit_pos: Vector2 = hit["position"]
			var normal: Vector2 = hit["normal"]
			hit_pos.y += depth_y

			if fire is Node2D:
				var f2d: Node2D = fire as Node2D
				f2d.global_position = hit_pos + normal * fire_lift_along_normal
				f2d.rotation = normal.angle() + PI / 2.0
				f2d.z_index = 0

			# если у огня есть API для surface — даём ФИЗИКУ или ВИЗУАЛ?
			# обычно surface/коллизии — физика, а визуал — отдельный
			if fire.has_method("place_on_surface"):
				fire.call("place_on_surface", hit["position"], hit["normal"])

			# проброс lane, если огонь тоже lane-aware
			if fire is Object:
				var fo := fire as Object
				if fo.has_method("set_lane_index"):
					fo.call("set_lane_index", lane_index)
				elif fo.has_method("set_lane"):
					fo.call("set_lane", lane_index)
				elif fo.get("lane_index") != null:
					fo.set("lane_index", lane_index)

			parent.add_child(fire)
		# если пола нет — огонь не спавним

	_destroy_self_deferred()


func _resolve_vfx_parent() -> Node:
	var vfx_groups: Array = get_tree().get_nodes_in_group("vfx_layer")
	if vfx_groups.size() > 0:
		return vfx_groups[0] as Node
	if get_tree().current_scene and get_tree().current_scene.has_node("VFX"):
		return get_tree().current_scene.get_node("VFX")
	if get_tree().current_scene:
		return get_tree().current_scene
	if get_parent() != null:
		return get_parent()
	return get_tree().root


func _find_ground_hit(origin: Vector2) -> Dictionary:
	# Луч: чуть вверх от удара → вниз. Ищем только по телам, по заданной маске.
	var from_pt: Vector2 = origin + Vector2(0, -ground_search_up)
	var to_pt: Vector2 = origin + Vector2(0, ground_search_down)

	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var params := PhysicsRayQueryParameters2D.create(from_pt, to_pt)
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.hit_from_inside = true
	params.collision_mask = ground_collision_mask
	params.exclude = [self]

	return space.intersect_ray(params)


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
		_explode_and_die()
