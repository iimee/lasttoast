extends CharacterBody2D

@export var speed: float = 140.0
@export var arrival_threshold: float = 8.0
@export var max_hp: int = 1
@export var death_fx_scene: PackedScene

@export_node_path var left_point_path: NodePath
@export_node_path var right_point_path: NodePath

var hp: int
var dir_x: int = 1
var left_x: float
var right_x: float
var is_dead: bool = false
var target: Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_cs: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox
@onready var left_point: Node2D = null
@onready var right_point: Node2D = null

func _ready() -> void:
	hp = max_hp

	if left_point_path != NodePath():
		left_point = get_node_or_null(left_point_path)
	elif has_node("LeftPoint"):
		left_point = $LeftPoint

	if right_point_path != NodePath():
		right_point = get_node_or_null(right_point_path)
	elif has_node("RightPoint"):
		right_point = $RightPoint

	if left_point and right_point:
		left_x = minf(left_point.global_position.x, right_point.global_position.x)
		right_x = maxf(left_point.global_position.x, right_point.global_position.x)
	else:
		left_x = global_position.x - 64.0
		right_x = global_position.x + 64.0

	dir_x = 1
	_update_sprite_flip()

	if is_instance_valid(hitbox):
		hitbox.area_entered.connect(_on_Hitbox_area_entered)

	if _has_anim("fly"):
		sprite.play("fly")

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return

	velocity.y = 0.0
	velocity.x = dir_x * speed

	if dir_x > 0 and global_position.x >= right_x - arrival_threshold:
		_reverse()
	elif dir_x < 0 and global_position.x <= left_x + arrival_threshold:
		_reverse()

	move_and_slide()

	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		if col and absf(col.get_normal().x) > 0.7:
			_reverse()
			break

func _reverse() -> void:
	dir_x = -dir_x
	global_position.x = clampf(global_position.x, left_x, right_x)
	_update_sprite_flip()

func _update_sprite_flip() -> void:
	if sprite:
		# спрайт по умолчанию смотрит влево → вправо = зеркалим
		sprite.flip_h = (dir_x > 0)

func _has_anim(name: String) -> bool:
	return sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(name)

func _on_Hitbox_area_entered(area: Area2D) -> void:
	_process_hit_from_obj(area)

func _process_hit_from_obj(obj: Object) -> void:
	if obj == null or not (obj is Node):
		return
	var n := obj as Node

	var dmg := 0
	if n.is_in_group("attack"):
		var v = n.get("damage")
		if v != null:
			dmg = int(v)
		elif n.has_meta("damage"):
			dmg = int(n.get_meta("damage"))
		else:
			dmg = 1
	elif n.get("damage") != null:
		dmg = int(n.get("damage"))
	elif n.has_meta("damage"):
		dmg = int(n.get_meta("damage"))

	if dmg <= 0:
		return

	_apply_damage(dmg)

	if n.has_method("queue_free"):
		n.call("queue_free")

func _apply_damage(amount: int) -> void:
	if is_dead:
		return
	hp -= amount
	if hp <= 0:
		_die()
		return
	if _has_anim("hit"):
		sprite.play("hit")
		await sprite.animation_finished
		if not is_dead and _has_anim("fly"):
			sprite.play("fly")
			
func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	$CollisionShape2D.disabled = true
	if has_node("Hitbox/CollisionShape2D"):
		$"Hitbox/CollisionShape2D".disabled = true
	if death_fx_scene:
		var fx = death_fx_scene.instantiate()
		var parent := get_tree().current_scene if get_tree().current_scene else get_parent()
		parent.add_child(fx)
		if fx is Node2D:
			(fx as Node2D).global_position = global_position
	if _has_anim("die"):
		sprite.play("die")
		await sprite.animation_finished
	queue_free()
