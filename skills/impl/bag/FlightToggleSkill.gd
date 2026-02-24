extends Skill
class_name FlightToggleSkill

@export var duration: float = 0.0                 # 0 = пока не выключишь повторным нажатием
@export var require_nicotine: bool = false        # если true — включение только при Resources.nicotine > 0

func _init() -> void:
	cooldown = 0.2

func can_use(user: Node) -> bool:
	if require_nicotine:
		if user == null:
			return false
		var tree: SceneTree = user.get_tree()
		if tree == null:
			return false
		var root: Node = tree.root
		var res: Node = root.get_node_or_null("Resources")
		if res == null:
			return false
		var nic: int = int(res.get("nicotine"))
		return nic > 0
	return true

func execute(user: Node) -> void:
	if user == null:
		return
	var was_flying: bool = bool(user.get("is_flying"))

	if user.has_method("toggle_fly"):
		user.toggle_fly()
	else:
		return

	# Если только что ВКЛЮЧИЛИ полёт и задана длительность — выключим по таймеру
	if not was_flying and duration > 0.0:
		var t: SceneTreeTimer = user.get_tree().create_timer(duration)
		t.timeout.connect(func():
			if is_instance_valid(user) and bool(user.get("is_flying")) and user.has_method("toggle_fly"):
				user.toggle_fly()
		)
