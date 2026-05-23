# player.gd — Godot 4.6
extends CharacterBody2D

const PLAYER_SKILLS_RUNTIME_SCRIPT = preload("res://Player/player_skills_runtime.gd")
const PLAYER_FEEDBACK_RUNTIME_SCRIPT = preload("res://Player/player_feedback_runtime.gd")
const PLAYER_HP_POOL_RUNTIME_SCRIPT = preload("res://Player/player_hp_pool_runtime.gd")

# =========================
#         SKILLS
# =========================
signal skills_changed
signal skill_used(slot:int, cd:float)
signal skill_ready(slot:int)

const SKILLS_SLOT_COUNT: int = 4

const SKILLS_DB_PATHS: Array[String] = ["/root/SkillsDB", "/root/db/SkillsDB"]

var skills_slots: Dictionary = {}       # slot:int(1..N) -> Skill
var skills_cooldowns: Dictionary = {}   # slot:int -> float
# Runtime helpers extracted from the player monolith.
var _skills_runtime: RefCounted = PLAYER_SKILLS_RUNTIME_SCRIPT.new()
var _feedback_runtime: RefCounted = PLAYER_FEEDBACK_RUNTIME_SCRIPT.new()
var _hp_pool_runtime: RefCounted = PLAYER_HP_POOL_RUNTIME_SCRIPT.new()

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var shadow: Sprite2D = $Shadow
@onready var human_collision_shape2d: CollisionShape2D = $HumanCollisionShape2D

@export var arc_dot_texture: Texture2D
@export var arc_marker_16: Texture2D
@export var arc_marker_48: Texture2D

var _arc_preview: ArcPreview = null
@export var fire_hurt_anim_name: StringName = &"fire"
@export var fire_hurt_duration: float = 2.0

# -------------------------
# Animation helpers (FIX)
# -------------------------
func _has_anim(name: StringName) -> bool:
	return animated_sprite_2d \
	and animated_sprite_2d.sprite_frames \
	and animated_sprite_2d.sprite_frames.has_animation(name)

func _set_anim_loop(name: StringName, loop: bool) -> void:
	if not (animated_sprite_2d and animated_sprite_2d.sprite_frames):
		return
	if animated_sprite_2d.sprite_frames.has_animation(name):
		animated_sprite_2d.sprite_frames.set_animation_loop(name, loop)

# FIX: список одноразовых анимаций (и для проверки завершений)
var _one_shot_anims: Array[StringName] = []

func _force_non_loop_one_shots() -> void:
	# Все “одноразовые” клипы обязаны быть non-loop, иначе они никогда не закончатся -> залипание.
	_one_shot_anims = [
		&"damage",
		&"fire",
		&"vomit", &"vomit_hit",
		&"use_bottle",
		&"use_cig",
		&"attack", &"attack2", &"attack3",
		&"jump_up", &"land",
		&"dead",
		&"berserk",
		# FIX: если у тебя есть отдельная анимация дэша и она one-shot — добавь сюда
		&"dash",
		&"dodge",
	]
	for a in _one_shot_anims:
		_set_anim_loop(a, false)

func _return_to_motion_anim() -> void:
	# Универсальный возврат после лока/хёрта/каста
	if not animated_sprite_2d:
		return

	# не ломаем air state — он сам решает (jump_up/fall/land)
	if _air_state == AirState.ASCEND or _air_state == AirState.FALL or _air_state == AirState.LAND:
		return

	if _land_lock and is_on_floor():
		return

	var axis := Input.get_axis("ui_left", "ui_right")
	update_animations(axis)

# FIX: жёсткий “антизалип” — снимаем локи, если их анимация была перебита
func _animation_watchdog() -> void:
	if not animated_sprite_2d:
		return

	var cur: StringName = StringName(animated_sprite_2d.animation)

	# каст залипает, если анимацию каста перебили другой
	if is_casting and _casting_anim != StringName():
		if cur != _casting_anim:
			is_casting = false
			_casting_anim = StringName()

	# use_bottle/use_cig: если их перебили — снимаем лок
	if is_using_bottle:
		if cur != &"use_bottle" and cur != &"use_cig":
			is_using_bottle = false

	# атака: если перебили не-атакой — снимаем атак-лок и комбо-флаги
	if is_attacking:
		if not melee_anim_names.has(cur):
			is_attacking = false
			_attack_performed = false
			_combo_can_chain = false
			_combo_queued = false
			_combo_press_buffered = false
			_melee_step_damage_mult = 1.0
			_active_melee_anim = StringName()
			_melee_finish_token += 1
			_clear_melee_micro_step()

	# anti-freeze: если action-локов нет, а спрайт остановлен/заморожен,
	# принудительно возвращаем обычную анимацию движения.
	var blocked_by_state: bool = false
	match _get_action_state():
		ActionState.DASH, ActionState.DODGE, ActionState.HURT, ActionState.CAST, ActionState.ATTACK, ActionState.ITEM, ActionState.LAND_LOCK, ActionState.FRENZY, ActionState.DEAD:
			blocked_by_state = true
		_:
			blocked_by_state = false
	var can_recover: bool = (not blocked_by_state) and _air_state == AirState.GROUND
	if can_recover:
		if animated_sprite_2d.speed_scale <= 0.0:
			animated_sprite_2d.speed_scale = 1.0
		if cur == &"dash" or cur == &"dodge" or cur == fire_hurt_anim_name or not animated_sprite_2d.is_playing():
			_return_to_motion_anim()

func _is_fire_damage_source(source: Variant) -> bool:
	if not (source is Object):
		return false
	var source_obj: Object = source as Object
	return source_obj.has_method("is_fire_damage_source") and bool(source_obj.call("is_fire_damage_source"))

func _get_hurt_anim_name(source: Variant) -> StringName:
	if _is_fire_damage_source(source) and _has_anim(fire_hurt_anim_name):
		return fire_hurt_anim_name
	return &"damage"

func _get_hurt_anim_wait_time(hurt_anim: StringName, speed_scale: float) -> float:
	if hurt_anim == fire_hurt_anim_name:
		return maxf(0.0, fire_hurt_duration)
	var dur := _anim_duration(hurt_anim, speed_scale)
	if dur <= 0.0:
		dur = 0.18
	return min(dur + 0.02, 0.35)

func _play_hurt_anim_for_duration(hurt_anim: StringName, total_duration: float, token: int) -> void:
	if not _has_anim(hurt_anim):
		return
	if _dead or token != _hurt_token or not animated_sprite_2d:
		return

	if hurt_anim != fire_hurt_anim_name:
		_set_anim_loop(hurt_anim, false)
		animated_sprite_2d.speed_scale = 1.0
		animated_sprite_2d.frame = 0
		animated_sprite_2d.play(String(hurt_anim))
		await get_tree().create_timer(total_duration).timeout
		return

	_set_anim_loop(hurt_anim, true)
	animated_sprite_2d.speed_scale = 1.0
	animated_sprite_2d.frame = 0
	animated_sprite_2d.play(String(hurt_anim))

	await get_tree().create_timer(total_duration).timeout

	if _dead or token != _hurt_token or not animated_sprite_2d:
		return

	_set_anim_loop(hurt_anim, false)
	animated_sprite_2d.speed_scale = 1.0
	_return_to_motion_anim()

func _update_hurt_facing(input_axis: float) -> void:
	if not animated_sprite_2d:
		return
	if absf(input_axis) > 0.001:
		animated_sprite_2d.flip_h = input_axis < 0.0
	elif last_move_direction != Vector2.ZERO:
		animated_sprite_2d.flip_h = (last_move_direction == Vector2.LEFT)

# Запуск каст-анимаций (например, throw) с локом
func play_cast_anim(name: String) -> void:
	var sn := StringName(name)
	if animated_sprite_2d \
	and animated_sprite_2d.sprite_frames \
	and animated_sprite_2d.sprite_frames.has_animation(sn):

		# FIX: касты обязаны быть non-loop, иначе animation_finished не придёт
		_set_anim_loop(sn, false)

		is_casting = true
		_casting_anim = sn
		animated_sprite_2d.speed_scale = 1.0
		animated_sprite_2d.frame = 0
		animated_sprite_2d.play(name)

		# фэйл-сейф на случай, если кто-то собьёт сигнал завершения
		var dur := _anim_duration(sn, 1.0)
		if dur <= 0.0:
			dur = 0.35
		_cast_safety_release(dur + 0.05)

func skills_get_aim_dir() -> Vector2:
	if "last_move_direction" in self and last_move_direction != Vector2.ZERO:
		return last_move_direction
	if has_node("AnimatedSprite2D") and $AnimatedSprite2D.flip_h:
		return Vector2.LEFT
	return Vector2.RIGHT

#PEW PEW PROJECTILES (LANE-AWARE)

func _obj_has_property(o: Object, prop: StringName) -> bool:
	if o == null:
		return false
	for d in o.get_property_list():
		if d.has("name") and StringName(d.name) == prop:
			return true
	return false


func skills_spawn_projectile(scene: PackedScene, pos: Vector2, dir: Vector2, speed: float) -> Node:
	if scene == null:
		return null

	var p: Node = scene.instantiate()

	# позиция (ещё до add_child можно)
	if p is Node2D:
		(p as Node2D).global_position = pos

	# ===== lane_index tag (СНАЧАЛА) =====
	if lane_body != null and p is Object:
		var po := p as Object
		var li: int = int(lane_body.lane_index)
		var dy: float = float(lane_body.depth_y)

		# ВАЖНО: если есть метод — он обычно обновляет визуал
		if po.has_method("set_lane_index"):
			po.call("set_lane_index", li)
		elif _obj_has_property(po, &"lane_index"):
			po.set("lane_index", li)

		# Pass exact current depth so combat can filter by visual offset instead of lane index.
		if po.has_method("set_depth_y"):
			po.call("set_depth_y", dy)
		elif _obj_has_property(po, &"depth_y"):
			po.set("depth_y", dy)

	# теперь добавляем в дерево (только теперь _ready)
	get_parent().add_child(p)

	# setup
	if p.has_method("setup"):
		p.call("setup", dir, speed)
	else:
		if p is Object:
			(p as Object).set("direction", dir)
			(p as Object).set("speed", speed)

	return p


# --- Хотбар ---
# -------------------------
# Skills Runtime Proxies
# -------------------------
func skills_clear_slots() -> void:
	_skills_runtime.clear_slots(self)

func skills_apply_loadout(list: Array) -> void:
	_skills_runtime.apply_loadout(self, list)

func skills_assign(slot:int, s) -> void:
	_skills_runtime.assign(self, slot, s)

var _skill_in_progress: Dictionary = {} # slot -> bool
var _queued_dash_slot: int = 0

func skills_use_slot(slot:int) -> void:
	_skills_runtime.use_slot(self, slot)

func _is_dash_slot(slot: int) -> bool:
	return _skills_runtime.is_dash_slot(self, slot)

func _is_dash_skill(s) -> bool:
	return _skills_runtime.is_dash_skill(self, s)

func _is_skill_with_keywords(s, keywords: PackedStringArray) -> bool:
	return _skills_runtime.is_skill_with_keywords(self, s, keywords)

func _get_dodge_skill_from_db() -> Skill:
	return _skills_runtime.get_dodge_skill_from_db(self)

func _try_use_dodge_action() -> void:
	_skills_runtime.try_use_dodge_action(self)

func _try_consume_queued_dash() -> void:
	_skills_runtime.try_consume_queued_dash(self)


func _skills_process(delta: float) -> void:
	_skills_runtime.process_cooldowns(self, delta)
				

# =========================
#    MOVEMENT / STATES
# =========================
const SPEED: float = 30.0
const JUMP_VELOCITY: float = -240.0
const KNOCKBACK_FORCE: float = 150.0
const SURFACE_SLOW_MIN: float = 0.1

# Слои
const LAYER_WORLD    := 1 << 0   # Layer 1 — уровень / пол / тайлы
const LAYER_PLAYER   := 1 << 1   # Layer 2 — игрок
const LAYER_TRIGGER  := 1 << 6   # Layer 7 — триггеры
const LAYER_HAZARD   := 1 << 7   # Layer 8 — хазарды/шипы

# Тень
@export var shadow_y_offset: float = 16.0
@export var shadow_min_scale: float = 0.55
@export var shadow_height_px: float = 40.0
var _shadow_base_scale: Vector2 = Vector2.ONE
var _shadow_ground_y: float = 0.0

# =========================
# --- ATTACK / MELEE (COMBO)
# =========================
@export var melee_offset: Vector2 = Vector2(18, -6)
@export var melee_cooldown: float = 0.45
@export var melee_micro_step_distance: float = 10.0
@export var melee_micro_step_duration: float = 0.07

# Комбо (attack -> attack2 -> attack3)
@export var combo_reset_time: float = 0.55
@export var combo_input_window: float = 0.22
@export var heavy_pause_before_attack3: float = 0.18

@export var melee_anim_names: Array[StringName] = [
	StringName("attack"),
	StringName("attack2"),
	StringName("attack3"),
]

@export var melee_hit_delay_by_anim: Dictionary = {
	"attack": 0.08,
	"attack2": 0.10,
	"attack3": 0.16,
}

@export var melee_damage_mult_by_step: Dictionary = {
	1: 1.00,
	2: 1.10,
	3: 1.75,
}
@export var melee_knockback_by_step: Dictionary = {
	1: Vector2(120, -80),
	2: Vector2(150, -95),
	3: Vector2(210, -120),
}

@export var melee_base_damage: int = 2
@export var melee_hitstop_sec: float = 0.045
@export var melee_hitstop_scale: float = 0.08
@export var melee_cam_shake_px: float = 2.8
@export var melee_cam_shake_sec: float = 0.09
@export var melee_finisher_burst_enabled: bool = true
@export var melee_finisher_burst_radius: float = 44.0
@export var melee_finisher_burst_damage: int = 1
@export var melee_finisher_burst_knockback: float = 185.0
@export var melee_finisher_cooldown_refund_sec: float = 0.35

var attack_area: Area2D = null

var is_attack_on_cooldown: bool = false
var is_attacking: bool = false
var _attack_performed: bool = false
var _queued_attack_after_hurt: bool = false

# combo runtime
var _combo_step: int = 0
var _combo_queued: bool = false
var _combo_can_chain: bool = false
var _combo_press_buffered: bool = false
var _combo_timer: float = 0.0
var _melee_step_damage_mult: float = 1.0
var _active_melee_anim: StringName = StringName()
var _melee_finish_token: int = 0
var _melee_micro_step_speed: float = 0.0
var _melee_micro_step_time_left: float = 0.0
var _melee_finisher_triggered: bool = false

# =========================
# LANE BODY
# =========================
@export var depth_speed: float = 40.0
@export var depth_radius: float = 8.0
@onready var lane_body: LaneBody = $LaneBody

@export var skill_origin_path: NodePath = NodePath("AnimatedSprite2D/SkillOrigin")

func skills_get_origin_global() -> Vector2:
	var so = $AnimatedSprite2D/SkillOrigin
	return so.global_position


func skills_get_visual_root() -> Node2D:
	# Узел, который реально двигается по depth_y
	if lane_body and lane_body.use_visual_offset and lane_body.visual_root_path != NodePath():
		var vr := lane_body.get_node_or_null(lane_body.visual_root_path) as Node2D
		if vr:
			return vr
	# fallback
	if animated_sprite_2d:
		return animated_sprite_2d
	return self

func skills_get_visual_offset() -> Vector2:
	var vr := skills_get_visual_root()
	return vr.global_position - global_position


var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# Прыжки
const BASE_JUMPS: int = 1
const EXTRA_JUMPS_WHEN_NICOTINE: int = 1
var jumps_left: int = BASE_JUMPS

var last_move_direction: Vector2 = Vector2.RIGHT

# ВАЖНО: Dash скилл должен выставлять is_dashing=true пока идёт
var is_dashing: bool = false
var is_dodging: bool = false
const _DASH_COMBO_PENDING_META: StringName = &"_dash_projectile_combo_pending"
var _surface_slow_multiplier: float = 1.0
var _surface_slow_until_msec: int = 0

func apply_projectile_dash_combo(payload: Dictionary) -> void:
	if payload.is_empty():
		return
	set_meta(_DASH_COMBO_PENDING_META, payload)
	_apply_projectile_dash_combo_to_active_controller()

func _apply_projectile_dash_combo_to_active_controller() -> bool:
	if not has_meta(_DASH_COMBO_PENDING_META):
		return false

	var raw: Variant = get_meta(_DASH_COMBO_PENDING_META)
	if typeof(raw) != TYPE_DICTIONARY:
		remove_meta(_DASH_COMBO_PENDING_META)
		return false
	var payload := raw as Dictionary

	var applied: bool = false
	for child in get_children():
		if child != null and child.has_method("apply_projectile_synergy"):
			child.call("apply_projectile_synergy", payload)
			applied = true

	if applied:
		remove_meta(_DASH_COMBO_PENDING_META)
	return applied

func _consume_pending_projectile_dash_combo() -> Dictionary:
	if not has_meta(_DASH_COMBO_PENDING_META):
		return {}
	var raw: Variant = get_meta(_DASH_COMBO_PENDING_META)
	remove_meta(_DASH_COMBO_PENDING_META)
	if typeof(raw) == TYPE_DICTIONARY:
		return raw as Dictionary
	return {}

func apply_surface_slow(multiplier: float, duration_sec: float = 0.12) -> void:
	var m: float = clampf(multiplier, SURFACE_SLOW_MIN, 1.0)
	_surface_slow_multiplier = m
	var until: int = Time.get_ticks_msec() + int(maxf(0.0, duration_sec) * 1000.0)
	if until > _surface_slow_until_msec:
		_surface_slow_until_msec = until

func _surface_speed_multiplier() -> float:
	if _surface_slow_until_msec <= 0:
		return 1.0
	if Time.get_ticks_msec() > _surface_slow_until_msec:
		_surface_slow_until_msec = 0
		_surface_slow_multiplier = 1.0
		return 1.0
	return _surface_slow_multiplier

# =========================
#        === HP SYSTEM ===
# =========================
signal health_changed(current:int, max:int)
signal died

@export var hp_max:int = 10
@export var invuln_time: float = 0.6
@export var hurt_stun_time: float = 0.12
@export var hurt_hitstop_sec: float = 0.03
@export var hurt_hitstop_scale: float = 0.16
@export var hurt_cam_shake_px: float = 2.0
@export var hurt_cam_shake_sec: float = 0.08
var hp:int = 0
var _invulnerable: bool = false
var _dead: bool = false
enum ActionState { FREE, DASH, DODGE, HURT, CAST, ATTACK, ITEM, LAND_LOCK, FRENZY, DEAD }

var _hitstop_token: int = 0
var _camera_shake_time: float = 0.0
var _camera_shake_dur: float = 0.0
var _camera_shake_amp: float = 0.0
var _camera_base_offset: Vector2 = Vector2.ZERO
var _camera_cached: Camera2D = null

# --- anti-stuck hurt state ---
var _hurt_active: bool = false
var _hurt_token: int = 0
var _saved_collision_mask: int = 0
var _mask_lane_suppressed: bool = false

func _suppress_lane_mask(enable: bool) -> void:
	if enable:
		if _mask_lane_suppressed:
			return
		_saved_collision_mask = collision_mask
		collision_mask = LAYER_WORLD | LAYER_TRIGGER | LAYER_HAZARD
		_mask_lane_suppressed = true
	else:
		if not _mask_lane_suppressed:
			return
		collision_mask = _saved_collision_mask
		_mask_lane_suppressed = false

func _hurt_end(token: int, old_mod: Color) -> void:
	if token != _hurt_token:
		return
	_hurt_release_control(token)
	_invulnerable = false

	if animated_sprite_2d:
		animated_sprite_2d.modulate = old_mod

func _hurt_release_control(token: int) -> void:
	if token != _hurt_token:
		return
	_hurt_active = false
	_suppress_lane_mask(false)

	_return_to_motion_anim()

	if _queued_attack_after_hurt and not _dead:
		_queued_attack_after_hurt = false
		if not is_using_bottle and not is_casting and not _frenzy_active and not _frenzy_recovering:
			_on_attack_pressed()

func _get_action_state() -> ActionState:
	if _dead or hp <= 0:
		return ActionState.DEAD
	if _hurt_active:
		return ActionState.HURT
	if _frenzy_active or _frenzy_recovering:
		return ActionState.FRENZY
	if is_dashing:
		return ActionState.DASH
	if is_dodging:
		return ActionState.DODGE
	if is_casting:
		return ActionState.CAST
	if is_attacking:
		return ActionState.ATTACK
	if is_using_bottle:
		return ActionState.ITEM
	if _land_lock and is_on_floor():
		return ActionState.LAND_LOCK
	return ActionState.FREE

func is_dead() -> bool:
	return _dead or hp <= 0

# =========================
#     AIR SUBSTATES
# =========================
enum AirState { GROUND, ASCEND, FALL, LAND }
var _air_state: int = AirState.GROUND
var _has_split_jump: bool = false
var _land_lock: bool = false
var is_using_bottle: bool = false  # (используется как общий item-lock для use_bottle / use_cig)
var _pending_use_cig_ignite: bool = false

@export var use_cig_ignite_radius: float = 72.0
@export var use_cig_ignite_depth_tolerance: float = 10.0

# сохранение контекста
var _restore_anim: StringName = StringName()
var _restore_frame: int = 0
var _restore_speed: float = 1.0
var _restore_flip: bool = false

const JUMP_RANGE := Vector2i(0, 3)
const FALL_RANGE := Vector2i(4, 6)
const LAND_RANGE := Vector2i(7, 8)

# Фейл-сейфы
const LAND_LOCK_FALLBACK: float = 0.22
const MELEE_LOCK_MAX := 0.65
const BOTTLE_LOCK_MAX := 1.2

# ====== snap drop fix ======
var _default_floor_snap: float = 16.0
var _snap_disable_frames: int = 0
var _prev_lane_index: int = -1

# ===== Autoload helpers =====
func _res_node() -> Node:
	return get_node_or_null("/root/Resources")

func _effects_node() -> Node:
	return get_node_or_null("/root/ItemEffects")

func _nicotine_value() -> int:
	var r := _res_node()
	return int(r.get("nicotine")) if r else 0

func _has_nicotine_for_double() -> bool:
	return _nicotine_value() > 0

# --- EQUIP (API ДЛЯ МЕНЮ) ---
func equip_skill(slot:int, skill) -> void:
	_skills_runtime.equip_skill(self, slot, skill)

func equip_skill_by_id(slot_index: int, skill_id: StringName) -> void:
	_skills_runtime.equip_skill_by_id(self, slot_index, skill_id)

# =========================
#    === BERSERK STATE ===
# =========================
var berserk_active: bool = false
var berserk_out_bonus: int = 5
var berserk_in_bonus: int = 5
var _berserk_timer: SceneTreeTimer = null
var _berserk_token: int = 0
var is_casting: bool = false
var _casting_anim: StringName = StringName()

@export var berserk_anim_name: StringName = &"berserk"
@export var berserk_play_anim: bool = true
@export var berserk_cast_lock: bool = true

# =========================
#   PASSIVE: FULL HP FRENZY
# =========================
@export var frenzy_enabled: bool = true
@export var frenzy_duration: float = 3.0
@export var frenzy_recovery: float = 0.45
@export var frenzy_move_speed_mult: float = 1.25
@export var frenzy_attack_range: float = 18.0
@export var frenzy_retarget_interval: float = 0.2

var _frenzy_active: bool = false
var _frenzy_recovering: bool = false
var _frenzy_full_latch: bool = false
var _frenzy_token: int = 0
var _frenzy_retarget_left: float = 0.0
var _frenzy_target: Node2D = null

func get_outgoing_damage_bonus() -> int:
	return berserk_out_bonus if berserk_active else 0

func get_melee_damage() -> int:
	var base := melee_base_damage + get_outgoing_damage_bonus()
	return int(round(max(0, base) * _melee_step_damage_mult))

# --- API ДЛЯ СКИЛЛА BerserkSkill.gd ---
func berserk_start(duration: float) -> void:
	berserk_active = true

	# гарантируем non-loop
	if _has_anim(berserk_anim_name):
		_set_anim_loop(berserk_anim_name, false)

	# проигрываем анимацию
	if berserk_play_anim and _has_anim(berserk_anim_name):
		if berserk_cast_lock:
			play_cast_anim(String(berserk_anim_name))
		else:
			animated_sprite_2d.speed_scale = 1.0
			animated_sprite_2d.frame = 0
			animated_sprite_2d.play(String(berserk_anim_name))

	# таймер баффа (не зависит от анимации)
	_berserk_token += 1
	var t := _berserk_token
	_berserk_timer = get_tree().create_timer(max(0.05, duration))
	await _berserk_timer.timeout
	if t != _berserk_token:
		return
	berserk_end()

func berserk_end() -> void:
	_berserk_token += 1
	berserk_active = false
	_berserk_timer = null
	if is_casting and _casting_anim == berserk_anim_name:
		is_casting = false
		_casting_anim = StringName()
		_return_to_motion_anim()

func _maybe_start_frenzy_from_pool() -> void:
	if not frenzy_enabled or _dead:
		return
	if hp < hp_max:
		_frenzy_full_latch = false
		return
	if _frenzy_full_latch:
		return
	if _frenzy_active or _frenzy_recovering:
		return
	_frenzy_full_latch = true
	_start_frenzy()

func _start_frenzy() -> void:
	if _dead or _frenzy_active or _frenzy_recovering:
		return

	_cancel_action_locks_on_hurt()
	_frenzy_token += 1
	var token: int = _frenzy_token

	_frenzy_active = true
	_frenzy_recovering = false
	_frenzy_retarget_left = 0.0
	_frenzy_target = null

	await get_tree().create_timer(maxf(0.05, frenzy_duration)).timeout
	if token != _frenzy_token or _dead:
		return

	_frenzy_active = false
	_frenzy_target = null
	_frenzy_recovering = true
	velocity.x = 0.0
	_return_to_motion_anim()

	await get_tree().create_timer(maxf(0.0, frenzy_recovery)).timeout
	if token != _frenzy_token or _dead:
		return

	_frenzy_recovering = false
	_return_to_motion_anim()

func _is_target_same_lane(target: Node2D) -> bool:
	if target == null or lane_body == null:
		return false
	var my_depth: float = float(lane_body.depth_y)
	var target_depth: float = _depth_y_of(target)
	if is_inf(target_depth):
		return true
	return absf(target_depth - my_depth) <= _depth_reach_with_target(target)

func _depth_reach_with_target(target: Object) -> float:
	return maxf(0.0, depth_radius) + _depth_radius_of(target)

func _depth_y_of(target: Object) -> float:
	if target == null:
		return INF
	if target.has_method("combat_get_depth_y"):
		var dm: Variant = target.call("combat_get_depth_y")
		if typeof(dm) == TYPE_FLOAT or typeof(dm) == TYPE_INT:
			return float(dm)
	var lb: Variant = target.get("lane_body")
	if lb != null and lb is Object:
		var lb_obj := lb as Object
		var d1: Variant = lb_obj.get("depth_y")
		if typeof(d1) == TYPE_FLOAT or typeof(d1) == TYPE_INT:
			return float(d1)
	var d2: Variant = target.get("depth_y")
	if typeof(d2) == TYPE_FLOAT or typeof(d2) == TYPE_INT:
		return float(d2)
	return INF

func _depth_radius_of(target: Object) -> float:
	if target == null:
		return 0.0
	if target.has_method("combat_get_depth_radius"):
		var rm: Variant = target.call("combat_get_depth_radius")
		if typeof(rm) == TYPE_FLOAT or typeof(rm) == TYPE_INT:
			return maxf(0.0, float(rm))
	var r: Variant = target.get("depth_radius")
	if typeof(r) == TYPE_FLOAT or typeof(r) == TYPE_INT:
		return maxf(0.0, float(r))
	return 0.0

func _lane_index_of(target: Object) -> int:
	if target == null:
		return -1
	var lb: Variant = target.get("lane_body")
	if lb != null and lb is Object:
		var lb_obj := lb as Object
		var lbi: Variant = lb_obj.get("lane_index")
		if typeof(lbi) == TYPE_INT:
			return int(lbi)
	var li: Variant = target.get("lane_index")
	if typeof(li) == TYPE_INT:
		return int(li)
	return -1

func combat_get_depth_y() -> float:
	if lane_body != null:
		return float(lane_body.depth_y)
	return global_position.y

func combat_get_depth_radius() -> float:
	return maxf(0.0, depth_radius)

func _is_dead_target(target: Node2D) -> bool:
	if target == null:
		return true
	if target.has_method("is_dead"):
		return bool(target.call("is_dead"))
	var po := target as Object
	if po == null:
		return false
	var dead_flag: Variant = po.get("is_dead")
	if typeof(dead_flag) == TYPE_BOOL and bool(dead_flag):
		return true
	var hp_v: Variant = po.get("hp")
	if typeof(hp_v) == TYPE_INT and int(hp_v) <= 0:
		return true
	return false

func _select_frenzy_target() -> Node2D:
	var nearest: Node2D = null
	var best_d2: float = INF
	var enemies: Array = get_tree().get_nodes_in_group("Enemy")
	for n in enemies:
		if not (n is Node2D):
			continue
		var e := n as Node2D
		if e == null or not is_instance_valid(e):
			continue
		if _is_dead_target(e):
			continue
		if not _is_target_same_lane(e):
			continue
		var d2: float = global_position.distance_squared_to(e.global_position)
		if d2 < best_d2:
			best_d2 = d2
			nearest = e
	return nearest

func _frenzy_axis_and_attack(delta: float) -> float:
	if not _frenzy_active or _dead:
		return 0.0

	_frenzy_retarget_left -= maxf(0.0, delta)
	var need_target: bool = (_frenzy_target == null) or (not is_instance_valid(_frenzy_target)) or _is_dead_target(_frenzy_target) or (not _is_target_same_lane(_frenzy_target))
	if need_target or _frenzy_retarget_left <= 0.0:
		_frenzy_target = _select_frenzy_target()
		_frenzy_retarget_left = maxf(0.05, frenzy_retarget_interval)

	if _frenzy_target == null:
		return 0.0

	var dx: float = _frenzy_target.global_position.x - global_position.x
	if absf(dx) <= frenzy_attack_range:
		if not is_attacking and not is_attack_on_cooldown and not is_casting and not is_using_bottle:
			_on_attack_pressed()
		return 0.0
	return signf(dx)

# =========================
# --- Устранение ложных падений ---
const FALL_AIR_TIME_THRESHOLD := 0.08
const FALL_HEIGHT_THRESHOLD   := 10.0
const LAND_MIN_AIR_TIME       := 0.05
const LAND_MIN_DROP           := 8.0
const FALL_START_VY_MIN       := 40.0

var _air_leave_time: float = 0.0
var _air_leave_y: float = 0.0
var _was_on_floor: bool = false
var _was_grounded_relaxed: bool = false
var _prev_floor_normal: Vector2 = Vector2.UP

func _is_grounded_relaxed() -> bool:
	if is_on_floor():
		return true
	if test_move(global_transform, Vector2(0.0, max(4.0, floor_snap_length))):
		return true
	return false

# =========================
#    DEPTH LOCK CONTROL
# =========================
func _depth_should_lock() -> bool:
	match _get_action_state():
		ActionState.DODGE, ActionState.ATTACK, ActionState.ITEM, ActionState.CAST, ActionState.FRENZY:
			return true
		_:
			return false

func _apply_depth_lock() -> void:
	if lane_body == null:
		return
	lane_body.depth_locked = _depth_should_lock()

# =========================
#    FLOOR DROP ON LANE CHANGE
# =========================
func _force_drop_from_floor() -> void:
	_snap_disable_frames = 1
	velocity.y = max(velocity.y, 1.0)

# =========================
#    LANE BLOCKING HELPERS
# =========================
func _active_cshape() -> CollisionShape2D:
	if human_collision_shape2d and not human_collision_shape2d.disabled:
		return human_collision_shape2d
	return null

func _can_be_in_lane(lane: int) -> bool:
	var cs := _active_cshape()
	if cs == null or cs.shape == null:
		return true

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = cs.shape
	params.transform = cs.global_transform
	params.collision_mask = LaneSystem.layer_from_lane(lane)
	params.exclude = [get_rid()]
	params.margin = 0.05

	var space := get_world_2d().direct_space_state
	var hits := space.intersect_shape(params, 1)
	return hits.is_empty()

# =========================

func _ready() -> void:
	randomize()

	_default_floor_snap = floor_snap_length
	_prev_lane_index = lane_body.lane_index

	if not lane_body.lane_changed.is_connected(_on_lane_changed):
		lane_body.lane_changed.connect(_on_lane_changed)

	_apply_lane_collision_mask(lane_body.lane_index)

	# SHADOW
	if shadow:
		_shadow_base_scale = shadow.scale
		shadow.visible = true
		shadow.z_index = animated_sprite_2d.z_index
		shadow.z_as_relative = true
		if shadow.get_parent() == self:
			move_child(shadow, 0)
	_shadow_ground_y = global_position.y

	# --- Коллизии / слои ---
	collision_layer = LAYER_PLAYER
	set_collision_mask_value(3, false)

	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED

	add_to_group("Player")
	jumps_left = _calc_allowed_jumps()
	set_physics_process(true)

	human_collision_shape2d.disabled = false

	skills_clear_slots()
	if has_node("/root/DevLoadout") and DevLoadout.has_method("safe_apply_later"):
		DevLoadout.safe_apply_later(self)

	if has_node("Attack"):
		attack_area = $Attack
		attack_area.monitoring = false
		if attack_area.has_signal("hit"):
			attack_area.connect("hit", Callable(self, "_on_melee_hit"))

	# Спрайтовые анимации
	if animated_sprite_2d and animated_sprite_2d.sprite_frames:
		_has_split_jump = (
			animated_sprite_2d.sprite_frames.has_animation("jump_up")
			and animated_sprite_2d.sprite_frames.has_animation("fall")
			and animated_sprite_2d.sprite_frames.has_animation("land")
		)

		_force_non_loop_one_shots()

		if not animated_sprite_2d.frame_changed.is_connected(_on_as2d_frame_changed):
			animated_sprite_2d.frame_changed.connect(_on_as2d_frame_changed)
		if not animated_sprite_2d.animation_finished.is_connected(_on_sprite_animation_finished):
			animated_sprite_2d.animation_finished.connect(_on_sprite_animation_finished)

	if has_node("AnimationPlayer"):
		$AnimationPlayer.connect("animation_finished", Callable(self, "_on_animation_finished"))

	# HP/inebriation unified pool init
	_bind_hp_to_inebriation_pool()
	_cache_camera()

func _exit_tree() -> void:
	if Engine.time_scale < 1.0:
		Engine.time_scale = 1.0

func _process(delta: float) -> void:
	_update_shadow()
	_update_camera_shake(delta)

# -------------------------
# Feedback Runtime Proxies
# -------------------------
func _cache_camera() -> void:
	_feedback_runtime.cache_camera(self)

func _camera() -> Camera2D:
	return _feedback_runtime.camera(self)

func _start_camera_shake(strength_px: float, duration: float) -> void:
	_feedback_runtime.start_camera_shake(self, strength_px, duration)

func _update_camera_shake(delta: float) -> void:
	_feedback_runtime.update_camera_shake(self, delta)

func _start_hitstop(duration: float, time_scale: float) -> void:
	await _feedback_runtime.start_hitstop(self, duration, time_scale)

func _movement_locked() -> bool:
	match _get_action_state():
		ActionState.DODGE, ActionState.ATTACK, ActionState.ITEM, ActionState.CAST, ActionState.LAND_LOCK, ActionState.FRENZY:
			return true
		_:
			return false

func _physics_process(delta: float) -> void:
	# FIX: каждый кадр проверяем “залипшие” локи из-за перебитых анимаций
	_animation_watchdog()

	# snap drop fix
	if _snap_disable_frames > 0:
		_snap_disable_frames -= 1
		floor_snap_length = 0.0
	else:
		floor_snap_length = _default_floor_snap

	# depth lock
	_apply_depth_lock()

	# комбо-таймер (сброс шага если тянем)
	if _combo_step > 0 and not is_attacking:
		_combo_timer += delta
		if _combo_timer >= combo_reset_time:
			_reset_combo()

	# input: attack
	if Input.is_action_just_pressed("attack"):
		if _hurt_active:
			_queued_attack_after_hurt = true
		elif not is_using_bottle and not is_casting and not _frenzy_active and not _frenzy_recovering:
			_on_attack_pressed()

	var grounded_relaxed_pre := _is_grounded_relaxed()
	if grounded_relaxed_pre:
		_shadow_ground_y = global_position.y

	var surface_speed_mul: float = _surface_speed_multiplier()
	var frenzy_speed_mul: float = frenzy_move_speed_mult if _frenzy_active else 1.0
	var move_speed: float = SPEED * surface_speed_mul * frenzy_speed_mul
	var lane_move_speed: float = depth_speed * surface_speed_mul

	# ===== LANE SWITCH =====
	if not lane_body.depth_locked:
		var depth_axis_now: float = Input.get_axis("ui_up", "ui_down")
		if not is_zero_approx(depth_axis_now):
			var proposed: float = lane_body.depth_y + depth_axis_now * lane_move_speed * delta
			proposed = LaneSystem.clamp_depth(proposed)

			var target_lane: int = LaneSystem.lane_from_depth(proposed)
			if target_lane == lane_body.lane_index or _can_be_in_lane(target_lane):
				lane_body.depth_y = proposed

	var frenzy_axis: float = _frenzy_axis_and_attack(delta)
	var movement_locked: bool = _movement_locked()
	var input_axis: float = frenzy_axis if _frenzy_active else (0.0 if movement_locked else Input.get_axis("ui_left", "ui_right"))
	var jump_allowed: bool = (not movement_locked) and (not is_dashing)

	# если каст — тормозим X
	if is_casting:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 10.0 * delta)

	# ---------- GRAVITY ----------
	if not is_on_floor():
		velocity.y += gravity * delta

	# прыжок
	if jump_allowed and Input.is_action_just_pressed("ui_accept"):
		if _is_grounded_relaxed():
			jumps_left = _calc_allowed_jumps()
		var midair_ok := (jumps_left > 0 and _has_nicotine_for_double())
		if _is_grounded_relaxed() or midair_ok:
			var was_midair := not _is_grounded_relaxed()
			velocity.y = JUMP_VELOCITY
			if jumps_left > 0:
				jumps_left -= 1
			_enter_air_ascend(was_midair)
	elif not jump_allowed and _is_grounded_relaxed():
		velocity.y = move_toward(velocity.y, 0.0, 2000.0 * delta)

	# двойной прыжок лимит
	if _is_grounded_relaxed():
		jumps_left = _calc_allowed_jumps()
	elif jumps_left > 0 and not _has_nicotine_for_double():
		jumps_left = 0

	# ходьба
	if input_axis != 0.0 and (not movement_locked or _frenzy_active):
		velocity.x = input_axis * move_speed
		last_move_direction = Vector2.RIGHT if input_axis > 0.0 else Vector2.LEFT
	else:
		if not is_casting:
			velocity.x = move_toward(velocity.x, 0.0, move_speed)

	_apply_melee_micro_step(delta)

	# ====== движение ======
	move_and_slide()

	# ====== если на земле сменили lane — сбрасываем "липкий пол" ======
	if is_on_floor() and _prev_lane_index != lane_body.lane_index:
		_force_drop_from_floor()

	_prev_lane_index = lane_body.lane_index

	# --- трекинг отрыва и «мягкой земли» ---
	var grounded_relaxed := _is_grounded_relaxed()
	var left_floor_this_frame := (_was_on_floor and not grounded_relaxed)

	if left_floor_this_frame:
		_air_leave_time = 0.0
		_air_leave_y = global_position.y
	elif not grounded_relaxed:
		_air_leave_time += delta

	# --- вход в падение с порогами ---
	if not grounded_relaxed:
		if velocity.y >= max(0.0, FALL_START_VY_MIN) and _air_state != AirState.FALL:
			var drop := global_position.y - _air_leave_y
			if (_air_leave_time >= FALL_AIR_TIME_THRESHOLD) or (drop >= FALL_HEIGHT_THRESHOLD):
				_enter_air_fall()
	else:
		var did_real_air := (_air_leave_time >= LAND_MIN_AIR_TIME) or ((global_position.y - _air_leave_y) >= LAND_MIN_DROP)
		var just_landed_relaxed := (not _was_grounded_relaxed) and grounded_relaxed and did_real_air

		if just_landed_relaxed and not _land_lock:
			_enter_land()

	update_animations(input_axis)

	_try_consume_queued_dash()
	_skills_process(delta)

	_was_on_floor = grounded_relaxed
	_was_grounded_relaxed = grounded_relaxed
	_prev_floor_normal = get_floor_normal()

	if Input.is_action_just_pressed("dodge"):
		_try_use_dodge_action()
	if Input.is_action_just_pressed("skill_1"): skills_use_slot(1)
	if Input.is_action_just_pressed("skill_2"): skills_use_slot(2)
	if Input.is_action_just_pressed("skill_3"): skills_use_slot(3)
	if Input.is_action_just_pressed("skill_4"): skills_use_slot(4)
# --- Использование расходников ---
func _unhandled_input(event: InputEvent) -> void:
	if _movement_locked():
		return
	if is_dashing and (event.is_action_pressed("use_bottle") or event.is_action_pressed("use_cigs")):
		return

	if event.is_action_pressed("use_bottle"):
		var effects := _effects_node()
		if effects and effects.has_method("use_full_bottle"):
			if effects.use_full_bottle():
				_start_blocking_anim("use_bottle")
				print("Drink: HP pool = ", hp)
			else:
				print("Нет полной бутылки")
		else:
			print("ItemEffects не подключён")

	elif event.is_action_pressed("use_cigs"):
		var effects2 := _effects_node()
		if effects2 and effects2.has_method("use_cig_pack"):
			if effects2.use_cig_pack():
				_start_blocking_anim("use_cig")
				var c2: int = int(effects2.get("pack_charges"))
				print("Покурил: +", c2, " никотина")
			else:
				print("Нет пачки")
		else:
			print("ItemEffects не подключён")

# --- Вспомогательное: длительность анимации ---
func _anim_duration(anim_name: StringName, speed_scale := 1.0) -> float:
	if not (animated_sprite_2d and animated_sprite_2d.sprite_frames and animated_sprite_2d.sprite_frames.has_animation(anim_name)):
		return 0.0
	var frames := animated_sprite_2d.sprite_frames.get_frame_count(anim_name)
	var fps := float(animated_sprite_2d.sprite_frames.get_animation_speed(anim_name))
	fps = max(1.0, fps * max(0.001, speed_scale))
	return float(frames) / fps

# --- Старт «блокирующей» анимации ---
func _start_blocking_anim(anim_name: String) -> void:
	if is_using_bottle:
		return
	is_using_bottle = true
	_pending_use_cig_ignite = (anim_name == "use_cig")

	if animated_sprite_2d:
		_restore_anim = animated_sprite_2d.animation
		_restore_frame = animated_sprite_2d.frame
		_restore_speed = animated_sprite_2d.speed_scale
		_restore_flip = animated_sprite_2d.flip_h

	# FIX: одноразовые клипы non-loop
	_set_anim_loop(StringName(anim_name), false)

	var played := false
	if has_node("AnimationPlayer") and $AnimationPlayer.has_animation(anim_name):
		$AnimationPlayer.play(anim_name)
		played = true
	elif _has_anim(StringName(anim_name)):
		animated_sprite_2d.speed_scale = 1.0
		animated_sprite_2d.frame = 0
		animated_sprite_2d.play(anim_name)
		played = true

	if has_node("SFXUseBottle") and anim_name == "use_bottle":
		$SFXUseBottle.play()
	if has_node("SFXUseCig") and anim_name == "use_cig":
		$SFXUseCig.play()

	if not played:
		_end_blocking_anim()
		return

	var dur := _anim_duration(StringName(anim_name), animated_sprite_2d.speed_scale)
	if dur <= 0.0:
		dur = BOTTLE_LOCK_MAX
	else:
		dur = min(dur + 0.02, BOTTLE_LOCK_MAX)
	await get_tree().create_timer(dur).timeout
	if is_using_bottle:
		_end_blocking_anim()

func _end_blocking_anim() -> void:
	is_using_bottle = false
	if animated_sprite_2d and (animated_sprite_2d.animation == "use_bottle" or animated_sprite_2d.animation == "use_cig"):
		animated_sprite_2d.animation = _restore_anim
		animated_sprite_2d.frame = _restore_frame
		animated_sprite_2d.speed_scale = _restore_speed
		animated_sprite_2d.flip_h = _restore_flip
	_return_to_motion_anim()

# --- Сколько прыжков доступно сейчас ---
func _calc_allowed_jumps() -> int:
	return BASE_JUMPS + (EXTRA_JUMPS_WHEN_NICOTINE if _has_nicotine_for_double() else 0)

# --- Управление анимациями ---
func update_animations(input_axis: float) -> void:
	if not animated_sprite_2d:
		return

	var action_state: ActionState = _get_action_state()
	if action_state == ActionState.DASH:
		return
	if animated_sprite_2d.animation == &"dodge" and animated_sprite_2d.is_playing():
		return

	# НЕ перебиваем hurt-анимацию только пока она реально проигрывается.
	var current_anim: StringName = StringName(animated_sprite_2d.animation)
	var is_hurt_anim: bool = (current_anim == &"damage" or current_anim == fire_hurt_anim_name)
	if _hurt_active and is_hurt_anim and animated_sprite_2d.is_playing():
		if current_anim == fire_hurt_anim_name:
			_update_hurt_facing(input_axis)
		return

	# НЕ перебиваем каст, пока он активен
	if action_state == ActionState.CAST and _casting_anim != StringName():
		return

	match action_state:
		ActionState.DODGE, ActionState.ATTACK, ActionState.ITEM, ActionState.CAST, ActionState.LAND_LOCK, ActionState.DEAD:
			return
		_:
			pass

	if _air_state == AirState.ASCEND or _air_state == AirState.FALL or _air_state == AirState.LAND:
		return

	var depth_axis := 0.0
	if not lane_body.depth_locked:
		depth_axis = Input.get_axis("ui_up", "ui_down")

	var moving_x := absf(input_axis) > 0.001
	var moving_depth := absf(depth_axis) > 0.001

	if moving_x:
		animated_sprite_2d.flip_h = input_axis < 0.0
	elif last_move_direction != Vector2.ZERO:
		animated_sprite_2d.flip_h = (last_move_direction == Vector2.LEFT)

	if moving_x or moving_depth:
		if moving_x and moving_depth:
			if depth_axis < 0.0:
				if animated_sprite_2d.sprite_frames and animated_sprite_2d.sprite_frames.has_animation("walk-ne"):
					animated_sprite_2d.play("walk-ne")
				else:
					animated_sprite_2d.play("walk")
			else:
				if animated_sprite_2d.sprite_frames and animated_sprite_2d.sprite_frames.has_animation("walk-se"):
					animated_sprite_2d.play("walk-se")
				else:
					animated_sprite_2d.play("walk")
			return

		if moving_depth and not moving_x:
			if depth_axis < 0.0:
				if animated_sprite_2d.sprite_frames and animated_sprite_2d.sprite_frames.has_animation("walk-n"):
					animated_sprite_2d.play("walk-n")
				else:
					animated_sprite_2d.play("walk")
			else:
				if animated_sprite_2d.sprite_frames and animated_sprite_2d.sprite_frames.has_animation("walk-s"):
					animated_sprite_2d.play("walk-s")
				else:
					animated_sprite_2d.play("walk")
			return

		if moving_x and not moving_depth:
			if animated_sprite_2d.sprite_frames and animated_sprite_2d.sprite_frames.has_animation("walk"):
				animated_sprite_2d.play("walk")
			elif animated_sprite_2d.sprite_frames and animated_sprite_2d.sprite_frames.has_animation("walk-se"):
				animated_sprite_2d.play("walk-se")
			else:
				animated_sprite_2d.play("idle")
			return

	animated_sprite_2d.play("idle")

# --- Входы в подпозы воздуха ---
func _enter_air_ascend(is_double: bool=false) -> void:
	_air_state = AirState.ASCEND
	_land_lock = false
	if _has_split_jump:
		_set_anim_loop(&"jump_up", false)
		animated_sprite_2d.speed_scale = 1.15 if is_double else 1.0
		animated_sprite_2d.play("jump_up")
	else:
		animated_sprite_2d.animation = "jump"
		animated_sprite_2d.speed_scale = 1.15 if is_double else 1.0
		animated_sprite_2d.play()
		animated_sprite_2d.frame = JUMP_RANGE.x

func _enter_air_fall() -> void:
	_air_state = AirState.FALL
	_land_lock = false
	if _has_split_jump:
		animated_sprite_2d.speed_scale = 1.0
		animated_sprite_2d.play("fall")
	else:
		animated_sprite_2d.animation = "jump"
		animated_sprite_2d.speed_scale = 1.0
		if animated_sprite_2d.frame < FALL_RANGE.x:
			animated_sprite_2d.frame = FALL_RANGE.x
		animated_sprite_2d.play()

func _enter_land() -> void:
	_air_state = AirState.LAND
	_land_lock = true
	if _has_split_jump:
		_set_anim_loop(&"land", false)
		animated_sprite_2d.speed_scale = 1.0
		animated_sprite_2d.play("land")
	else:
		animated_sprite_2d.animation = "jump"
		animated_sprite_2d.speed_scale = 1.0
		animated_sprite_2d.play()
		if animated_sprite_2d.frame < LAND_RANGE.x:
			animated_sprite_2d.frame = LAND_RANGE.x
	_land_unlock_timeout()

func _land_unlock_timeout() -> void:
	await get_tree().create_timer(LAND_LOCK_FALLBACK).timeout
	if _air_state == AirState.LAND and _land_lock:
		_set_ground_idle_or_run()

func _set_ground_idle_or_run() -> void:
	_air_state = AirState.GROUND
	_land_lock = false
	if animated_sprite_2d:
		animated_sprite_2d.speed_scale = 1.0
	_return_to_motion_anim()

# --- Кламп кадров/завершения ---
func _on_as2d_frame_changed() -> void:
	if _has_split_jump:
		return
	if animated_sprite_2d.animation != "jump":
		return
	var f := animated_sprite_2d.frame
	match _air_state:
		AirState.ASCEND:
			if f > JUMP_RANGE.y:
				animated_sprite_2d.frame = JUMP_RANGE.y
				animated_sprite_2d.stop()
		AirState.FALL:
			if f < FALL_RANGE.x:
				animated_sprite_2d.frame = FALL_RANGE.x
			if f > FALL_RANGE.y:
				animated_sprite_2d.frame = FALL_RANGE.y
		AirState.LAND:
			if f < LAND_RANGE.x:
				animated_sprite_2d.frame = LAND_RANGE.x
			if f >= LAND_RANGE.y:
				_set_ground_idle_or_run()

func _on_sprite_animation_finished() -> void:
	if not animated_sprite_2d:
		return

	var finished: StringName = StringName(animated_sprite_2d.animation)

	# land -> вернуть контроль
	if _has_split_jump and finished == &"land":
		_set_ground_idle_or_run()
		return

	# use_bottle / use_cig -> снять лок
	if finished == &"use_bottle" or finished == &"use_cig":
		if finished == &"use_cig":
			_handle_use_cig_completed()
		_end_blocking_anim()
		return

	# комбо
	if melee_anim_names.has(finished):
		_on_melee_anim_finished(finished)
		return

	# каст (если именно кастовая анимация закончилась)
	if _casting_anim != StringName() and finished == _casting_anim:
		_casting_anim = StringName()
		is_casting = false
		_return_to_motion_anim()
		return

	# FIX: универсальный возврат после любого one-shot клипа
	# (включая damage/vomit/etc), если сейчас нет локающих состояний
	if _one_shot_anims.has(finished):
		if not _movement_locked():
			_return_to_motion_anim()

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "use_bottle" or anim_name == "use_cig":
		if anim_name == "use_cig":
			_handle_use_cig_completed()
		_end_blocking_anim()

func _handle_use_cig_completed() -> void:
	if not _pending_use_cig_ignite:
		return
	_pending_use_cig_ignite = false
	_ignite_vomit_puddle_in_front()

func _ignite_vomit_puddle_in_front() -> void:
	if use_cig_ignite_radius <= 0.0:
		return

	var facing: Vector2 = skills_get_aim_dir()
	if facing == Vector2.ZERO:
		facing = Vector2.RIGHT
	var dir_x: float = signf(facing.x)
	if is_zero_approx(dir_x):
		dir_x = -1.0 if (animated_sprite_2d and animated_sprite_2d.flip_h) else 1.0

	var max_dist_sq: float = use_cig_ignite_radius * use_cig_ignite_radius
	var best: Node2D = null
	var best_dist_sq: float = INF

	for n in get_tree().get_nodes_in_group("vomit_puddle"):
		if n == null or not is_instance_valid(n):
			continue
		if not (n is Node2D):
			continue
		if not _is_puddle_same_lane_or_depth(n):
			continue

		var puddle: Node2D = n as Node2D
		var delta: Vector2 = puddle.global_position - global_position
		var dist_sq: float = delta.length_squared()
		if dist_sq > max_dist_sq:
			continue
		if delta.x * dir_x <= 0.0:
			continue

		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best = puddle

	if best != null and best.has_method("_ignite_self"):
		best.call("_ignite_self")

func _is_puddle_same_lane_or_depth(puddle_node: Node) -> bool:
	if lane_body == null:
		return true
	if not (puddle_node is Object):
		return true

	var po: Object = puddle_node as Object
	var lane_v: Variant = po.get("lane_index")
	if typeof(lane_v) == TYPE_INT and int(lane_v) != -1:
		return int(lane_v) == int(lane_body.lane_index)

	var depth_v: Variant = po.get("depth_y")
	if typeof(depth_v) == TYPE_FLOAT or typeof(depth_v) == TYPE_INT:
		var pd: float = float(depth_v)
		var my_depth: float = float(lane_body.depth_y)
		return absf(pd - my_depth) <= maxf(0.0, use_cig_ignite_depth_tolerance)

	return true

# =========================
# MELEE COMBO LOGIC (NEW)
# =========================
func _on_attack_pressed() -> void:
	if is_attacking:
		if _combo_can_chain:
			_combo_queued = true
		elif _combo_step < 3:
			_combo_press_buffered = true
		return

	if is_attack_on_cooldown:
		return

	_combo_step = clampi((_combo_step if _combo_step > 0 else 0) + 1, 1, 3)
	_combo_timer = 0.0
	_combo_queued = false
	_combo_press_buffered = false
	_start_combo_step(_combo_step)

func _reset_combo() -> void:
	_combo_step = 0
	_combo_timer = 0.0
	_combo_queued = false
	_combo_can_chain = false
	_combo_press_buffered = false
	_melee_step_damage_mult = 1.0
	_active_melee_anim = StringName()
	_melee_finisher_triggered = false
	_melee_finish_token += 1
	_clear_melee_micro_step()

func _anim_for_step(step: int) -> StringName:
	var idx := clampi(step - 1, 0, melee_anim_names.size() - 1)
	return melee_anim_names[idx]

func _hit_delay_for(anim_name: StringName) -> float:
	return float(melee_hit_delay_by_anim.get(String(anim_name), 0.10))

func _start_melee_micro_step(aim_dir: Vector2) -> void:
	var distance: float = maxf(0.0, melee_micro_step_distance)
	var duration: float = maxf(0.0, melee_micro_step_duration)
	if distance <= 0.0 or duration <= 0.0:
		_clear_melee_micro_step()
		return

	var dir_x: float = signf(aim_dir.x)
	if is_zero_approx(dir_x):
		dir_x = -1.0 if (animated_sprite_2d and animated_sprite_2d.flip_h) else 1.0

	_melee_micro_step_speed = (distance / duration) * dir_x
	_melee_micro_step_time_left = duration

func _apply_melee_micro_step(delta: float) -> void:
	if _melee_micro_step_time_left <= 0.0:
		return
	if (not is_attacking) or is_dashing or is_casting:
		_clear_melee_micro_step()
		return

	_melee_micro_step_time_left = maxf(0.0, _melee_micro_step_time_left - delta)
	velocity.x = _melee_micro_step_speed
	if _melee_micro_step_time_left <= 0.0:
		_melee_micro_step_speed = 0.0

func _clear_melee_micro_step() -> void:
	_melee_micro_step_time_left = 0.0
	_melee_micro_step_speed = 0.0

func _arm_melee_finish_watchdog(anim_name: StringName, step: int, timeout: float, token: int) -> void:
	await get_tree().create_timer(maxf(0.02, timeout)).timeout
	if token != _melee_finish_token:
		return
	if not is_attacking:
		return
	if _combo_step != step:
		return
	if _active_melee_anim != anim_name:
		return
	_on_melee_anim_finished(anim_name)

func _start_combo_step(step: int) -> void:
	if is_using_bottle or is_casting:
		return

	is_attacking = true
	_attack_performed = false
	_combo_can_chain = false
	_combo_press_buffered = false
	_melee_finisher_triggered = false

	var anim_name := _anim_for_step(step)
	_set_anim_loop(anim_name, false)

	var aim_dir := skills_get_aim_dir()
	if animated_sprite_2d:
		animated_sprite_2d.flip_h = (aim_dir == Vector2.LEFT)

	if step == 3 and heavy_pause_before_attack3 > 0.0:
		await get_tree().create_timer(heavy_pause_before_attack3).timeout
		if (not is_attacking) or _combo_step != step or _dead:
			return

	if not _has_anim(anim_name):
		anim_name = StringName("attack")

	_set_anim_loop(anim_name, false)

	animated_sprite_2d.speed_scale = 1.0
	animated_sprite_2d.frame = 0
	animated_sprite_2d.play(String(anim_name))
	_active_melee_anim = anim_name
	_start_melee_micro_step(aim_dir)

	_melee_step_damage_mult = float(melee_damage_mult_by_step.get(step, 1.0))
	if attack_area != null:
		var kb: Vector2 = melee_knockback_by_step.get(step, Vector2(160, -120))
		if "hit_knockback" in attack_area:
			attack_area.hit_knockback = kb

	var dur := _anim_duration(anim_name, animated_sprite_2d.speed_scale)
	if dur <= 0.0:
		dur = 0.25
	_melee_finish_token += 1
	var finish_token: int = _melee_finish_token
	_arm_melee_finish_watchdog(anim_name, step, dur + 0.08, finish_token)
	var open_at: float = maxf(0.0, dur - combo_input_window)
	_open_chain_window_late(open_at)

	await get_tree().create_timer(_hit_delay_for(anim_name)).timeout
	if not is_attacking:
		return
	if _active_melee_anim != anim_name:
		return
	if animated_sprite_2d and StringName(animated_sprite_2d.animation) != anim_name:
		return
	if not _attack_performed:
		perform_melee()

	var lock_dur := clampf(dur + 0.02, 0.0, MELEE_LOCK_MAX)
	await get_tree().create_timer(lock_dur).timeout

func _open_chain_window_late(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if is_attacking:
		_combo_can_chain = true
		if _combo_press_buffered and _combo_step < 3:
			_combo_queued = true
		_combo_press_buffered = false

func _on_melee_anim_finished(anim_name: StringName) -> void:
	if not is_attacking:
		return
	if anim_name != _active_melee_anim:
		return

	_combo_can_chain = false
	_combo_press_buffered = false
	_melee_finish_token += 1

	if _combo_queued and _combo_step < 3:
		_combo_queued = false
		_combo_step += 1
		_combo_timer = 0.0
		_start_combo_step(_combo_step)
		return

	is_attacking = false
	_attack_performed = false
	_melee_step_damage_mult = 1.0
	_active_melee_anim = StringName()
	_melee_finisher_triggered = false
	_clear_melee_micro_step()

	if _combo_step >= 3:
		_reset_combo()

	_start_melee_cooldown()
	_return_to_motion_anim()

func _start_melee_cooldown() -> void:
	if is_attack_on_cooldown:
		return
	is_attack_on_cooldown = true
	await get_tree().create_timer(melee_cooldown).timeout
	is_attack_on_cooldown = false

func perform_melee() -> void:
	if attack_area == null:
		return
	_attack_performed = true
	var aim_dir: Vector2 = skills_get_aim_dir()
	var flip: float = -1.0 if aim_dir == Vector2.LEFT else 1.0
	attack_area.position = Vector2(melee_offset.x * flip, melee_offset.y)
	attack_area.rotation = 0
	if attack_area.has_method("swing"):
		attack_area.swing(global_position, aim_dir, _is_grounded_relaxed())
	else:
		push_warning("Attack node has no method 'swing' — check Attack.gd")

func _on_melee_hit(_target: Node) -> void:
	if has_node("MeleeHitParticles"):
		$MeleeHitParticles.restart()
	if has_node("SFXMelee"):
		$SFXMelee.play()
	_start_camera_shake(melee_cam_shake_px, melee_cam_shake_sec)
	_start_hitstop(melee_hitstop_sec, melee_hitstop_scale)
	if _combo_step == 3 and not _melee_finisher_triggered:
		_melee_finisher_triggered = true
		_trigger_melee_finisher(_target)

func _trigger_melee_finisher(primary_target: Node) -> void:
	if melee_finisher_burst_enabled:
		_apply_melee_finisher_burst(primary_target)
	_refund_skill_cooldowns(melee_finisher_cooldown_refund_sec)
	_start_camera_shake(melee_cam_shake_px * 1.45, melee_cam_shake_sec * 1.2)

func _refund_skill_cooldowns(amount_sec: float) -> void:
	var refund: float = maxf(0.0, amount_sec)
	if refund <= 0.0:
		return
	for slot_variant in skills_cooldowns.keys():
		var slot: int = int(slot_variant)
		var before: float = float(skills_cooldowns.get(slot, 0.0))
		if before <= 0.0:
			continue
		var after: float = maxf(0.0, before - refund)
		skills_cooldowns[slot] = after
		if after <= 0.0 and before > 0.0:
			skill_ready.emit(slot)

func _apply_melee_finisher_burst(primary_target: Node) -> void:
	var radius: float = maxf(0.0, melee_finisher_burst_radius)
	if radius <= 0.0 or melee_finisher_burst_damage <= 0:
		return
	var world: World2D = get_world_2d()
	if world == null:
		return
	var space: PhysicsDirectSpaceState2D = world.direct_space_state
	if space == null:
		return

	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = radius

	var params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0.0, global_position)
	params.collide_with_areas = true
	params.collide_with_bodies = true
	params.collision_mask = 0x7FFFFFFF
	params.exclude = [get_rid()]

	var results: Array[Dictionary] = space.intersect_shape(params, 24)
	var already_hit: Dictionary = {}
	if primary_target != null:
		already_hit[primary_target.get_instance_id()] = true

	for result: Dictionary in results:
		var collider_variant: Variant = result.get("collider")
		if not (collider_variant is Object):
			continue
		var resolved: Node = _resolve_melee_finisher_target(collider_variant as Object)
		if resolved == null or resolved == self:
			continue
		if not _can_hit_melee_finisher_target(resolved):
			continue

		var target_id: int = resolved.get_instance_id()
		if already_hit.has(target_id):
			continue
		already_hit[target_id] = true

		var kb: Vector2 = _melee_finisher_knockback_for(resolved)
		resolved.call("apply_damage", melee_finisher_burst_damage, kb, global_position)

func _resolve_melee_finisher_target(raw: Object) -> Node:
	if raw is Node and (raw as Node).has_method("apply_damage"):
		return raw as Node
	if raw is Node:
		var parent: Node = (raw as Node).get_parent()
		if parent != null and parent.has_method("apply_damage"):
			return parent
	return null

func _can_hit_melee_finisher_target(target: Node) -> bool:
	if target == null or target.is_in_group("Player"):
		return false
	if not target.has_method("apply_damage"):
		return false
	var target_depth: float = _depth_y_of(target as Object)
	var my_depth: float = _depth_y_of(self)
	if not is_inf(target_depth) and not is_inf(my_depth):
		var tolerance: float = combat_get_depth_radius() + _depth_radius_of(target as Object)
		if absf(target_depth - my_depth) > tolerance:
			return false
	return true

func _melee_finisher_knockback_for(target: Node) -> Vector2:
	var dir_x: float = 1.0
	if target is Node2D:
		dir_x = signf((target as Node2D).global_position.x - global_position.x)
	if is_zero_approx(dir_x):
		dir_x = -1.0 if (animated_sprite_2d and animated_sprite_2d.flip_h) else 1.0
	return Vector2(dir_x * melee_finisher_burst_knockback, -110.0)

func _get_skills_db() -> Node:
	return _skills_runtime.get_skills_db(self)

# =========================
#        === DAMAGE API ===
# =========================

func _cancel_action_locks_on_hurt() -> void:
	is_dodging = false
	_frenzy_token += 1
	_frenzy_active = false
	_frenzy_recovering = false
	_frenzy_target = null
	_frenzy_retarget_left = 0.0

	# комбо/атака
	is_attacking = false
	_attack_performed = false
	_combo_can_chain = false
	_combo_queued = false
	_reset_combo()
	_melee_step_damage_mult = 1.0
	_active_melee_anim = StringName()
	_clear_melee_micro_step()

	# бутылка/сиги (общий item-lock)
	is_using_bottle = false

	# касты
	is_casting = false
	_casting_anim = StringName()

	# посадочный лок
	_land_lock = false
	if _air_state == AirState.LAND:
		_air_state = AirState.GROUND

	# хитбокс
	if attack_area:
		attack_area.monitoring = false

	# если AnimationPlayer мог держать "use_bottle" и т.п.
	if has_node("AnimationPlayer"):
		$AnimationPlayer.stop()

func apply_damage(amount:int, a:Variant=null, b:Variant=null) -> void:
	if _dead:
		return
	if _invulnerable or _hurt_active:
		return

	if berserk_active:
		amount = max(0, amount + berserk_in_bonus)

	var from_pos: Vector2 = global_position
	var knock_vec: Vector2 = Vector2.ZERO
	var damage_source: Variant = null

	if a is Vector2 and b is Vector2:
		knock_vec = a
		from_pos = b
	elif a is Vector2 and b is Object:
		knock_vec = a
		damage_source = b
	elif a is Vector2 and b == null:
		from_pos = a
	elif a is Object:
		damage_source = a
	elif b is Object:
		damage_source = b

	_set_hp_pool(hp - max(0, amount))

	if hp <= 0:
		_die()
		return

	_start_camera_shake(hurt_cam_shake_px, hurt_cam_shake_sec)
	_start_hitstop(hurt_hitstop_sec, hurt_hitstop_scale)

	_hurt_active = true
	_invulnerable = true
	_cancel_action_locks_on_hurt()
	_hurt_token += 1
	var token := _hurt_token

	var old_mod := animated_sprite_2d.modulate if animated_sprite_2d else Color(1,1,1,1)

	_suppress_lane_mask(true)

	# knockback — только если передали явный вектор
	if knock_vec != Vector2.ZERO:
		var dir_x := signf(knock_vec.x)
		if dir_x != 0.0:
			apply_knockback(Vector2(dir_x, 0.0))

	# hit react
	var hurt_anim: StringName = _get_hurt_anim_name(damage_source)
	if _has_anim(hurt_anim):
		var wait_time: float = _get_hurt_anim_wait_time(hurt_anim, animated_sprite_2d.speed_scale)
		await _play_hurt_anim_for_duration(hurt_anim, wait_time, token)
		if _dead or token != _hurt_token:
			_hurt_end(token, old_mod)
			return

	# короткий стан
	if hurt_stun_time > 0.0:
		await get_tree().create_timer(hurt_stun_time).timeout
		if _dead or token != _hurt_token:
			_hurt_end(token, old_mod)
			return

	_hurt_release_control(token)

	# invuln blink
	if animated_sprite_2d:
		animated_sprite_2d.modulate = Color(1,1,1,0.55)

	await get_tree().create_timer(invuln_time).timeout
	if _dead or token != _hurt_token:
		_hurt_end(token, old_mod)
		return

	_hurt_end(token, old_mod)

func _die() -> void:
	if _dead:
		return
	_dead = true
	is_dodging = false
	_frenzy_token += 1
	_frenzy_active = false
	_frenzy_recovering = false
	_frenzy_target = null

	_hurt_token += 1
	_hurt_active = false
	_invulnerable = true
	_suppress_lane_mask(false)

	died.emit()

	if _has_anim(&"dead"):
		_set_anim_loop(&"dead", false)
		animated_sprite_2d.play("dead")

	human_collision_shape2d.disabled = true
	set_physics_process(false)

# --- корутина: фэйл-сейф снятия каста ---
# -------------------------
# HP Pool Runtime Proxies
# -------------------------
func _bind_hp_to_inebriation_pool() -> void:
	_hp_pool_runtime.bind_hp_to_inebriation_pool(self)

func _on_inebriation_pool_changed(v: int) -> void:
	_hp_pool_runtime.on_inebriation_pool_changed(self, v)

func _set_hp_pool(target_value: int) -> void:
	_hp_pool_runtime.set_hp_pool(self, target_value)

func can_pay_hp_cost(cost: int) -> bool:
	return _hp_pool_runtime.can_pay_hp_cost(self, cost)

func spend_skill_hp(cost: int) -> bool:
	return _hp_pool_runtime.spend_skill_hp(self, cost)

func gain_skill_hp(amount: int) -> int:
	return _hp_pool_runtime.gain_skill_hp(self, amount)

# --- coroutine: cast release failsafe ---
func _cast_safety_release(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	# FIX: снимаем каст только если он всё ещё “про тот же каст”
	if is_casting:
		is_casting = false
		_casting_anim = StringName()
		_return_to_motion_anim()

## lane
func _on_lane_changed(_old: int, new_lane: int) -> void:
	_apply_lane_collision_mask(new_lane)

func _apply_lane_collision_mask(lane: int) -> void:
	var lane_layer := LaneSystem.layer_from_lane(lane)
	collision_mask = LAYER_WORLD | LAYER_TRIGGER | LAYER_HAZARD | lane_layer

# =========================
#        SHADOW LOGIC
# =========================
func _update_shadow() -> void:
	if shadow == null or animated_sprite_2d == null:
		return

	var depth_visual_dy: float = animated_sprite_2d.global_position.y - global_position.y

	shadow.global_position = Vector2(
		global_position.x,
		_shadow_ground_y + depth_visual_dy + shadow_y_offset
	)

	var h: float = max(0.0, _shadow_ground_y - global_position.y)
	var t: float = clamp(h / max(1.0, shadow_height_px), 0.0, 1.0)
	var s: float = lerp(1.0, shadow_min_scale, t)
	shadow.scale = _shadow_base_scale * s

# --- API: нокбэки ---
func apply_knockback(direction: Vector2) -> void:
	if is_casting:
		return
	velocity.x = -direction.x * KNOCKBACK_FORCE

func apply_smoke_hit_knockback(from_dir: Vector2) -> void:
	if is_casting:
		return
	apply_knockback(from_dir)
	
func _cleanup_old_skill_arcs() -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return

	# типичные имена старых линий из скиллов
	var names := [
		"AimArcLine2D",
		"AimArcLine2D_Molotov",
		"AimArcLine2D_Bottle",
	]

	for n in names:
		var node := get_tree().current_scene.find_child(n, true, false)
		if node != null and is_instance_valid(node):
			node.queue_free()

func skills_get_arc_preview() -> ArcPreview:

	if _arc_preview != null and is_instance_valid(_arc_preview):
		return _arc_preview

	var scene: PackedScene = preload("res://VFX/ArcPreview/ArcPreview.tscn")
	_arc_preview = scene.instantiate() as ArcPreview

	# назначаем текстуры (иначе ArcPreview ничего не рисует)
	if _arc_preview != null:
		_arc_preview.dot_texture = arc_dot_texture
		_arc_preview.marker_tex_16 = arc_marker_16
		_arc_preview.marker_tex_48 = arc_marker_48
		_arc_preview.ground_mask = Layers.WORLD

	# куда класть: vfx_layer или VFX
	var parent: Node = null
	var vfx_groups: Array = get_tree().get_nodes_in_group("vfx_layer")

	if vfx_groups.size() > 0:
		parent = vfx_groups[0]
	elif get_tree().current_scene != null and get_tree().current_scene.has_node("VFX"):
		parent = get_tree().current_scene.get_node("VFX")
	elif get_tree().current_scene != null:
		parent = get_tree().current_scene
	else:
		parent = get_tree().root

	parent.add_child(_arc_preview)
	return _arc_preview
