extends Skill
class_name DodgeSkill

@export var invulnerability_time: float = 0.22
@export var nicotine_cost: int = 1
@export var dodge_anim_name: StringName = &"dodge"
const _DODGE_INVULN_TOKEN_META: StringName = &"_dodge_invuln_token"
const _DODGE_LOCK_TOKEN_META: StringName = &"_dodge_lock_token"
@export var dodge_lock_fallback: float = 0.22

func can_use(user: Node) -> bool:
	if user == null:
		return false
	if user.has_method("_movement_locked") and bool(user.call("_movement_locked")):
		return false
	if nicotine_cost <= 0:
		return true
	var tree: SceneTree = user.get_tree()
	if tree == null:
		return false
	var res: Node = tree.root.get_node_or_null("Resources")
	if res == null:
		return false
	var nic: int = int(res.get("nicotine"))
	return nic >= nicotine_cost

func execute(user: Node) -> void:
	if user == null:
		return
	if not can_use(user):
		return

	if nicotine_cost > 0:
		var res: Node = user.get_tree().root.get_node_or_null("Resources")
		if res == null:
			return
		res.call("add_nicotine", -nicotine_cost)

	var lock_time: float = _resolve_dodge_lock_time(user)
	_start_dodge_lock(user, lock_time)
	_play_dodge_anim(user)
	_apply_invulnerability(user, lock_time)

func _resolve_dodge_lock_time(user: Node) -> float:
	var duration: float = maxf(0.05, dodge_lock_fallback)
	if not user.has_node("AnimatedSprite2D"):
		return duration
	var spr: AnimatedSprite2D = user.get_node("AnimatedSprite2D") as AnimatedSprite2D
	if spr == null or spr.sprite_frames == null:
		return duration
	if not spr.sprite_frames.has_animation(dodge_anim_name):
		return duration
	var frames: int = spr.sprite_frames.get_frame_count(dodge_anim_name)
	var fps: float = float(spr.sprite_frames.get_animation_speed(dodge_anim_name))
	if fps <= 0.0:
		return duration
	var anim_dur: float = float(frames) / fps
	return maxf(duration, anim_dur + 0.02)

func _start_dodge_lock(user: Node, duration: float) -> void:
	if not (user is Object):
		return
	var obj := user as Object
	var token: int = int(obj.get_meta(_DODGE_LOCK_TOKEN_META, 0)) + 1
	obj.set_meta(_DODGE_LOCK_TOKEN_META, token)
	if _has_property(obj, &"is_dodging"):
		obj.set("is_dodging", true)
	var tree: SceneTree = user.get_tree()
	if tree == null:
		return
	var timer: SceneTreeTimer = tree.create_timer(maxf(0.05, duration))
	timer.timeout.connect(func() -> void:
		if not is_instance_valid(user):
			return
		var o := user as Object
		if int(o.get_meta(_DODGE_LOCK_TOKEN_META, 0)) != token:
			return
		if o.has_meta(_DODGE_LOCK_TOKEN_META):
			o.remove_meta(_DODGE_LOCK_TOKEN_META)
		if _has_property(o, &"is_dodging"):
			o.set("is_dodging", false)
	)

func _play_dodge_anim(user: Node) -> void:
	if not user.has_node("AnimatedSprite2D"):
		return
	var spr: AnimatedSprite2D = user.get_node("AnimatedSprite2D") as AnimatedSprite2D
	if spr == null or spr.sprite_frames == null:
		return
	if not spr.sprite_frames.has_animation(dodge_anim_name):
		return
	spr.sprite_frames.set_animation_loop(dodge_anim_name, false)
	if spr.speed_scale == 0.0:
		spr.speed_scale = 1.0
	spr.frame = 0
	spr.play(String(dodge_anim_name))

func _apply_invulnerability(user: Node, lock_time: float = 0.0) -> void:
	var invuln_duration: float = maxf(invulnerability_time, maxf(0.0, lock_time))
	if invuln_duration <= 0.0:
		return
	if not (user is Object):
		return
	var obj := user as Object
	var token: int = int(obj.get_meta(_DODGE_INVULN_TOKEN_META, 0)) + 1
	obj.set_meta(_DODGE_INVULN_TOKEN_META, token)
	obj.set("_invulnerable", true)
	var tree: SceneTree = user.get_tree()
	if tree == null:
		return
	var timer: SceneTreeTimer = tree.create_timer(invuln_duration)
	timer.timeout.connect(func() -> void:
		if not is_instance_valid(user):
			return
		var o := user as Object
		if int(o.get_meta(_DODGE_INVULN_TOKEN_META, 0)) != token:
			return
		if o.has_meta(_DODGE_INVULN_TOKEN_META):
			o.remove_meta(_DODGE_INVULN_TOKEN_META)
		var hurt_active: bool = false
		if _has_property(o, &"_hurt_active"):
			hurt_active = bool(o.get("_hurt_active"))
		if not hurt_active:
			o.set("_invulnerable", false)
	)

func _has_property(o: Object, prop: StringName) -> bool:
	for d in o.get_property_list():
		if d.has("name") and StringName(d.name) == prop:
			return true
	return false
