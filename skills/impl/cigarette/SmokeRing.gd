# SmokeRing.gd
extends Skill
class_name SmokeRing

@export var projectile: PackedScene
@export var speed: float = 90.0

@export var forward_offset: float = 18.0
@export var height_offset: float = -24.0

@export var recoil_in_flight: bool = true
@export var hp_cost: int = 1
@export var nicotine_cost: int = 1

# время каста (длина анимации запуска на персонаже)
@export var cast_delay: float = 1

func _init() -> void:
	cooldown = 0.40

func can_use(user: Node) -> bool:
	if user == null:
		return false
	if not _can_pay_hp(user, hp_cost):
		return false
	if nicotine_cost <= 0:
		return true
	var tree: SceneTree = user.get_tree()
	if tree == null:
		return false
	var res: Node = tree.root.get_node_or_null("Resources")
	if res == null:
		return false
	return int(res.get("nicotine")) >= nicotine_cost

func execute(user: Node) -> void:
	if projectile == null or user == null:
		return
	if not can_use(user):
		return
	if hp_cost > 0 and not _spend_hp(user, hp_cost):
		return

	# списать никотин
	if nicotine_cost > 0:
		var res: Node = user.get_tree().root.get_node_or_null("Resources")
		if res == null:
			return
		res.call("add_nicotine", -nicotine_cost)

	var u := user as Node2D
	if u == null:
		return

	# анимация каста (запуск кольца на персонаже)
	if user.has_method("play_cast_anim"):
		user.play_cast_anim("smokering_skill")

	# направление
	var dir: Vector2 = Vector2.RIGHT
	if user.has_method("skills_get_aim_dir"):
		dir = user.skills_get_aim_dir()
	if dir.length() <= 0.0001:
		dir = Vector2.RIGHT
	dir = dir.normalized()

	# где будет спавн
	var spawn_pos: Vector2 = u.global_position + dir * forward_offset
	spawn_pos.y += height_offset
	var lane_depth_y: float = _get_user_lane_depth_y(user)

	# ---------- PHASE 1: создать, но НЕ показывать/не коллайдить/не двигать ----------
	var p := projectile.instantiate()
	if p == null:
		return

	# добавить в сцену (лучше текущая сцена, чем root)
	var world := user.get_tree().current_scene
	if world == null:
		world = user.get_tree().root
	world.add_child(p)
	# заморозить анимацию прожектайла, чтобы не промоталась пока он скрыт
	var spr: AnimatedSprite2D = null
	if p.has_node("AnimatedSprite2D"):
		spr = p.get_node("AnimatedSprite2D") as AnimatedSprite2D
	if spr:
		spr.stop()
		spr.frame = 0
		spr.speed_scale = 0.0

	if p is Node2D:
		(p as Node2D).global_position = spawn_pos

	# проставить lane_index как у бутылок/молотова
	var lane_i := -1
	if "lane_body" in user and user.get("lane_body"):
		var lb = user.get("lane_body")
		if lb and ("lane_index" in lb):
			lane_i = int(lb.lane_index)
	elif ("lane_index" in user):
		lane_i = int(user.lane_index)

	if lane_i != -1:
		if "lane_index" in p:
			p.lane_index = lane_i
		elif p.has_method("set_lane_index"):
			p.set_lane_index(lane_i)

	# Keep projectile visual depth aligned with player's current depth within lane.
	if p.has_method("set_depth_y"):
		p.call("set_depth_y", lane_depth_y)
	elif "depth_y" in p:
		p.depth_y = lane_depth_y
		if p.has_method("_apply_lane_visual"):
			p.call("_apply_lane_visual")

	# выключить коллизию/движение/видимость до конца анимации
	if p is Area2D:
		var a := p as Area2D
		a.monitoring = false
		a.monitorable = false
	p.visible = false
	if p.has_method("set_physics_process"):
		p.set_physics_process(false)

	# ---------- ждать окончание каста ----------
	if cast_delay > 0.0:
		await user.get_tree().create_timer(cast_delay).timeout
	if not is_instance_valid(p):
		return

	# ---------- PHASE 2: включить и мгновенно проверить point-blank ----------
	p.visible = true
	if p is Area2D:
		var a2 := p as Area2D
		a2.monitorable = true
		a2.monitoring = true

	# старт полёта
		# разморозить и перезапустить анимацию с 0 кадра
	if spr:
		spr.speed_scale = 1.0
		spr.frame = 0
		spr.play("smoke")
		
	if dir.length_squared() < 0.000001:
		dir = Vector2.RIGHT if u.scale.x >= 0.0 else Vector2.LEFT
	
	
	if p.has_method("setup"):
		p.setup(dir, speed)
	else:
		# если у прожектайла нет setup — хотя бы двинем чуть вперёд
		if p is Node2D:
			(p as Node2D).global_position += dir * 1.0

	# дать физике 1 кадр обновить overlaps и ткнуть хитом (чтобы вплотную работало)
	await user.get_tree().physics_frame
	if is_instance_valid(p) and p is Area2D:
		var a3 := p as Area2D
		# если в Projectile.gd есть _on_hit — дерни его руками по overlap’ам
		if p.has_method("_on_hit"):
			for b in a3.get_overlapping_bodies():
				p._on_hit(b)
				if not is_instance_valid(p):
					return
			for ar in a3.get_overlapping_areas():
				p._on_hit(ar)
				if not is_instance_valid(p):
					return

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

func _can_pay_hp(user: Node, cost: int) -> bool:
	if cost <= 0:
		return true
	if user.has_method("can_pay_hp_cost"):
		return bool(user.call("can_pay_hp_cost", cost))
	if user is Object:
		var hp: int = int((user as Object).get("hp"))
		return hp > cost
	return false

func _spend_hp(user: Node, cost: int) -> bool:
	if cost <= 0:
		return true
	if user.has_method("spend_skill_hp"):
		return bool(user.call("spend_skill_hp", cost))
	return false
