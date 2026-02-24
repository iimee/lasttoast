# dashSkill.gd — Godot 4.6 (NO cast-lock for dash)
extends Skill
class_name DashSkill

@export var duration: float = 0.14
@export var speed: float = 620.0

@export var inertia_time: float = 0.12
@export var inertia_damping: float = 22.0

@export var nicotine_cost: int = 1

@export var damage: int = 2
@export var knockback_force: float = 60.0
@export var hit_radius: float = 18.0
@export var enemy_collision_mask: int = 0 # 0 = использовать collision_mask игрока

@export var stop_on_wall: bool = true
@export var stop_anim_on_wall: bool = true

func can_use(user: Node) -> bool:
	if user == null:
		return false

	# Запрет рывка в прыжке (только на полу)
	if user is CharacterBody2D:
		if not (user as CharacterBody2D).is_on_floor():
			return false
	elif user.has_method("is_on_floor"):
		if not bool(user.call("is_on_floor")):
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

	# Списание никотина
	if nicotine_cost > 0:
		var res: Node = user.get_tree().root.get_node_or_null("Resources")
		if res == null:
			return
		res.call("add_nicotine", -nicotine_cost)

	# Направление
	var dir: Vector2 = Vector2.ZERO
	if user.has_method("skills_get_aim_dir"):
		dir = user.skills_get_aim_dir()

	if dir == Vector2.ZERO:
		var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if input_dir != Vector2.ZERO:
			dir = input_dir

	if dir == Vector2.ZERO and user.has_node("AnimatedSprite2D"):
		var spr0: AnimatedSprite2D = user.get_node("AnimatedSprite2D") as AnimatedSprite2D
		dir = Vector2.LEFT if spr0.flip_h else Vector2.RIGHT

	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	dir = dir.normalized()

	# Контроллер рывка
	var ctrl: DashController = preload("res://Combat/Hitboxes/DashController.gd").new()
	ctrl.duration = duration
	ctrl.speed = speed
	ctrl.dir = dir
	ctrl.user = user as CharacterBody2D

	ctrl.inertia_time = inertia_time
	ctrl.inertia_damping = inertia_damping

	ctrl.damage = damage
	ctrl.knockback_force = knockback_force
	ctrl.hit_radius = hit_radius
	ctrl.enemy_collision_mask = enemy_collision_mask

	ctrl.stop_on_wall = stop_on_wall
	ctrl.stop_anim_on_wall = stop_anim_on_wall

	user.add_child(ctrl)
	ctrl.owner = user

	# ВАЖНО: не play_cast_anim(), чтобы не включать лок.
	_play_dash_anim_no_lock(user)

func _play_dash_anim_no_lock(user: Node) -> void:
	if not user.has_node("AnimatedSprite2D"):
		return
	var spr: AnimatedSprite2D = user.get_node("AnimatedSprite2D") as AnimatedSprite2D
	if spr == null:
		return
	if spr.sprite_frames == null:
		return
	if not spr.sprite_frames.has_animation("dash"):
		return

	# Гарантируем что не стоит speed_scale=0 после чужих локов
	if spr.speed_scale == 0.0:
		spr.speed_scale = 1.0

	spr.play("dash")
