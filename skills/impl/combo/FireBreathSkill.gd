extends Skill
class_name FireBreathSkill

@export var fire_breath_scene: PackedScene
@export var damage: int = 2
@export var knockback: float = 140.0
@export var enemy_group: String = "Enemy"
@export var offset_right: Vector2 = Vector2(5, -10)
@export var offset_left: Vector2 = Vector2(-50, -10)
@export var hp_cost: int = 2
@export var nicotine_cost: int = 1

func _init() -> void:
	cooldown = 0.50

func can_use(user: Node) -> bool:
	if user == null:
		return false
	if fire_breath_scene == null:
		return false
	var tree: SceneTree = user.get_tree()
	if tree == null:
		return false
	var res: Node = tree.root.get_node_or_null("Resources")
	if res == null:
		return false
	var nic: int = int(res.get("nicotine"))
	if nic < nicotine_cost:
		return false
	return _can_pay_hp(user, hp_cost)

func execute(user: Node) -> void:
	if user == null:
		return
	if not can_use(user):
		return
	if not (user is Node2D):
		push_warning("FireBreathSkill: user is not Node2D.")
		return

	var tree: SceneTree = user.get_tree()
	var res: Node = tree.root.get_node_or_null("Resources")
	if res == null:
		return
	if hp_cost > 0 and not _spend_hp(user, hp_cost):
		return
	if nicotine_cost > 0:
		res.call("add_nicotine", -nicotine_cost)

	var user2d: Node2D = user as Node2D
	var dir: Vector2 = Vector2.RIGHT
	if user.has_method("skills_get_aim_dir"):
		dir = user.skills_get_aim_dir()
	var is_right: bool = dir.x >= 0.0

	var spawn_pos: Vector2 = user2d.global_position
	var mouth: Node2D = user.get_node_or_null("Sockets/Mouth") as Node2D
	if mouth == null:
		mouth = user.get_node_or_null("Mouth") as Node2D
	if mouth != null:
		spawn_pos = mouth.global_position
	spawn_pos += (offset_right if is_right else offset_left)

	if user.has_method("play_cast_anim"):
		user.play_cast_anim("fire_breath")

	var v: Node = fire_breath_scene.instantiate()
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
