extends Skill
class_name SmokePlatformSkill

@export var platform_scene: PackedScene
@export var duration: float = 2.0
@export var platform_size: Vector2 = Vector2(64, 12)
@export var y_offset: float = 2.0
@export var platform_layer: int = 6
@export var nicotine_cost: int = 1

func _init() -> void:
	cooldown = 0.35
	# дефолты в уже существующие поля базового Skill
	if id == StringName():
		id = &"SmokePlatform"
	if title == "":
		title = "Дымовая платформа"
	# icon оставь пустым — задай в ресурсe .tres через инспектор

func can_use(user: Node) -> bool:
	if user == null or platform_scene == null:
		return false
	var tree: SceneTree = user.get_tree()
	if tree == null: return false
	var res: Node = tree.root.get_node_or_null("Resources")
	if res == null: return false
	return int(res.get("nicotine")) >= nicotine_cost

func execute(user: Node) -> void:
	if user == null or not can_use(user) or not (user is Node2D):
		return

	var tree: SceneTree = user.get_tree()
	var res: Node = tree.root.get_node_or_null("Resources")
	if res == null: return

	# списание ресурса
	if nicotine_cost > 0:
		res.call("add_nicotine", -nicotine_cost)

	# спавн платформы
	var p: Node = platform_scene.instantiate()
	if p == null: return

	var parent: Node = tree.current_scene
	if parent == null:
		parent = user.get_parent()
	parent.add_child(p)

	# позиция
	var user2d := user as Node2D
	if p is Node2D:
		(p as Node2D).global_position = _feet_position(user2d) + Vector2(0, y_offset)

	# настройка без жёсткой зависимости от класса
	if "duration" in p:
		p.set("duration", duration)

	if "collision_layer" in p:
		var bit: int = 1 << max(0, platform_layer - 1)
		p.set("collision_layer", bit)

	var col := p.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col and col.shape is RectangleShape2D:
		(col.shape as RectangleShape2D).size = platform_size
		col.one_way_collision = true

func _feet_position(user2d: Node2D) -> Vector2:
	var cs := user2d.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs and cs.shape is RectangleShape2D:
		var half_h := (cs.shape as RectangleShape2D).size.y * 0.5
		return user2d.global_position + Vector2(0, half_h)

	for child in user2d.get_children():
		var ch := child as CollisionShape2D
		if ch and ch.shape is RectangleShape2D:
			var h2 := (ch.shape as RectangleShape2D).size.y * 0.5
			return user2d.global_position + Vector2(0, h2)

	return user2d.global_position + Vector2(0, 16)
