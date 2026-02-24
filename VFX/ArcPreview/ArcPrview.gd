extends Node2D
class_name ArcPreview

@export_group("Dots")
@export var dot_texture: Texture2D
@export var dot_step_points: int = 1
@export var dot_scale: float = 0.25
@export var dot_z_index: int = 999

@export_group("Marker")
@export var marker_tex_16: Texture2D
@export var marker_tex_48: Texture2D
@export var marker_z_index: int = 999

@export_group("Arc Sampling")
@export var sample_points: int = 48
@export var time_step: float = 0.04

@export_group("Limits")
@export var max_distance_x: float = 200.0
@export var freeze_on_limit: bool = true

@export_group("Ground")
@export var ground_mask: int = 0
@export var ground_snap_up: float = 8.0
@export var ground_snap_down: float = 220.0

@export_group("Debug")
@export var watchdog_force_visible: bool = true
@export var watchdog_print: bool = false

@onready var dots_root: Node2D = $Dots
@onready var marker: Sprite2D = $Marker

var _pool: Array[Sprite2D] = []
var _used: int = 0
var _active: bool = false

# freeze state
var _frozen: bool = false
var _frozen_key_start: Vector2 = Vector2.ZERO
var _frozen_key_lane: float = 0.0
var _frozen_key_dir_sign: int = 1


func _ready() -> void:
	# важно: превью не должно зависеть от pause/таймскейла/чисток vfx-групп
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)


func _process(_delta: float) -> void:
	# WATCHDOG: если активно — держим видимость любой ценой
	if not watchdog_force_visible:
		return
	if not _active:
		return
	if not visible:
		visible = true
		if watchdog_print:
			print("[ArcPreview] forced visible=true")
	if marker != null and not marker.visible:
		marker.visible = true
		if watchdog_print:
			print("[ArcPreview] forced marker.visible=true")
	# точки держим видимыми только те, что "used"
	for i in range(_used):
		if i < _pool.size() and _pool[i] != null and not _pool[i].visible:
			_pool[i].visible = true


func show_preview() -> void:
	_active = true
	visible = true


func hide_preview() -> void:
	_active = false
	visible = false
	_frozen = false
	_clear_used()


func set_marker_size_px(px: int) -> void:
	if marker == null:
		return
	if px <= 16:
		if marker_tex_16 != null:
			marker.texture = marker_tex_16
	else:
		if marker_tex_48 != null:
			marker.texture = marker_tex_48


func update_arc(start_visual: Vector2, aim_dir: Vector2, speed: float, upward_boost: float, gravity_force: float, lane_depth_y: float) -> void:
	if not _active:
		return
	if dot_texture == null:
		return

	var dir_sign_i: int = -1 if aim_dir.x < 0.0 else 1

	# freeze: если достигли лимита — держим картинку
	if freeze_on_limit and _frozen:
		if start_visual != _frozen_key_start:
			_frozen = false
		elif lane_depth_y != _frozen_key_lane:
			_frozen = false
		elif dir_sign_i != _frozen_key_dir_sign:
			_frozen = false
		else:
			return

	var start_phys: Vector2 = start_visual - Vector2(0.0, lane_depth_y)
	var v0: Vector2 = Vector2(float(dir_sign_i) * speed, -upward_boost)
	var g: Vector2 = Vector2(0.0, gravity_force)

	var space: PhysicsDirectSpaceState2D = null
	if get_world_2d() != null:
		space = get_world_2d().direct_space_state

	_used = 0

	var prev_phys: Vector2 = start_phys
	var prev_draw: Vector2 = _pix(prev_phys + Vector2(0.0, lane_depth_y))
	_place_dot(prev_draw)

	var t_limit: float = -1.0
	if max_distance_x > 0.0 and abs(v0.x) > 0.001:
		t_limit = max_distance_x / abs(v0.x)

	var t: float = 0.0
	var n: int = int(max(2, sample_points))

	for i in range(1, n):
		t += time_step

		# лимит дальности
		if t_limit > 0.0 and t >= t_limit:
			var p_limit_phys: Vector2 = start_phys + v0 * t_limit + 0.5 * g * t_limit * t_limit
			var end_draw: Vector2 = _snap_to_ground(space, p_limit_phys, lane_depth_y)

			_place_dot(end_draw)
			_finish(end_draw)

			if freeze_on_limit:
				_frozen = true
				_frozen_key_start = start_visual
				_frozen_key_lane = lane_depth_y
				_frozen_key_dir_sign = dir_sign_i

			return

		var p_phys: Vector2 = start_phys + v0 * t + 0.5 * g * t * t

		# попадание в землю по сегменту
		if space != null and ground_mask != 0:
			var hit: Dictionary = _ray_hit(space, prev_phys, p_phys)
			if hit.size() > 0:
				var hit_phys: Vector2 = hit["position"]
				var hit_draw: Vector2 = _pix(hit_phys + Vector2(0.0, lane_depth_y))
				_place_dot(hit_draw)
				_finish(hit_draw)
				return

		var p_draw: Vector2 = _pix(p_phys + Vector2(0.0, lane_depth_y))
		if (i % max(1, dot_step_points)) == 0:
			_place_dot(p_draw)

		prev_phys = p_phys
		prev_draw = p_draw

	_finish(prev_draw)


func _snap_to_ground(space: PhysicsDirectSpaceState2D, phys_pos: Vector2, lane_depth_y: float) -> Vector2:
	if space != null and ground_mask != 0:
		var from_pt: Vector2 = phys_pos + Vector2(0.0, -ground_snap_up)
		var to_pt: Vector2 = phys_pos + Vector2(0.0, ground_snap_down)
		var hit: Dictionary = _ray_hit(space, from_pt, to_pt)
		if hit.size() > 0:
			var hp: Vector2 = hit["position"]
			return _pix(hp + Vector2(0.0, lane_depth_y))

	return _pix(phys_pos + Vector2(0.0, lane_depth_y))


func _finish(pos_draw: Vector2) -> void:
	if marker != null:
		marker.global_position = pos_draw
		marker.z_index = marker_z_index
	_clear_unused_from(_used)


func _place_dot(pos: Vector2) -> void:
	var s: Sprite2D = _get_dot()
	s.texture = dot_texture
	s.centered = true
	s.global_position = pos
	s.z_index = dot_z_index
	s.scale = Vector2(dot_scale, dot_scale)
	s.visible = true
	_used += 1


func _get_dot() -> Sprite2D:
	if _used < _pool.size():
		return _pool[_used]
	var s := Sprite2D.new()
	dots_root.add_child(s)
	_pool.append(s)
	return s


func _clear_used() -> void:
	_clear_unused_from(0)


func _clear_unused_from(from_index: int) -> void:
	for i in range(from_index, _pool.size()):
		_pool[i].visible = false


func _pix(v: Vector2) -> Vector2:
	return Vector2(round(v.x), round(v.y))


func _ray_hit(space: PhysicsDirectSpaceState2D, from_pt: Vector2, to_pt: Vector2) -> Dictionary:
	var params := PhysicsRayQueryParameters2D.create(from_pt, to_pt)
	params.collision_mask = ground_mask
	params.collide_with_bodies = true
	params.collide_with_areas = false
	params.hit_from_inside = true
	return space.intersect_ray(params)

func _exit_tree() -> void:
	print("[ArcPreview] EXIT_TREE (was active=", _active, ") parent=", get_parent())
