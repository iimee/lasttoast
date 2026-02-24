extends Skill
class_name FireBreathSkill

@export var fire_breath_scene: PackedScene   # ← назначь FireBreath.tscn
@export var damage: int = 1
@export var knockback: float = 140.0
@export var enemy_group: String = "Enemy"

# Тонкая настройка точки вылета:
@export var offset_right: Vector2 = Vector2(5, -10)   # когда смотрим вправо
@export var offset_left:  Vector2 = Vector2(-50, -10)  # когда смотрим влево

@export var inebriation_cost: int = 1                # цена по опьянению
@export var nicotine_cost: int = 1                   # цена по накуренности

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

	var ineb: int = int(res.get("inebriation"))
	var nic: int = int(res.get("nicotine"))
	return (ineb >= inebriation_cost) and (nic >= nicotine_cost)

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

	# --- Списание ресурсов ---
	if inebriation_cost > 0:
		res.call("add_inebriation", -inebriation_cost)
	if nicotine_cost > 0:
		res.call("add_nicotine", -nicotine_cost)

	var user2d: Node2D = user as Node2D
	var dir: Vector2 = Vector2.RIGHT
	if user.has_method("skills_get_aim_dir"):
		dir = user.skills_get_aim_dir()
	var is_right: bool = dir.x >= 0.0

	# Базовая точка спавна — позиция игрока
	var spawn_pos: Vector2 = user2d.global_position

	# Если есть маркер "рот" — берём его позицию
	var mouth: Node2D = user.get_node_or_null("Sockets/Mouth") as Node2D
	if mouth == null:
		mouth = user.get_node_or_null("Mouth") as Node2D
	if mouth != null:
		spawn_pos = mouth.global_position

	# Добавляем сдвиг по направлению
	spawn_pos += (offset_right if is_right else offset_left)

	# Анимация каста (если есть)
	if user.has_method("play_cast_anim"):
		user.play_cast_anim("fire_breath")

	# Спавним эффект
	var v: Node = fire_breath_scene.instantiate()

	var parent: Node = user.get_tree().current_scene
	if parent == null:
		parent = user.get_parent()
	parent.add_child(v)

	if v is Node2D:
		var v2d: Node2D = v as Node2D
		v2d.global_position = spawn_pos

	# Прокидываем параметры (best-effort)
	v.set("direction", dir)
	v.set("damage", damage)
	v.set("knockback", knockback)
	v.set("enemy_group", enemy_group)
