extends Skill
class_name BottleThrowSkill

const ItemDB = preload("res://db/ItemDB.gd")

@export var projectile: PackedScene
@export var speed: float = 200.0
@export var offset_right: Vector2 = Vector2(14, -8)
@export var offset_left:  Vector2 = Vector2(-14, -8)

# charge
@export var action_name: StringName = &"skill_1"
@export var max_charge_time: float = 0.8
@export var min_speed_mul: float = 0.6
@export var max_speed_mul: float = 1.6

# preview physics (должны совпадать с BottleFly)
@export var preview_upward_boost: float = 200.0
@export var preview_gravity_force: float = 800.0

# marker style
@export var marker_size_px: int = 16

# emit timing
@export var emit_on_4th_frame: bool = true
@export var frame_index_to_emit: int = 3
@export var fallback_delay_sec: float = 0.5

# safety
@export var hold_after_max_timeout: float = 3.0 # чтобы не зависнуть навсегда, если input залип

var _charging: bool = false


func can_use(user: Node) -> bool:
	if user == null or projectile == null:
		return false

	var inv: Node = user.get_tree().root.get_node_or_null("Inventory")
	if inv == null:
		push_warning("[BottleThrowSkill] /root/Inventory not found")
		return false

	var empty_cnt: int = int(inv.call("get_count", ItemDB.EMPTY_BOTTLE))
	var full_cnt: int  = int(inv.call("get_count", ItemDB.FULL_BOTTLE))
	return (empty_cnt + full_cnt) > 0


func execute(user: Node) -> void:
	if user == null or projectile == null:
		return
	if _charging:
		return
	if not can_use(user):
		return

	var u: Node2D = user as Node2D
	if u == null:
		return

	_charging = true

	# aim dir
	var aim_dir: Vector2 = Vector2.RIGHT
	if user.has_method("skills_get_aim_dir"):
		aim_dir = user.call("skills_get_aim_dir")
	if aim_dir.length() <= 0.001:
		aim_dir = Vector2.RIGHT

	var is_right: bool = (aim_dir.x >= 0.0)
	var spawn_offset: Vector2 = offset_right if is_right else offset_left

	var origin: Vector2 = _origin(user, u)
	var lane_depth_y: float = _get_user_lane_depth_y(user)

	var arc: ArcPreview = null
	if user.has_method("skills_get_arc_preview"):
		arc = user.call("skills_get_arc_preview") as ArcPreview
	if arc != null and is_instance_valid(arc):
		arc.set_marker_size_px(marker_size_px)
		arc.show_preview()

	# ========= CHARGE LOOP =========
	var charge_t: float = 0.0
	var dt: float = _fixed_dt()

	while Input.is_action_pressed(action_name) and charge_t < max_charge_time:
		charge_t += dt
		var k: float = clampf(charge_t / max_charge_time, 0.0, 1.0)
		var spd_mul: float = lerpf(min_speed_mul, max_speed_mul, k)
		var spd_now: float = speed * spd_mul

		if arc != null and is_instance_valid(arc):
			arc.update_arc(origin + spawn_offset, aim_dir, spd_now, preview_upward_boost, preview_gravity_force, lane_depth_y)

		await user.get_tree().process_frame

	var k_final: float = clampf(charge_t / max_charge_time, 0.0, 1.0)
	var final_speed: float = speed * lerpf(min_speed_mul, max_speed_mul, k_final)

	# ========= HOLD AFTER MAX (PREVIEW STAYS) =========
	# Если кнопку продолжают держать после max_charge_time — держим превью, но:
	# - обновляем редко (раз в несколько кадров)
	# - ставим таймаут, чтобы не “залипнуть” навсегда
	var hold_time: float = 0.0
	var frame_skip: int = 0

	while Input.is_action_pressed(action_name):
		hold_time += dt
		if hold_after_max_timeout > 0.0 and hold_time >= hold_after_max_timeout:
			break

		# обновляем превью не каждый кадр, чтобы не нагружать
		frame_skip += 1
		if frame_skip >= 6:
			frame_skip = 0
			if arc != null and is_instance_valid(arc):
				arc.update_arc(origin + spawn_offset, aim_dir, final_speed, preview_upward_boost, preview_gravity_force, lane_depth_y)

		await user.get_tree().process_frame

	# теперь отпустили (или таймаут) — прячем превью
	if arc != null and is_instance_valid(arc):
		arc.hide_preview()

	# если отпустили НЕ по своей воле (таймаут) — просто отменяем
	if hold_after_max_timeout > 0.0 and hold_time >= hold_after_max_timeout:
		_charging = false
		return

	# ========= SPEND =========
	if not _spend_one_bottle(user):
		_charging = false
		return

	# анимация
	if user.has_method("play_cast_anim"):
		user.call("play_cast_anim", "throw")

	# тайминг выпуска
	if emit_on_4th_frame:
		var delay_sec: float = _compute_throw_delay_on_frame(user, "throw", frame_index_to_emit)
		await user.get_tree().create_timer(delay_sec).timeout
	else:
		await user.get_tree().create_timer(fallback_delay_sec).timeout

	# spawn projectile
	var dir_for_projectile: Vector2 = aim_dir.normalized()
	user.call("skills_spawn_projectile", projectile, origin + spawn_offset, dir_for_projectile, final_speed)

	_charging = false


func _origin(user: Node, u: Node2D) -> Vector2:
	if user.has_method("skills_get_origin_global"):
		var v = user.call("skills_get_origin_global")
		if v is Vector2:
			return v as Vector2
	return u.global_position


func _get_user_lane_depth_y(user: Node) -> float:
	if user == null:
		return 0.0

	if user is Object:
		var uo := user as Object
		var lb = uo.get("lane_body")
		if lb != null and lb is Object:
			var lbo := lb as Object
			var dy = lbo.get("depth_y")
			if typeof(dy) == TYPE_FLOAT or typeof(dy) == TYPE_INT:
				return float(dy)

	return 0.0


func _spend_one_bottle(user: Node) -> bool:
	var inv: Node = user.get_tree().root.get_node_or_null("Inventory")
	if inv == null:
		return false

	var spend_id: String = ""
	var empty_cnt: int = int(inv.call("get_count", ItemDB.EMPTY_BOTTLE))
	if empty_cnt > 0:
		spend_id = ItemDB.EMPTY_BOTTLE
	else:
		var full_cnt: int = int(inv.call("get_count", ItemDB.FULL_BOTTLE))
		if full_cnt > 0:
			spend_id = ItemDB.FULL_BOTTLE
		else:
			return false

	return bool(inv.call("take", spend_id, 1))


func _compute_throw_delay_on_frame(user: Node, anim_name: String, frame_index: int) -> float:
	var as2d: AnimatedSprite2D = user.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if as2d == null or as2d.sprite_frames == null:
		return fallback_delay_sec
	if not as2d.sprite_frames.has_animation(anim_name):
		return fallback_delay_sec

	var fps: float = float(as2d.sprite_frames.get_animation_speed(anim_name))
	if fps <= 0.0:
		return fallback_delay_sec

	var idx: int = max(0, frame_index)
	return float(idx) / fps


func _fixed_dt() -> float:
	var tps_variant = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")
	var tps: float = float(tps_variant)
	if tps <= 0.0:
		tps = 60.0
	return 1.0 / tps
