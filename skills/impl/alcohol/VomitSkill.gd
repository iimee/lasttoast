extends Skill
class_name Vomit

@export var vomit_scene: PackedScene        # res://Combat/Vomit.tscn
@export var damage: int = 1
@export var knockback: float = 140.0
@export var enemy_group: String = "Enemy"
@export var offset_right: Vector2 = Vector2(33, -4)
@export var offset_left:  Vector2 = Vector2(-8, -4)
@export var inebriation_cost: int = 1       # тратим опьянение

func _init() -> void:
	cooldown = 0.50

func can_use(user: Node) -> bool:
	if user == null or vomit_scene == null:
		return false
	var tree: SceneTree = user.get_tree()
	if tree == null:
		return false
	var res: Node = tree.root.get_node_or_null("Resources")
	if res == null:
		return false
	var ineb: int = int(res.get("inebriation"))
	return ineb >= inebriation_cost

func execute(user: Node) -> void:
	if user == null:
		return
	if not can_use(user):
		return

	# списываем опьянение
	if inebriation_cost > 0:
		var res: Node = user.get_tree().root.get_node_or_null("Resources")
		if res == null:
			return
		res.call("add_inebriation", -inebriation_cost)

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
		user.play_cast_anim("vomit")  # если нет — просто пропустит

	var v: Node = vomit_scene.instantiate()
	var parent: Node = user.get_tree().current_scene
	if parent == null:
		parent = user.get_parent()
	parent.add_child(v)

	if v is Node2D:
		(v as Node2D).global_position = spawn_pos

	# параметры удара
	v.set("direction", dir)
	v.set("damage", damage)
	v.set("knockback", knockback)
	v.set("enemy_group", enemy_group)
