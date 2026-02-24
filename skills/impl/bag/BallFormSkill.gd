extends Skill
class_name BallFormSkill

@export var duration: float = 0.0             # 0 = пока не выключишь повторным нажатием
@export var inebriation_cost: int = 1         # сколько зарядов опьянения требуется для включения

func _init() -> void:
	cooldown = 0.2                             # анти-даблклик

func can_use(user: Node) -> bool:
	if user == null:
		return false

	# Проверяем наличие ресурса "Resources" и уровень опьянения
	var tree: SceneTree = user.get_tree()
	if tree == null:
		return false
	var root: Node = tree.root
	var res: Node = root.get_node_or_null("Resources")
	if res == null:  
		return false

	var ineb: int = int(res.get("inebriation"))
	return ineb >= inebriation_cost

func execute(user: Node) -> void:
	if user == null:
		return

	var is_ball: bool = bool(user.get("is_ball"))
	var tree: SceneTree = user.get_tree()
	var root: Node = tree.root
	var res: Node = root.get_node_or_null("Resources")

	# Если не шар — включаем, потратив опьянение
	if not is_ball:
		if res == null:
			return
		var ineb: int = int(res.get("inebriation"))
		if ineb < inebriation_cost:
			return
		# Тратим опьянение
		res.call("add_inebriation", -inebriation_cost)

		# Включаем форму шара
		if user.has_method("toggle_ball"):
			user.toggle_ball()

		# Авто-выключение по таймеру
		if duration > 0.0:
			var t: SceneTreeTimer = tree.create_timer(duration)
			t.timeout.connect(func():
				if is_instance_valid(user) and bool(user.get("is_ball")) and user.has_method("toggle_ball"):
					user.toggle_ball()
			)
	else:
		# Уже шар — просто выключаем
		if user.has_method("toggle_ball"):
			user.toggle_ball()
