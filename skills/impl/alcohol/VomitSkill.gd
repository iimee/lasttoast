extends Skill
class_name Vomit

@export var vomit_scene: PackedScene
@export var damage: int = 2
@export var knockback: float = 140.0
@export var enemy_group: String = "Enemy"
@export var offset_right: Vector2 = Vector2(33, -4)
@export var offset_left: Vector2 = Vector2(-8, -4)
@export var hp_cost: int = 1

func _init() -> void:
	cooldown = 0.50

func can_use(user: Node) -> bool:
	if user == null or vomit_scene == null:
		return false
	return _can_pay_hp(user, hp_cost)

func execute(user: Node) -> void:
	if user == null:
		return
	if not can_use(user):
		return
	if hp_cost > 0 and not _spend_hp(user, hp_cost):
		return
	if vomit_scene == null:
		push_warning("VomitSkill: vomit_scene is null. Assign Vomit.tscn.")
		return
	if not (user is Node2D):
		push_warning("VomitSkill: user is not Node2D.")
		return

	var u: Node2D = user as Node2D
	var dir: Vector2 = Vector2.RIGHT
	if user.has_method("skills_get_aim_dir"):
		dir = user.skills_get_aim_dir()
	var is_right: bool = dir.x >= 0.0
	var spawn_pos: Vector2 = u.global_position + (offset_right if is_right else offset_left)

	if user.has_method("play_cast_anim"):
		user.play_cast_anim("vomit")

	var v: Node = vomit_scene.instantiate()
	var parent: Node = user.get_tree().current_scene
	if parent == null:
		parent = user.get_parent()
	parent.add_child(v)

	if v is Node2D:
		(v as Node2D).global_position = spawn_pos

	v.set("direction", dir)
	v.set("damage", damage)
	v.set("knockback", knockback)
	v.set("enemy_group", enemy_group)

	var lane_i: int = _get_user_lane_index(user)
	var lane_depth_y: float = _get_user_lane_depth_y(user)
	var render_base_z: int = _get_user_render_z(user)

	if lane_i != -1:
		if "lane_index" in v:
			v.lane_index = lane_i
		elif v.has_method("set_lane_index"):
			v.call("set_lane_index", lane_i)

	if v.has_method("set_depth_y"):
		v.call("set_depth_y", lane_depth_y)
	elif "depth_y" in v:
		v.depth_y = lane_depth_y

	if "render_base_z" in v:
		v.render_base_z = render_base_z
	elif v.has_method("set_render_base_z"):
		v.call("set_render_base_z", render_base_z)

func _get_user_lane_index(user: Node) -> int:
	if user == null:
		return -1
	var uo: Object = user as Object
	if uo == null:
		return -1
	var lb: Variant = uo.get("lane_body")
	if lb != null and lb is Object:
		var lbo: Object = lb as Object
		var li: Variant = lbo.get("lane_index")
		if typeof(li) == TYPE_INT:
			return int(li)
	var li2: Variant = uo.get("lane_index")
	if typeof(li2) == TYPE_INT:
		return int(li2)
	return -1

func _get_user_lane_depth_y(user: Node) -> float:
	if user == null:
		return 0.0
	var uo: Object = user as Object
	if uo == null:
		return 0.0
	var lb: Variant = uo.get("lane_body")
	if lb != null and lb is Object:
		var lbo: Object = lb as Object
		var dy: Variant = lbo.get("depth_y")
		if typeof(dy) == TYPE_FLOAT or typeof(dy) == TYPE_INT:
			return float(dy)
	return 0.0

func _get_user_render_z(user: Node) -> int:
	if user == null:
		return 0
	if user.has_node("AnimatedSprite2D"):
		var spr: CanvasItem = user.get_node("AnimatedSprite2D") as CanvasItem
		if spr != null:
			return int(spr.z_index)
	var ci: CanvasItem = user as CanvasItem
	if ci != null:
		return int(ci.z_index)
	return 0

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
